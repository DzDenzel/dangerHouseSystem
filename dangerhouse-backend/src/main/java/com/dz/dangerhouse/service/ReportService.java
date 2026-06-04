package com.dz.dangerhouse.service;

import com.dz.dangerhouse.dto.response.GenerateReportResponse;
import com.dz.dangerhouse.dto.response.ReportResponse;
import com.dz.dangerhouse.entity.Report;

/**
 * 报告服务
 */
public interface ReportService {

    /**
     * 生成检测报告
     *
     * @param detectionId 检测任务ID
     * @param format 报告格式（PDF/WORD）
     * @return 报告生成响应
     */
    GenerateReportResponse generateReport(Long detectionId, String format);

    /**
     * 根据ID获取报告信息
     *
     * @param id 报告ID
     * @return 报告响应
     */
    ReportResponse getReportById(Long id);

    /**
     * 根据ID获取报告实体
     *
     * @param id 报告ID
     * @return 报告实体
     */
    Report getReportEntity(Long id);
}