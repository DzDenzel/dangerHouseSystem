package com.dz.dangerhouse.dto.response;

import lombok.Data;

import java.time.LocalDateTime;

/**
 * 报告详情响应
 */
@Data
public class ReportResponse {
    
    /**
     * 报告ID
     */
    private Long id;
    
    /**
     * 检测任务ID
     */
    private Long detectionId;
    
    /**
     * 建筑ID
     */
    private Long buildingId;
    
    /**
     * 报告编号
     */
    private String reportNo;
    
    /**
     * 文件路径
     */
    private String filePath;
    
    /**
     * 下载链接
     */
    private String downloadUrl;
    
    /**
     * 文件类型
     */
    private String fileType;
    
    /**
     * 报告状态
     */
    private String status;
    
    /**
     * 生成时间
     */
    private LocalDateTime generatedAt;
}
