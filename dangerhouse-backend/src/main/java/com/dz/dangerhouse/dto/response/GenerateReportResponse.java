package com.dz.dangerhouse.dto.response;

import lombok.Data;

import java.time.LocalDateTime;

/**
 * 报告生成响应
 */
@Data
public class GenerateReportResponse {
    
    /**
     * 报告ID
     */
    private Long reportId;
    
    /**
     * 报告编号
     */
    private String reportNo;
    
    /**
     * 下载链接
     */
    private String downloadUrl;
    
    /**
     * 报告状态
     */
    private String status;
    
    /**
     * 创建时间
     */
    private LocalDateTime createdAt;
}
