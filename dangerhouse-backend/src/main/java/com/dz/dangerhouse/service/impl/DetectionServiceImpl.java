package com.dz.dangerhouse.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.dz.dangerhouse.cache.CacheProperties;
import com.dz.dangerhouse.cache.CacheService;
import com.dz.dangerhouse.dto.response.AiDetectionResponse;
import com.dz.dangerhouse.dto.response.DetectionResultResponse;
import com.dz.dangerhouse.entity.Building;
import com.dz.dangerhouse.entity.Detection;
import com.dz.dangerhouse.entity.Image;
import com.dz.dangerhouse.entity.Report;
import com.dz.dangerhouse.entity.User;
import com.dz.dangerhouse.exception.BusinessException;
import com.dz.dangerhouse.mapper.BuildingMapper;
import com.dz.dangerhouse.mapper.DetectionMapper;
import com.dz.dangerhouse.mapper.ImageMapper;
import com.dz.dangerhouse.mapper.ReportMapper;
import com.dz.dangerhouse.mapper.UserMapper;
import com.dz.dangerhouse.service.CurrentUserService;
import com.dz.dangerhouse.service.DetectionAiClientService;
import com.dz.dangerhouse.service.DetectionResultAssembler;
import com.dz.dangerhouse.service.DetectionService;
import com.dz.dangerhouse.util.FileUploadUtil;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.io.File;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.concurrent.TimeUnit;
import java.util.stream.Collectors;

/**
 * 检测服务实现类
 * 提供检测任务创建、图片上传、AI检测、结果查询等完整功能
 */
@Slf4j
@Service
public class DetectionServiceImpl implements DetectionService {

    @Autowired
    private DetectionAiClientService detectionAiClientService;

    @Autowired
    private DetectionResultAssembler detectionResultAssembler;

    @Autowired
    private CurrentUserService currentUserService;

    @Autowired
    private FileUploadUtil fileUploadUtil;

    @Autowired
    private DetectionMapper detectionMapper;

    @Autowired
    private ImageMapper imageMapper;

    @Autowired
    private ReportMapper reportMapper;

    @Autowired
    private BuildingMapper buildingMapper;

    @Autowired
    private UserMapper userMapper;

    @Autowired
    private CacheService cacheService;

    @Autowired
    private CacheProperties cacheProperties;

    /**
     * 为建筑创建空的检测任务
     *
     * @param buildingId  建筑ID
     * @param userId      用户ID
     * @param description 任务描述
     * @return 检测任务响应
     */
    @Override
    @Transactional(rollbackFor = Exception.class)
    public DetectionResultResponse createTask(Long buildingId, Long userId, String description) {
        Building building = buildingMapper.selectById(buildingId);
        if (building == null) {
            throw new BusinessException("建筑不存在");
        }

        validateBuildingAccess(building);

        User user = userMapper.selectById(userId);
        if (user == null) {
            throw new BusinessException("用户不存在");
        }

        Detection detection = new Detection();
        detection.setBuildingId(buildingId);
        detection.setUserId(userId);
        detection.setStatus("CREATED");
        detection.setDescription(description);
        detection.setCreatedAt(LocalDateTime.now());
        detection.setUpdatedAt(LocalDateTime.now());
        detectionMapper.insert(detection);

        evictDetectionCache(detection.getId());
        evictDashboardCache();

        log.info("创建检测任务成功：taskId={}, buildingId={}, userId={}", detection.getId(), buildingId, userId);
        return buildDetectionResponse(detection, building, user, null);
    }

    /**
     * 为现有检测任务上传一张或多张图片
     *
     * @param detectionId 检测任务ID
     * @param images      图片文件列表
     * @return 图片信息列表
     */
    @Override
    @Transactional(rollbackFor = Exception.class)
    public List<DetectionResultResponse.ImageInfo> uploadImages(Long detectionId, List<MultipartFile> images) {
        Detection detection = detectionMapper.selectById(detectionId);
        if (detection == null) {
            throw new BusinessException("检测任务不存在");
        }
        if (!"CREATED".equals(detection.getStatus())) {
            throw new BusinessException("检测任务已启动，无法继续上传图片");
        }

        List<DetectionResultResponse.ImageInfo> imageInfos = new ArrayList<>();
        for (MultipartFile file : images) {
            if (file == null || file.isEmpty()) {
                continue;
            }

            String imagePath = fileUploadUtil.uploadDetectionOriginalImage(file, detectionId);

            Image image = new Image();
            image.setDetectionId(detectionId);
            image.setImagePath(imagePath);
            image.setImageType("ORIGINAL");
            image.setUploadTime(LocalDateTime.now());
            imageMapper.insert(image);

            imageInfos.add(
                    DetectionResultResponse.ImageInfo.builder()
                            .id(image.getId())
                            .imagePath(fileUploadUtil.getFileUrl(imagePath))
                            .imageType("ORIGINAL")
                            .uploadTime(image.getUploadTime())
                            .build()
            );
        }

        detection.setStatus("READY");
        detection.setErrorMessage(null);
        detection.setUpdatedAt(LocalDateTime.now());
        detectionMapper.updateById(detection);
        evictDetectionCache(detectionId);

        log.info("上传检测图片成功：detectionId={}, 图片数量={}", detectionId, imageInfos.size());
        return imageInfos;
    }

    /**
     * 启动检测任务的AI分析
     *
     * @param detectionId 检测任务ID
     * @return 检测结果响应
     */
    @Override
    @Transactional(rollbackFor = Exception.class)
    public DetectionResultResponse startDetection(Long detectionId) {
        Detection detection = detectionMapper.selectById(detectionId);
        if (detection == null) {
            throw new BusinessException("检测任务不存在");
        }
        validateDetectionAccess(detection);
        if (!"READY".equals(detection.getStatus()) && !"FAILED".equals(detection.getStatus())) {
            throw new BusinessException("检测任务状态无效: " + detection.getStatus());
        }

        List<Image> images = imageMapper.findByDetectionId(detectionId);
        if (images.isEmpty()) {
            detection.setStatus("FAILED");
            detection.setErrorMessage("没有可检测的图片");
            detection.setUpdatedAt(LocalDateTime.now());
            detectionMapper.updateById(detection);
            evictDetectionCache(detectionId);
            evictDashboardCache();
            throw new BusinessException("没有可检测的图片");
        }

        detection.setCrackCount(0);
        detection.setDamageRatio(BigDecimal.ZERO);
        detection.setRiskLevel(null);
        detection.setDetectResult(null);
        detection.setStatus("PROCESSING");
        detection.setErrorMessage(null);
        detection.setUpdatedAt(LocalDateTime.now());
        detectionMapper.updateById(detection);
        evictDetectionCache(detectionId);
        evictDashboardCache();

        List<File> imageFiles = resolveImageFiles(images);
        if (imageFiles.isEmpty()) {
            detection.setStatus("FAILED");
            detection.setErrorMessage("未找到可用的检测图片文件");
            detection.setUpdatedAt(LocalDateTime.now());
            detectionMapper.updateById(detection);
            evictDetectionCache(detectionId);
            evictDashboardCache();
            throw new BusinessException("未找到可用的检测图片文件");
        }

        try {
            AiDetectionResponse.DataInfo dataInfo = detectionAiClientService.detect(imageFiles);
            detectionAiClientService.applyAnalysisToDetection(detection, dataInfo);
            detection.setDetectTime(LocalDateTime.now());
            detection.setStatus("COMPLETED");
            detection.setErrorMessage(null);
            detection.setUpdatedAt(LocalDateTime.now());
            detectionMapper.updateById(detection);

            if (dataInfo.getImageResults() != null) {
                detectionAiClientService.persistImageResults(images, dataInfo.getImageResults());
            }
        } catch (Exception ex) {
            detection.setStatus("FAILED");
            detection.setErrorMessage(ex.getMessage());
            detection.setUpdatedAt(LocalDateTime.now());
            detectionMapper.updateById(detection);
            evictDetectionCache(detectionId);
            evictDashboardCache();
            throw ex;
        }

        evictDetectionCache(detectionId);
        evictDashboardCache();

        Building building = buildingMapper.selectById(detection.getBuildingId());
        User user = userMapper.selectById(detection.getUserId());
        log.info("检测任务完成：taskId={}, 风险等级={}, 裂缝数量={}",
                detectionId, detection.getRiskLevel(), detection.getCrackCount());
        return buildDetectionResponse(detection, building, user, images);
    }

    /**
     * 取消待处理的检测任务
     *
     * @param detectionId 检测任务ID
     */
    @Override
    @Transactional(rollbackFor = Exception.class)
    public void cancelDetection(Long detectionId) {
        Detection detection = detectionMapper.selectById(detectionId);
        if (detection == null) {
            throw new BusinessException("检测任务不存在");
        }
        validateDetectionAccess(detection);
        if (!"CREATED".equals(detection.getStatus()) && !"READY".equals(detection.getStatus())) {
            throw new BusinessException("仅 CREATED 或 READY 状态的任务可以取消");
        }

        detection.setStatus("CANCELLED");
        detection.setUpdatedAt(LocalDateTime.now());
        detectionMapper.updateById(detection);
        evictDetectionCache(detectionId);
        evictDashboardCache();

        log.info("取消检测任务成功：taskId={}", detectionId);
    }

    /**
     * 删除检测任务
     *
     * @param id 检测任务ID
     */
    @Override
    @Transactional(rollbackFor = Exception.class)
    public void deleteDetection(Long id) {
        Detection detection = detectionMapper.selectById(id);
        if (detection == null) {
            throw new BusinessException("检测任务不存在");
        }

        validateDetectionAccess(detection);

        imageMapper.deleteByDetectionId(id);
        detectionMapper.deleteById(id);
        evictDetectionCache(id);
        evictDashboardCache();

        log.info("删除检测任务成功：taskId={}", id);
    }

    /**
     * 根据ID获取检测详情（带缓存）
     *
     * @param id 检测任务ID
     * @return 检测结果响应
     */
    @Override
    public DetectionResultResponse getDetectionById(Long id) {
        DetectionResultResponse response = cacheService.queryWithMutex(
                cacheProperties.detectionDetailKey(id),
                DetectionResultResponse.class,
                () -> loadDetectionById(id),
                cacheProperties.getDefaultTtlMinutes(),
                TimeUnit.MINUTES
        );
        if (response == null) {
            throw new BusinessException("检测任务不存在");
        }
        if (currentUserService.hasRole("USER") && !currentUserService.getCurrentUserId().equals(response.getUserId())) {
            throw new BusinessException(403, "没有权限查看该检测记录");
        }
        return response;
    }

    /**
     * 分页获取检测记录（带缓存）
     *
     * @param page      页码
     * @param size      每页数量
     * @param buildingId 建筑ID
     * @param status    状态
     * @param riskLevel 风险等级
     * @param startDate 开始日期
     * @param endDate   结束日期
     * @return 分页结果
     */
    @Override
    public Page<DetectionResultResponse> getDetectionList(
            Integer page,
            Integer size,
            Long buildingId,
            String status,
            String riskLevel,
            LocalDate startDate,
            LocalDate endDate
    ) {
        Long currentUserId = currentUserService.getCurrentUserId();
        boolean userOnly = currentUserService.hasRole("USER");
        String cacheKey = buildDetectionListCacheKey(page, size, buildingId, status, riskLevel, startDate, endDate,
                currentUserId, userOnly);
        @SuppressWarnings("unchecked")
        Page<DetectionResultResponse> resultPage = cacheService.queryWithPassThrough(
                cacheKey,
                Page.class,
                () -> loadDetectionList(page, size, buildingId, status, riskLevel, startDate, endDate,
                        currentUserId, userOnly),
                cacheProperties.getDefaultTtlMinutes(),
                TimeUnit.MINUTES
        );
        return resultPage;
    }

    /**
     * 根据 ID 加载检测详情
     */
    private DetectionResultResponse loadDetectionById(Long id) {
        Detection detection = detectionMapper.selectById(id);
        if (detection == null) {
            return null;
        }

        Building building = buildingMapper.selectById(detection.getBuildingId());
        if (building == null) {
            throw new BusinessException("建筑不存在");
        }

        User user = userMapper.selectById(detection.getUserId());
        List<Image> images = imageMapper.findByDetectionId(id);
        return buildDetectionResponse(detection, building, user, images);
    }

    /**
     * 加载检测列表分页数据
     */
    private Page<DetectionResultResponse> loadDetectionList(
            Integer page,
            Integer size,
            Long buildingId,
            String status,
            String riskLevel,
            LocalDate startDate,
            LocalDate endDate,
            Long currentUserId,
            boolean userOnly
    ) {
        Page<Detection> detectionPage = new Page<>(page, size);
        LambdaQueryWrapper<Detection> wrapper = new LambdaQueryWrapper<>();

        wrapper.eq(buildingId != null, Detection::getBuildingId, buildingId)
                .eq(userOnly, Detection::getUserId, currentUserId)
                .eq(status != null && !status.isEmpty(), Detection::getStatus, status)
                .eq(riskLevel != null && !riskLevel.isEmpty(), Detection::getRiskLevel, riskLevel)
                .ge(startDate != null, Detection::getDetectTime, startDate != null ? startDate.atStartOfDay() : null)
                .le(endDate != null, Detection::getDetectTime, endDate != null ? endDate.plusDays(1).atStartOfDay() : null)
                .orderByDesc(Detection::getDetectTime);

        detectionPage = detectionMapper.selectPage(detectionPage, wrapper);

        Page<DetectionResultResponse> resultPage =
                new Page<>(detectionPage.getCurrent(), detectionPage.getSize(), detectionPage.getTotal());
        List<DetectionResultResponse> records = detectionPage.getRecords().stream()
                .map(detection -> {
                    Building building = buildingMapper.selectById(detection.getBuildingId());
                    User user = userMapper.selectById(detection.getUserId());
                    List<Image> imageList = imageMapper.findByDetectionId(detection.getId());
                    return buildDetectionResponse(detection, building, user, imageList);
                })
                .collect(Collectors.toList());
        resultPage.setRecords(records);
        return resultPage;
    }

    /**
     * 获取用户创建的所有检测记录
     *
     * @param userId 用户ID
     * @return 检测记录列表
     */
    @Override
    public List<DetectionResultResponse> getDetectionsByUserId(Long userId) {
        List<Detection> detections = detectionMapper.selectList(
                new LambdaQueryWrapper<Detection>()
                        .eq(Detection::getUserId, userId)
                        .orderByDesc(Detection::getDetectTime)
        );

        return detections.stream()
                .map(detection -> {
                    Building building = buildingMapper.selectById(detection.getBuildingId());
                    User user = userMapper.selectById(detection.getUserId());
                    List<Image> images = imageMapper.findByDetectionId(detection.getId());
                    return buildDetectionResponse(detection, building, user, images);
                })
                .collect(Collectors.toList());
    }

    /**
     * 单图上传检测兼容方法
     *
     * @param buildingId 建筑ID
     * @param file       图片文件
     * @return 检测结果响应
     */
    @Override
    @Transactional(rollbackFor = Exception.class)
    public DetectionResultResponse uploadAndDetect(Long buildingId, MultipartFile file) {
        return uploadAndDetectMultiple(buildingId, List.of(file), null);
    }

    /**
     * 批量上传图片并执行检测
     *
     * @param buildingId 建筑ID
     * @param files      图片文件列表
     * @param imageType  图片类型
     * @return 检测结果响应
     */
    @Override
    @Transactional(rollbackFor = Exception.class)
    public DetectionResultResponse uploadAndDetectMultiple(Long buildingId, List<MultipartFile> files, String imageType) {
        Building building = buildingMapper.selectById(buildingId);
        if (building == null) {
            throw new BusinessException("建筑不存在");
        }

        validateBuildingAccess(building);

        User currentUser = currentUserService.getCurrentUser();
        Long userId = currentUser.getId();

        if (files == null || files.isEmpty()) {
            throw new BusinessException("请至少上传一张图片");
        }

        log.info("开始批量图片检测：buildingId={}, userId={}, 图片数量={}", buildingId, userId, files.size());

        Detection detection = new Detection();
        detection.setBuildingId(buildingId);
        detection.setUserId(userId);
        detection.setStatus("PROCESSING");
        detection.setCrackCount(0);
        detection.setDamageRatio(BigDecimal.ZERO);
        detection.setRiskLevel("A");
        detection.setDetectTime(LocalDateTime.now());
        detection.setUpdatedAt(LocalDateTime.now());
        detectionMapper.insert(detection);
        evictDetectionCache(detection.getId());
        evictDashboardCache();

        List<Image> savedImages = new ArrayList<>();
        List<File> imageFiles = new ArrayList<>();

        for (MultipartFile file : files) {
            if (file == null || file.isEmpty()) {
                continue;
            }

            String filePath = fileUploadUtil.uploadDetectionOriginalImage(file, detection.getId());
            File imageFile = fileUploadUtil.getFile(filePath);
            imageFiles.add(imageFile);

            Image image = new Image();
            image.setDetectionId(detection.getId());
            image.setImagePath(filePath);
            image.setImageType("ORIGINAL");
            image.setUploadTime(LocalDateTime.now());
            imageMapper.insert(image);
            savedImages.add(image);
        }

        if (imageFiles.isEmpty()) {
            detection.setStatus("FAILED");
            detection.setErrorMessage("请至少上传一张有效图片");
            detection.setUpdatedAt(LocalDateTime.now());
            detectionMapper.updateById(detection);
            evictDetectionCache(detection.getId());
            evictDashboardCache();
            throw new BusinessException("请至少上传一张有效图片");
        }

        try {
            AiDetectionResponse.DataInfo dataInfo = detectionAiClientService.detect(imageFiles);
            detectionAiClientService.applyAnalysisToDetection(detection, dataInfo);
            detection.setStatus("COMPLETED");
            detection.setErrorMessage(null);
            detection.setUpdatedAt(LocalDateTime.now());
            detectionMapper.updateById(detection);

            if (dataInfo.getImageResults() != null) {
                detectionAiClientService.persistImageResults(savedImages, dataInfo.getImageResults());
            }
        } catch (Exception ex) {
            detection.setStatus("FAILED");
            detection.setErrorMessage(ex.getMessage());
            detection.setUpdatedAt(LocalDateTime.now());
            detectionMapper.updateById(detection);
            evictDetectionCache(detection.getId());
            evictDashboardCache();
            throw ex;
        }

        evictDetectionCache(detection.getId());
        evictDashboardCache();
        return buildDetectionResponse(detection, building, currentUser, savedImages);
    }

    /**
     * 获取建筑下的所有检测记录
     *
     * @param buildingId 建筑ID
     * @return 检测记录列表
     */
    @Override
    public List<DetectionResultResponse> getDetectionsByBuildingId(Long buildingId) {
        List<Detection> detections = detectionMapper.selectList(
                new LambdaQueryWrapper<Detection>()
                        .eq(Detection::getBuildingId, buildingId)
                        .orderByDesc(Detection::getDetectTime)
        );

        Building building = buildingMapper.selectById(buildingId);

        return detections.stream()
                .map(detection -> {
                    User user = userMapper.selectById(detection.getUserId());
                    List<Image> images = imageMapper.findByDetectionId(detection.getId());
                    return buildDetectionResponse(detection, building, user, images);
                })
                .collect(Collectors.toList());
    }

    /**
     * 删除建筑下的所有检测记录
     *
     * @param buildingId 建筑ID
     */
    @Override
    @Transactional(rollbackFor = Exception.class)
    public void deleteByBuildingId(Long buildingId) {
        List<Detection> detections = detectionMapper.selectList(
                new LambdaQueryWrapper<Detection>()
                        .eq(Detection::getBuildingId, buildingId)
        );

        for (Detection detection : detections) {
            imageMapper.deleteByDetectionId(detection.getId());
            reportMapper.delete(
                    new LambdaQueryWrapper<Report>()
                            .eq(Report::getDetectionId, detection.getId())
            );
            detectionMapper.deleteById(detection.getId());
            evictDetectionCache(detection.getId());
        }

        evictDashboardCache();
        log.info("删除建筑下所有检测记录成功：buildingId={}, 删除数量={}", buildingId, detections.size());
    }

    /**
     * 解析图片路径为文件对象
     *
     * @param images 图片实体列表
     * @return 文件对象列表
     */
    private List<File> resolveImageFiles(List<Image> images) {
        List<File> imageFiles = new ArrayList<>();
        for (Image image : images) {
            File file = fileUploadUtil.getFile(image.getImagePath());
            if (file != null && file.exists()) {
                imageFiles.add(file);
            }
        }
        return imageFiles;
    }

    /**
     * 构建检测结果响应对象
     *
     * @param detection 检测记录
     * @param building  建筑信息
     * @param user      用户信息
     * @param images    图片列表
     * @return 检测结果响应
     */
    private DetectionResultResponse buildDetectionResponse(
            Detection detection,
            Building building,
            User user,
            List<Image> images
    ) {
        Report report = reportMapper.selectOne(
                new LambdaQueryWrapper<Report>()
                        .eq(Report::getDetectionId, detection.getId())
                        .last("LIMIT 1")
        );
        List<AiDetectionResponse.DataInfo> dataInfos =
                detectionAiClientService.parseDetectResult(detection.getDetectResult());
        Map<String, Object> detectResultMap =
                detectionAiClientService.parseDetectResultToMap(detection.getDetectResult());
        return detectionResultAssembler.assemble(detection, building, user, images, report, dataInfos, detectResultMap);
    }

    /**
     * 清除检测相关缓存（检测详情和检测列表）
     *
     * @param detectionId 检测任务ID
     */
    private void evictDetectionCache(Long detectionId) {
        cacheService.delete(cacheProperties.detectionDetailKey(detectionId));
        cacheService.deleteByPrefix(cacheProperties.getDetectionListPrefix());
    }

    /**
     * 清除仪表盘缓存
     */
    private void evictDashboardCache() {
        cacheService.delete(cacheProperties.getDashboardKey());
    }

    /**
     * 构建检测列表缓存键名
     *
     * @param page      页码
     * @param size      每页数量
     * @param buildingId 建筑ID
     * @param status    状态
     * @param riskLevel 风险等级
     * @param startDate 开始日期
     * @param endDate   结束日期
     * @return 缓存键名
     */
    private String buildDetectionListCacheKey(Integer page, Integer size, Long buildingId, String status,
            String riskLevel, LocalDate startDate, LocalDate endDate, Long currentUserId, boolean userOnly) {
        return cacheProperties.getDetectionListPrefix()
                + safe(page) + ":"
                + safe(size) + ":"
                + safe(buildingId) + ":"
                + safe(status) + ":"
                + safe(riskLevel) + ":"
                + safe(startDate) + ":"
                + safe(endDate) + ":"
                + safe(currentUserId) + ":"
                + safe(userOnly);
    }

    /**
     * 安全地将对象转换为字符串，null值转为下划线
     *
     * @param value 对象
     * @return 字符串
     */
    private String safe(Object value) {
        return value == null ? "_" : String.valueOf(value).trim();
    }

    /**
     * 验证建筑访问权限
     */
    private void validateBuildingAccess(Building building) {
        if (!currentUserService.hasRole("USER")) {
            return;
        }
        Long currentUserId = currentUserService.getCurrentUserId();
        if (building.getOwnerUserId() == null || !building.getOwnerUserId().equals(currentUserId)) {
            throw new BusinessException(403, "没有权限操作该建筑的检测记录");
        }
    }

    /**
     * 验证检测任务访问权限
     */
    private void validateDetectionAccess(Detection detection) {
        if (!currentUserService.hasRole("USER")) {
            return;
        }
        Long currentUserId = currentUserService.getCurrentUserId();
        if (detection.getUserId() == null || !detection.getUserId().equals(currentUserId)) {
            throw new BusinessException(403, "没有权限操作该检测记录");
        }
    }
}
