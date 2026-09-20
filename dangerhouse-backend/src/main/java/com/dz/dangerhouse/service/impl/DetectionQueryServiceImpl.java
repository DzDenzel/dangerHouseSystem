package com.dz.dangerhouse.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.dz.dangerhouse.dto.response.DetectionResultResponse;
import com.dz.dangerhouse.entity.Image;
import com.dz.dangerhouse.mapper.ImageMapper;
import com.dz.dangerhouse.service.DetectionQueryService;
import com.dz.dangerhouse.util.FileUploadUtil;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.stream.Collectors;

/**
 * 检测查询服务实现类
 */
@Service
public class DetectionQueryServiceImpl implements DetectionQueryService {

    @Autowired
    private ImageMapper imageMapper;

    @Autowired
    private FileUploadUtil fileUploadUtil;

    @Override
    public List<DetectionResultResponse.ImageInfo> getImages(Long detectionId) {
        List<Image> images = imageMapper.selectList(
                new QueryWrapper<Image>()
                        .lambda()
                        .eq(Image::getDetectionId, detectionId)
                        .orderByAsc(Image::getId)
        );

        return images.stream()
                .map(image -> {
                    DetectionResultResponse.ImageInfo info = new DetectionResultResponse.ImageInfo();
                    info.setId(image.getId());
                    info.setImagePath(fileUploadUtil.getFileUrl(image.getImagePath()));
                    info.setResultImagePath(image.getResultImagePath() != null ?
                            fileUploadUtil.getFileUrl(image.getResultImagePath()) : null);
                    info.setImageType(image.getImageType());
                    info.setUploadTime(image.getUploadTime());
                    return info;
                })
                .collect(Collectors.toList());
    }
}