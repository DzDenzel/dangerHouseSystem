package com.dz.dangerhouse.service;

import com.dz.dangerhouse.entity.Report;

/**
 * 检测报告服务
 */
public interface DetectionReportService {
    
    /**
     * 确保检测报告存在，不存在则创建
     *
     * @param detectionId 检测任务ID
     * @param buildingId 建筑ID
     * @param fileType 文件类型
     * @return 报告实体
     */
    Report ensureReport(Long detectionId, Long buildingId, String fileType);
}