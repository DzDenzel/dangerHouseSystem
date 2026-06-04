package com.dz.dangerhouse.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.dz.dangerhouse.cache.CacheProperties;
import com.dz.dangerhouse.cache.CacheService;
import com.dz.dangerhouse.dto.response.GenerateReportResponse;
import com.dz.dangerhouse.dto.response.ReportResponse;
import com.dz.dangerhouse.entity.Building;
import com.dz.dangerhouse.entity.Detection;
import com.dz.dangerhouse.entity.Image;
import com.dz.dangerhouse.entity.Report;
import com.dz.dangerhouse.exception.BusinessException;
import com.dz.dangerhouse.mapper.BuildingMapper;
import com.dz.dangerhouse.mapper.DetectionMapper;
import com.dz.dangerhouse.mapper.ImageMapper;
import com.dz.dangerhouse.mapper.ReportMapper;
import com.dz.dangerhouse.service.CurrentUserService;
import com.dz.dangerhouse.service.ReportService;
import com.dz.dangerhouse.util.FileUploadUtil;
import com.dz.dangerhouse.util.PdfReportGenerator;
import com.dz.dangerhouse.util.ReportNumberGenerator;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;
import java.util.concurrent.TimeUnit;

/**
 * 报告服务实现类
 */
@Slf4j
@Service
public class ReportServiceImpl implements ReportService {

    @Autowired
    private ReportMapper reportMapper;

    @Autowired
    private DetectionMapper detectionMapper;

    @Autowired
    private BuildingMapper buildingMapper;

    @Autowired
    private ImageMapper imageMapper;

    @Autowired
    private ReportNumberGenerator reportNumberGenerator;

    @Autowired
    private PdfReportGenerator pdfReportGenerator;

    @Autowired
    private FileUploadUtil fileUploadUtil;

    @Autowired
    private CacheService cacheService;

    @Autowired
    private CacheProperties cacheProperties;

    @Autowired
    private CurrentUserService currentUserService;

    /**
     * 生成检测报告
     */
    @Override
    public GenerateReportResponse generateReport(Long detectionId, String format) {
        Detection detection = detectionMapper.selectById(detectionId);
        if (detection == null) {
            throw new BusinessException(404, "检测记录不存在");
        }
        validateDetectionAccess(detection);
        if (!"COMPLETED".equalsIgnoreCase(detection.getStatus())) {
            throw new BusinessException(400, "检测尚未完成，无法生成正式报告");
        }

        Building building = detection.getBuildingId() == null ? null
                : buildingMapper.selectById(detection.getBuildingId());
        List<Image> images = imageMapper.findByDetectionId(detectionId);
        if (images == null || images.isEmpty()) {
            throw new BusinessException(400, "检测图片缺失，无法生成报告");
        }

        String fileType = format == null || format.isBlank() ? "PDF" : format.toUpperCase();

        Report existingReport = reportMapper.selectOne(
                new LambdaQueryWrapper<Report>()
                        .eq(Report::getDetectionId, detectionId)
                        .last("LIMIT 1"));

        Report report = existingReport != null ? existingReport : new Report();
        String reportNo = (report.getReportNo() == null || report.getReportNo().isBlank())
                ? reportNumberGenerator.generate(detectionId)
                : report.getReportNo();

        String filePath = pdfReportGenerator.generateReport(detection, building, images, reportNo);
        LocalDateTime generatedAt = LocalDateTime.now();

        report.setBuildingId(detection.getBuildingId());
        report.setDetectionId(detectionId);
        report.setReportNo(reportNo);
        report.setFilePath(filePath);
        report.setFileType(fileType);
        report.setGeneratedAt(generatedAt);

        if (report.getId() == null) {
            reportMapper.insert(report);
        } else {
            reportMapper.updateById(report);
        }

        evictReportCache(report.getId());
        cacheService.delete(cacheProperties.detectionDetailKey(detectionId));

        log.info("报告生成成功: reportId={}, detectionId={}, reportNo={}", report.getId(), detectionId, reportNo);
        return toGenerateResponse(report);
    }

    /**
     * 根据 ID 获取报告详情（带缓存）
     */
    @Override
    public ReportResponse getReportById(Long id) {
        ReportResponse response = cacheService.queryWithMutex(
                cacheProperties.reportDetailKey(id),
                ReportResponse.class,
                () -> loadReportById(id),
                cacheProperties.getDefaultTtlMinutes(),
                TimeUnit.MINUTES
        );
        if (response == null) {
            throw new BusinessException(404, "报告不存在");
        }
        validateReportAccess(response);
        return response;
    }

    /**
     * 获取报告实体
     */
    @Override
    public Report getReportEntity(Long id) {
        Report report = reportMapper.selectById(id);
        if (report == null) {
            throw new BusinessException(404, "报告不存在");
        }
        if (report.getFilePath() == null || report.getFilePath().isBlank()) {
            throw new BusinessException(404, "报告文件不存在，请重新生成报告");
        }
        validateReportAccess(report);
        return report;
    }

    /**
     * 加载报告详情
     */
    private ReportResponse loadReportById(Long id) {
        Report report = reportMapper.selectById(id);
        return report == null ? null : toResponse(report);
    }

    /**
     * 转换为生成响应对象
     */
    private GenerateReportResponse toGenerateResponse(Report report) {
        GenerateReportResponse response = new GenerateReportResponse();
        response.setReportId(report.getId());
        response.setReportNo(report.getReportNo());
        response.setDownloadUrl(fileUploadUtil.getFileUrl(report.getFilePath()));
        response.setStatus("READY");
        response.setCreatedAt(report.getGeneratedAt());
        return response;
    }

    /**
     * 转换为响应对象
     */
    private ReportResponse toResponse(Report report) {
        ReportResponse response = new ReportResponse();
        response.setId(report.getId());
        response.setDetectionId(report.getDetectionId());
        response.setBuildingId(report.getBuildingId());
        response.setReportNo(report.getReportNo());
        response.setFilePath(fileUploadUtil.getFileUrl(report.getFilePath()));
        response.setDownloadUrl(fileUploadUtil.getFileUrl(report.getFilePath()));
        response.setFileType(report.getFileType());
        response.setStatus(report.getFilePath() == null || report.getFilePath().isBlank() ? "PENDING" : "READY");
        response.setGeneratedAt(report.getGeneratedAt());
        return response;
    }

    /**
     * 清除报告缓存
     */
    private void evictReportCache(Long reportId) {
        cacheService.delete(cacheProperties.reportDetailKey(reportId));
    }

    /**
     * 验证报告访问权限
     */
    private void validateReportAccess(ReportResponse report) {
        if (!currentUserService.hasRole("USER")) {
            return;
        }
        Detection detection = detectionMapper.selectById(report.getDetectionId());
        validateDetectionAccess(detection);
    }

    /**
     * 验证报告访问权限
     */
    private void validateReportAccess(Report report) {
        if (!currentUserService.hasRole("USER")) {
            return;
        }
        Detection detection = detectionMapper.selectById(report.getDetectionId());
        validateDetectionAccess(detection);
    }

    /**
     * 验证检测访问权限
     */
    private void validateDetectionAccess(Detection detection) {
        if (detection == null) {
            throw new BusinessException(404, "检测记录不存在");
        }
        if (!currentUserService.hasRole("USER")) {
            return;
        }
        Long currentUserId = currentUserService.getCurrentUserId();
        if (!currentUserId.equals(detection.getUserId())) {
            throw new BusinessException(403, "没有权限访问该报告");
        }
    }
}
