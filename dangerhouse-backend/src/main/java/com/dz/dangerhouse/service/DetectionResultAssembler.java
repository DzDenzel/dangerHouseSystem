package com.dz.dangerhouse.service;

import com.dz.dangerhouse.dto.response.AiDetectionResponse;
import com.dz.dangerhouse.dto.response.DetectionResultResponse;
import com.dz.dangerhouse.entity.Building;
import com.dz.dangerhouse.entity.Detection;
import com.dz.dangerhouse.entity.Image;
import com.dz.dangerhouse.entity.Report;
import com.dz.dangerhouse.entity.User;

import java.util.List;
import java.util.Map;

/**
 * 检测结果 DTO 组装器
 */
public interface DetectionResultAssembler {
    
    /**
     * 组装检测结果响应对象
     *
     * @param detection 检测记录
     * @param building 建筑信息
     * @param user 用户信息
     * @param images 图片列表
     * @param report 报告信息
     * @param dataInfos AI检测数据列表
     * @param detectResultMap 检测结果Map
     * @return 检测结果响应对象
     */
    DetectionResultResponse assemble(
            Detection detection,
            Building building,
            User user,
            List<Image> images,
            Report report,
            List<AiDetectionResponse.DataInfo> dataInfos,
            Map<String, Object> detectResultMap
    );
}