package com.dz.dangerhouse.dto.request;

import lombok.Data;

/**
 * 生成报告请求
 */
@Data
public class GenerateReportRequest {
    
    /**
     * 检测任务ID
     */
    private Long detectionId;
    
    /**
     * 报告格式（PDF/DOCX）
     */
    private String format;
}