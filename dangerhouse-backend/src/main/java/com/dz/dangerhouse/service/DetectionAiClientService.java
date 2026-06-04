package com.dz.dangerhouse.service;

import com.dz.dangerhouse.dto.response.AiDetectionResponse;
import com.dz.dangerhouse.entity.Detection;
import com.dz.dangerhouse.entity.Image;

import java.io.File;
import java.util.List;
import java.util.Map;

/**
 * AI 检测客户端服务
 */
public interface DetectionAiClientService {
    
    /**
     * 调用AI服务检测图片
     *
     * @param imageFiles 图片文件列表
     * @return AI检测响应数据
     */
    AiDetectionResponse.DataInfo detect(List<File> imageFiles);

    /**
     * 将AI分析结果应用到检测记录
     *
     * @param detection 检测记录实体
     * @param dataInfo AI检测数据
     */
    void applyAnalysisToDetection(Detection detection, AiDetectionResponse.DataInfo dataInfo);

    /**
     * 持久化图片检测结果
     *
     * @param images 图片实体列表
     * @param results AI检测结果列表
     */
    void persistImageResults(List<Image> images, List<AiDetectionResponse.ImageResult> results);

    /**
     * 解析检测结果字符串
     *
     * @param detectResult 检测结果JSON字符串
     * @return 解析后的数据列表
     */
    List<AiDetectionResponse.DataInfo> parseDetectResult(String detectResult);

    /**
     * 解析检测结果为Map
     *
     * @param detectResult 检测结果JSON字符串
     * @return 解析后的Map对象
     */
    Map<String, Object> parseDetectResultToMap(String detectResult);
}