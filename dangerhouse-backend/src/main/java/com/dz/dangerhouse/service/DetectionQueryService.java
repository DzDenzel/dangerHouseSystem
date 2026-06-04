package com.dz.dangerhouse.service;

import com.dz.dangerhouse.dto.response.DetectionResultResponse;

import java.util.List;

/**
 * 检测查询服务
 */
public interface DetectionQueryService {
    
    /**
     * 获取检测任务的图片列表
     *
     * @param detectionId 检测任务ID
     * @return 图片信息列表
     */
    List<DetectionResultResponse.ImageInfo> getImages(Long detectionId);
}