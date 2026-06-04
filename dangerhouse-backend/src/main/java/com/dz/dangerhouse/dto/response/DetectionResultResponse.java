package com.dz.dangerhouse.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

/**
 * 检测结果响应 DTO
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class DetectionResultResponse {

    /**
     * 检测记录 ID
     */
    private Long id;

    /**
     * 建筑 ID
     */
    private Long buildingId;

    /**
     * 建筑名称
     */
    private String buildingName;

    /**
     * 建筑地址
     */
    private String buildingAddress;

    /**
     * 检测人员用户 ID
     */
    private Long userId;

    /**
     * 检测人员用户名
     */
    private String username;

    /**
     * 检测状态：CREATED、READY、PROCESSING、COMPLETED、FAILED、CANCELLED
     */
    private String status;

    /**
     * 裂缝数量
     */
    private Integer crackCount;

    /**
     * 损伤比例
     */
    private Double damageRatio;

    /**
     * 风险等级：A-无风险点，B-有风险点，C-局部危房，D-整幢危房
     */
    private String riskLevel;

    /**
     * 检测置信度
     */
    private Double confidence;

    /**
     * 检测结果详情（JSON）
     */
    private Map<String, Object> detectResult;

    /**
     * 检测时间
     */
    private LocalDateTime detectTime;

    /**
     * 描述信息
     */
    private String description;

    /**
     * 检测失败原因
     */
    private String errorMessage;

    /**
     * 创建时间
     */
    private LocalDateTime createdAt;

    /**
     * 更新时间
     */
    private LocalDateTime updatedAt;

    /**
     * 图片列表（支持多图）
     */
    private List<ImageInfo> images;

    /**
     * 报告信息
     */
    private ReportInfo report;

    /**
     * 图片信息（用于多图返回）
     */
    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class ImageInfo {

        /**
         * 图片 ID
         */
        private Long id;

        /**
         * 原始图片 URL
         */
        private String imagePath;

        /**
         * 检测结果图 URL
         */
        private String resultImagePath;

        /**
         * 图片类型 (ORIGINAL/RESULT)
         */
        private String imageType;

        /**
         * 上传时间
         */
        private LocalDateTime uploadTime;
    }

    /**
     * 报告信息
     */
    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class ReportInfo {

        /**
         * 报告 ID
         */
        private Long id;

        /**
         * 报告编号
         */
        private String reportNo;

        /**
         * 报告文件路径
         */
        private String filePath;

        /**
         * 生成时间
         */
        private LocalDateTime generatedAt;
    }
}
