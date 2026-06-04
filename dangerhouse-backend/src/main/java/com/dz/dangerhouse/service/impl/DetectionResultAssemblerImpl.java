package com.dz.dangerhouse.service.impl;

import com.dz.dangerhouse.dto.response.AiDetectionResponse;
import com.dz.dangerhouse.dto.response.DetectionResultResponse;
import com.dz.dangerhouse.entity.Building;
import com.dz.dangerhouse.entity.Detection;
import com.dz.dangerhouse.entity.Image;
import com.dz.dangerhouse.entity.Report;
import com.dz.dangerhouse.entity.User;
import com.dz.dangerhouse.service.DetectionResultAssembler;
import com.dz.dangerhouse.util.FileUploadUtil;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

/**
 * 检测结果DTO组装器实现
 * 负责将多个实体对象（Detection、Building、User、Image、Report等）
 * 组装成统一的检测结果响应对象（DetectionResultResponse）
 */
@Service
public class DetectionResultAssemblerImpl implements DetectionResultAssembler {

    @Autowired
    private FileUploadUtil fileUploadUtil;

    /**
     * 组装检测结果响应对象
     * 整合检测记录、建筑信息、用户信息、图片列表、报告信息和AI分析结果
     *
     * @param detection       检测记录
     * @param building        建筑信息
     * @param user            用户信息
     * @param images          图片列表
     * @param report          报告信息
     * @param dataInfos       AI检测数据列表
     * @param detectResultMap 检测结果Map
     * @return 组装好的检测结果响应对象
     */
    @Override
    public DetectionResultResponse assemble(
            Detection detection,
            Building building,
            User user,
            List<Image> images,
            Report report,
            List<AiDetectionResponse.DataInfo> dataInfos,
            Map<String, Object> detectResultMap
    ) {
        // 提取AI分析结果
        AiDetectionResponse.Analysis analysis = null;
        if (dataInfos != null) {
            for (AiDetectionResponse.DataInfo dataInfo : dataInfos) {
                if (dataInfo != null && dataInfo.getAnalysis() != null) {
                    analysis = dataInfo.getAnalysis();
                    break;
                }
            }
        }

        // 组装图片信息列表
        List<DetectionResultResponse.ImageInfo> imageInfos = new ArrayList<>();
        if (images != null) {
            for (Image image : images) {
                imageInfos.add(DetectionResultResponse.ImageInfo.builder()
                        .id(image.getId())
                        .imagePath(fileUploadUtil.getFileUrl(image.getImagePath()))
                        .resultImagePath(image.getResultImagePath() != null ?
                                fileUploadUtil.getFileUrl(image.getResultImagePath()) : null)
                        .imageType(image.getImageType())
                        .uploadTime(image.getUploadTime())
                        .build());
            }
        }

        // 组装报告信息
        DetectionResultResponse.ReportInfo reportInfo = null;
        if (report != null) {
            reportInfo = DetectionResultResponse.ReportInfo.builder()
                    .id(report.getId())
                    .reportNo(report.getReportNo())
                    .filePath(fileUploadUtil.getFileUrl(report.getFilePath()))
                    .generatedAt(report.getGeneratedAt())
                    .build();
        }

        // 构建最终的检测结果响应对象
        return DetectionResultResponse.builder()
                .id(detection.getId())
                .buildingId(building != null ? building.getId() : null)
                .buildingName(building != null ? building.getName() : null)
                .buildingAddress(building != null ? building.getAddress() : null)
                .userId(detection.getUserId())
                .username(user != null ? user.getUsername() : null)
                .crackCount(detection.getCrackCount())
                .damageRatio(detection.getDamageRatio() != null ? detection.getDamageRatio().doubleValue() : null)
                .riskLevel(detection.getRiskLevel())
                .confidence(detection.getConfidence() != null ? detection.getConfidence().doubleValue() : null)
                .detectResult(detectResultMap)
                .detectTime(detection.getDetectTime())
                .createdAt(detection.getCreatedAt())
                .updatedAt(detection.getUpdatedAt())
                .status(detection.getStatus())
                .description(detection.getDescription())
                .errorMessage(detection.getErrorMessage())
                .images(imageInfos)
                .report(reportInfo)
                .build();
    }
}
