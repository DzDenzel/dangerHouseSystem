package com.dz.dangerhouse.service.impl;

import cn.hutool.json.JSONArray;
import cn.hutool.json.JSONObject;
import cn.hutool.json.JSONUtil;
import com.dz.dangerhouse.client.AiDetectionClient;
import com.dz.dangerhouse.dto.response.AiDetectionResponse;
import com.dz.dangerhouse.entity.Detection;
import com.dz.dangerhouse.entity.Image;
import com.dz.dangerhouse.exception.BusinessException;
import com.dz.dangerhouse.mapper.ImageMapper;
import com.dz.dangerhouse.service.DetectionAiClientService;
import com.dz.dangerhouse.util.FileUploadUtil;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.io.File;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * AI检测客户端服务实现类
 * 负责调用AI检测服务、处理检测结果、保存图片结果等
 */
@Slf4j
@Service
public class DetectionAiClientServiceImpl implements DetectionAiClientService {

    @Autowired
    private AiDetectionClient aiDetectionClient;

    @Autowired
    private FileUploadUtil fileUploadUtil;

    @Autowired
    private ImageMapper imageMapper;

    /**
     * 调用AI检测服务进行图片分析
     *
     * @param imageFiles 图片文件列表
     * @return AI检测数据信息
     * @throws BusinessException 如果AI检测失败
     */
    @Override
    public AiDetectionResponse.DataInfo detect(List<File> imageFiles) {
        AiDetectionResponse response = aiDetectionClient.detectDamage(imageFiles);
        if (response == null || response.getCode() == null || response.getCode() != 200 || response.getData() == null) {
            String errorMsg = response != null ? response.getMessage() : "AI服务返回空结果";
            throw new BusinessException("AI检测失败: " + errorMsg);
        }
        return response.getData();
    }

    /**
     * 将AI分析结果应用到检测记录实体
     *
     * @param detection 检测记录
     * @param dataInfo  AI检测数据
     */
    @Override
    public void applyAnalysisToDetection(Detection detection, AiDetectionResponse.DataInfo dataInfo) {
        AiDetectionResponse.Analysis overallAnalysis = dataInfo.getAnalysis();
        if (overallAnalysis != null) {
            detection.setCrackCount(overallAnalysis.getCrackCount());
            if (overallAnalysis.getDamageRatio() != null) {
                detection.setDamageRatio(
                        BigDecimal.valueOf(overallAnalysis.getDamageRatio()).setScale(4, RoundingMode.HALF_UP));
            }
            detection.setRiskLevel(overallAnalysis.getSeverityLevel());
            if (overallAnalysis.getConfidenceScore() != null) {
                detection.setConfidence(
                        BigDecimal.valueOf(overallAnalysis.getConfidenceScore()).setScale(2, RoundingMode.HALF_UP));
            }
        }
        detection.setDetectResult(buildSimplifiedDetectResult(dataInfo));
    }

    /**
     * 持久化图片级别的检测结果（保存结果图路径）
     *
     * @param images  原始图片列表
     * @param results AI检测结果列表
     */
    @Override
    public void persistImageResults(List<Image> images, List<AiDetectionResponse.ImageResult> results) {
        if (images == null || results == null) {
            return;
        }

        for (int i = 0; i < images.size() && i < results.size(); i++) {
            Image image = images.get(i);
            AiDetectionResponse.ImageResult imageResult = results.get(i);
            if (imageResult.getResultImage() == null) {
                continue;
            }

            String resultPath = fileUploadUtil.saveDetectionResultImage(imageResult.getResultImage(),
                    image.getDetectionId());
            if (resultPath != null) {
                image.setResultImagePath(resultPath);
                imageMapper.updateById(image);
            }
        }
    }

    /**
     * 解析检测结果JSON字符串为DataInfo对象列表
     * 支持数组格式和单个对象格式
     *
     * @param detectResult 检测结果JSON字符串
     * @return DataInfo对象列表
     */
    @Override
    public List<AiDetectionResponse.DataInfo> parseDetectResult(String detectResult) {
        if (detectResult == null || detectResult.isBlank()) {
            return new ArrayList<>();
        }

        try {
            String content = detectResult.trim();
            // 处理数组格式
            if (content.startsWith("[")) {
                JSONArray array = JSONUtil.parseArray(content);
                List<AiDetectionResponse.DataInfo> results = new ArrayList<>();
                for (Object item : array) {
                    if (item instanceof JSONObject jsonObject) {
                        results.add(toDataInfo(jsonObject));
                    }
                }
                return results;
            }

            // 处理单个对象格式
            if (content.startsWith("{")) {
                return List.of(toDataInfo(JSONUtil.parseObj(content)));
            }

            log.warn("不支持的检测结果格式: {}", content.substring(0, Math.min(100, content.length())));
            return new ArrayList<>();
        } catch (Exception e) {
            log.warn("解析检测结果失败: {}", e.getMessage());
            return new ArrayList<>();
        }
    }

    /**
     * 解析检测结果JSON字符串为Map对象
     *
     * @param detectResult 检测结果JSON字符串
     * @return Map对象，解析失败返回null
     */
    @Override
    public Map<String, Object> parseDetectResultToMap(String detectResult) {
        if (detectResult == null || detectResult.isBlank()) {
            return null;
        }

        try {
            JSONObject jsonObject = JSONUtil.parseObj(detectResult.trim());
            return new HashMap<>(jsonObject);
        } catch (Exception e) {
            log.warn("解析检测结果为Map失败: {}", e.getMessage());
            return null;
        }
    }

    /**
     * 构建简化的检测结果JSON字符串
     * 包含裂缝列表、统计信息和评估建议
     */
    private String buildSimplifiedDetectResult(AiDetectionResponse.DataInfo dataInfo) {
        if (dataInfo == null) {
            return null;
        }

        List<Map<String, Object>> cracks = new ArrayList<>();
        List<AiDetectionResponse.DetectionItem> detections = dataInfo.getDetections();
        double maxWidth = 0.0;

        if (detections != null) {
            for (AiDetectionResponse.DetectionItem item : detections) {
                Map<String, Object> crack = new HashMap<>();
                crack.put("id", item.getId());
                crack.put("type", item.getType());
                crack.put("typeName", item.getTypeName());
                crack.put("confidence", item.getConfidence());
                crack.put("bbox", item.getBbox());
                crack.put("center", item.getCenter());
                crack.put("width", item.getWidth());
                crack.put("height", item.getHeight());
                crack.put("area", item.getArea());
                cracks.add(crack);

                if (item.getWidth() != null) {
                    maxWidth = Math.max(maxWidth, item.getWidth());
                }
            }
        }

        AiDetectionResponse.Analysis analysis = dataInfo.getAnalysis();
        Map<String, Object> result = new HashMap<>();
        result.put("cracks", cracks);
        result.put("totalCracks", cracks.size());
        result.put("maxWidth", maxWidth);
        result.put("analysis", analysis != null ? analysis.getRecommendation() : "");

        if (analysis != null) {
            result.put("severityLevel", analysis.getSeverityLevel());
            result.put("damageRatio", analysis.getDamageRatio());
            result.put("crackCount", analysis.getCrackCount());
            result.put("confidenceScore", analysis.getConfidenceScore());
        }

        return JSONUtil.toJsonStr(result);
    }

    /**
     * 将JSONObject转换为DataInfo对象
     * 兼容不同的JSON结构
     */
    private AiDetectionResponse.DataInfo toDataInfo(JSONObject source) {
        if (source == null) {
            return AiDetectionResponse.DataInfo.builder().build();
        }

        JSONObject analysisNode = source.getJSONObject("analysis");
        AiDetectionResponse.Analysis analysis;
        List<AiDetectionResponse.DetectionItem> detections;

        if (analysisNode != null) {
            analysis = AiDetectionResponse.Analysis.builder()
                    .severityLevel(analysisNode.getStr("severityLevel"))
                    .damageRatio(getDouble(analysisNode.get("damageRatio")))
                    .crackCount(getInteger(analysisNode.get("crackCount")))
                    .confidenceScore(getDouble(analysisNode.get("confidenceScore")))
                    .recommendation(analysisNode.getStr("recommendation"))
                    .build();
            detections = toDetectionItems(source.getJSONArray("detections"));
        } else {
            analysis = AiDetectionResponse.Analysis.builder()
                    .severityLevel(source.getStr("severityLevel"))
                    .damageRatio(getDouble(source.get("damageRatio")))
                    .crackCount(getInteger(source.get("crackCount")))
                    .confidenceScore(getDouble(source.get("confidenceScore")))
                    .recommendation(source.getStr("analysis"))
                    .build();
            detections = toDetectionItems(source.getJSONArray("cracks"));
        }

        return AiDetectionResponse.DataInfo.builder()
                .analysis(analysis)
                .detections(detections)
                .imageResults(Collections.emptyList())
                .resultImage(source.getStr("resultImage"))
                .build();
    }

    /**
     * 将JSONArray转换为DetectionItem列表
     */
    private List<AiDetectionResponse.DetectionItem> toDetectionItems(JSONArray array) {
        List<AiDetectionResponse.DetectionItem> items = new ArrayList<>();
        if (array == null) {
            return items;
        }

        for (Object item : array) {
            if (!(item instanceof JSONObject jsonObject)) {
                continue;
            }

            items.add(AiDetectionResponse.DetectionItem.builder()
                    .id(getInteger(jsonObject.get("id")))
                    .type(jsonObject.getStr("type"))
                    .typeName(jsonObject.getStr("typeName"))
                    .confidence(getDouble(jsonObject.get("confidence")))
                    .bbox(toIntegerList(jsonObject.getJSONArray("bbox")))
                    .center(toIntegerList(jsonObject.getJSONArray("center")))
                    .width(getInteger(jsonObject.get("width")))
                    .height(getInteger(jsonObject.get("height")))
                    .area(getInteger(jsonObject.get("area")))
                    .build());
        }

        return items;
    }

    /**
     * 将JSONArray转换为Integer列表
     */
    private List<Integer> toIntegerList(JSONArray array) {
        if (array == null) {
            return null;
        }

        List<Integer> values = new ArrayList<>();
        for (Object item : array) {
            Integer value = getInteger(item);
            if (value != null) {
                values.add(value);
            }
        }
        return values;
    }

    /**
     * 安全地将Object转换为Integer
     */
    private Integer getInteger(Object value) {
        if (value instanceof Number number) {
            return number.intValue();
        }
        if (value instanceof String text && !text.isBlank()) {
            try {
                return Integer.parseInt(text);
            } catch (NumberFormatException ignored) {
                return null;
            }
        }
        return null;
    }

    /**
     * 安全地将Object转换为Double
     */
    private Double getDouble(Object value) {
        if (value instanceof Number number) {
            return number.doubleValue();
        }
        if (value instanceof String text && !text.isBlank()) {
            try {
                return Double.parseDouble(text);
            } catch (NumberFormatException ignored) {
                return null;
            }
        }
        return null;
    }
}
