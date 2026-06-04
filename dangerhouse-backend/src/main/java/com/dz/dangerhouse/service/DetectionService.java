package com.dz.dangerhouse.service;

import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.dz.dangerhouse.dto.response.DetectionResultResponse;
import org.springframework.web.multipart.MultipartFile;

import java.time.LocalDate;
import java.util.List;

/**
 * 检测服务接口
 */
public interface DetectionService {

    /**
     * 为建筑创建空的检测任务
     */
    DetectionResultResponse createTask(Long buildingId, Long userId, String description);

    /**
     * 为现有检测任务上传一张或多张图片
     */
    List<DetectionResultResponse.ImageInfo> uploadImages(Long detectionId, List<MultipartFile> images);

    /**
     * 启动检测任务的AI分析
     */
    DetectionResultResponse startDetection(Long detectionId);

    /**
     * 取消待处理的检测任务
     */
    void cancelDetection(Long detectionId);

    /**
     * 删除检测任务
     */
    void deleteDetection(Long id);

    /**
     * 分页获取检测记录
     */
    Page<DetectionResultResponse> getDetectionList(
            Integer page,
            Integer size,
            Long buildingId,
            String status,
            String riskLevel,
            LocalDate startDate,
            LocalDate endDate
    );

    /**
     * 根据ID获取检测详情
     */
    DetectionResultResponse getDetectionById(Long id);

    /**
     * 获取用户创建的所有检测记录
     */
    List<DetectionResultResponse> getDetectionsByUserId(Long userId);

    /**
     * 单图上传检测兼容方法
     */
    DetectionResultResponse uploadAndDetect(Long buildingId, MultipartFile file);

    /**
     * 获取建筑下的所有检测记录
     */
    List<DetectionResultResponse> getDetectionsByBuildingId(Long buildingId);

    /**
     * 批量上传图片并执行检测
     */
    DetectionResultResponse uploadAndDetectMultiple(Long buildingId, List<MultipartFile> files, String imageType);

    /**
     * 删除建筑下的所有检测记录
     */
    void deleteByBuildingId(Long buildingId);
}
