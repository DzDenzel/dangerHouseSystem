package com.dz.dangerhouse.dto.response;

import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;
import lombok.Builder;

import java.util.List;

/**
 * AI 检测响应 DTO
 * 映射 Python FastAPI AI 微服务的返回结果
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class AiDetectionResponse {

    /**
     * 响应码 (200-成功, 其他-失败)
     */
    private Integer code;

    /**
     * 响应消息
     */
    private String message;

    /**
     * 检测数据
     */
    private DataInfo data;

    /**
     * 检测数据详情
     */
    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class DataInfo {

        /**
         * 整体分析结果 (针对建筑整体)
         */
        private Analysis analysis;

        /**
         * 所有图片检测到的损伤列表(汇总)
         */
        private List<DetectionItem> detections;

        /**
         * 单图检测详情列表
         */
        private List<ImageResult> imageResults;

        /**
         * 结果图片路径（兼容旧版，通常为第一张或汇总图）
         */
        private String resultImage;
    }

    /**
     * 单张图片检测结果
     */
    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class ImageResult {
        /**
         * 文件名
         */
        private String filename;

        /**
         * 该图检测到的损伤列表
         */
        private List<DetectionItem> detections;

        /**
         * 该图的结果图 (Base64)
         */
        private String resultImage;

        /**
         * 该图的分析结果
         */
        private Analysis analysis;
    }

    /**
     * 分析结果详情
     */
    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class Analysis {

        /**
         * 损伤等级 (A/B/C/D)
         * A-无风险点，B-有风险点，C-局部危房，D-整幢危房
         */
        private String severityLevel;

        /**
         * 损伤面积占比 (百分比 0-100)
         */
        private Double damageRatio;

        /**
         * 裂缝数量
         */
        private Integer crackCount;

        /**
         * 检测置信度 (0-100)
         */
        private Double confidenceScore;

        /**
         * 建议措施
         */
        private String recommendation;
    }

    /**
     * 单个检测损伤详情
     */
    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class DetectionItem {

        /**
         * 损伤ID
         */
        private Integer id;

        /**
         * 损伤类型 (crack/corrosion/spalling 等)
         */
        private String type;

        /**
         * 损伤类型中文描述
         */
        private String typeName;

        /**
         * 置信度 (0-100)
         */
        private Double confidence;

        /**
         * 边界框 [x1, y1, x2, y2]
         */
        private List<Integer> bbox;

        /**
         * 中心点坐标 [x, y]
         */
        private List<Integer> center;

        /**
         * 宽度 (像素)
         */
        private Integer width;

        /**
         * 高度 (像素)
         */
        private Integer height;

        /**
         * 面积 (平方像素)
         */
        private Integer area;
    }
}