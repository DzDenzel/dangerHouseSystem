package com.dz.dangerhouse.controller;

import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.dz.dangerhouse.annotation.Log;
import com.dz.dangerhouse.common.Result;
import com.dz.dangerhouse.dto.request.DetectionQueryRequest;
import com.dz.dangerhouse.dto.response.DetectionResultResponse;
import com.dz.dangerhouse.dto.response.PageResponse;
import com.dz.dangerhouse.exception.BusinessException;
import com.dz.dangerhouse.service.CurrentUserService;
import com.dz.dangerhouse.service.DetectionQueryService;
import com.dz.dangerhouse.service.DetectionService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.ModelAttribute;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

import java.util.ArrayList;
import java.util.List;

/**
 * 检测管理控制器
 */
@Slf4j
@RestController
@RequestMapping("/api/detections")
@Tag(name = "检测管理", description = "危房检测相关接口")
public class DetectionController {

    @Autowired
    private DetectionService detectionService;

    @Autowired
    private CurrentUserService currentUserService;

    @Autowired
    private DetectionQueryService detectionQueryService;

    /**
     * 创建检测任务
     */
    @PostMapping
    @PreAuthorize("hasAnyRole('USER','INSPECTOR','ADMIN')")
    @Operation(summary = "创建检测任务", description = "创建检测任务并绑定建筑")
    @Log(operation = "创建检测任务", method = "POST /api/detections", recordParams = false)
    public Result<DetectionResultResponse> createDetection(
            @RequestParam("buildingId") Long buildingId,
            @RequestParam(value = "description", required = false) String description) {
        log.info("Create detection task for building {}", buildingId);
        Long userId = currentUserService.getCurrentUserId();
        DetectionResultResponse result = detectionService.createTask(buildingId, userId, description);
        return Result.success("检测任务创建成功", result);
    }

    /**
     * 上传检测图片
     */
    @PostMapping("/{id}/images")
    @PreAuthorize("hasAnyRole('USER','INSPECTOR','ADMIN')")
    @Operation(summary = "上传检测图片", description = "为指定检测任务上传图片，支持多张")
    @Log(operation = "上传检测图片", method = "POST /api/detections/{id}/images", recordParams = false)
    public Result<List<DetectionResultResponse.ImageInfo>> uploadImages(
            @PathVariable Long id,
            @RequestParam("images") List<MultipartFile> images) {
        List<MultipartFile> validFiles = new ArrayList<>();
        for (MultipartFile file : images) {
            if (file != null && !file.isEmpty()) {
                validFiles.add(file);
            }
        }

        if (validFiles.isEmpty()) {
            throw new BusinessException(400, "请至少上传一张有效图片");
        }

        List<DetectionResultResponse.ImageInfo> result = detectionService.uploadImages(id, validFiles);
        return Result.success("上传成功", result);
    }

    /**
     * 启动检测任务
     */
    @PostMapping("/{id}/start")
    @PreAuthorize("hasAnyRole('USER','INSPECTOR','ADMIN')")
    @Operation(summary = "启动检测", description = "触发 AI 分析流程")
    @Log(operation = "启动检测", method = "POST /api/detections/{id}/start")
    public Result<DetectionResultResponse> startDetection(@PathVariable Long id) {
        return Result.success("检测任务已启动", detectionService.startDetection(id));
    }

    /**
     * 获取检测详情
     */
    @GetMapping("/{id}")
    @PreAuthorize("hasAnyRole('USER','INSPECTOR','ADMIN')")
    @Operation(summary = "获取检测详情", description = "获取检测任务详情状态和结果")
    @Log(operation = "查看检测详情", method = "GET /api/detections/{id}", recordParams = false)
    public Result<DetectionResultResponse> getDetectionById(@PathVariable Long id) {
        return Result.success(detectionService.getDetectionById(id));
    }

    /**
     * 获取检测图片列表
     */
    @GetMapping("/{id}/images")
    @PreAuthorize("hasAnyRole('USER','INSPECTOR','ADMIN')")
    @Operation(summary = "获取检测图片列表", description = "获取任务关联的全部图片")
    @Log(operation = "查看检测图片", method = "GET /api/detections/{id}/images", recordParams = false)
    public Result<List<DetectionResultResponse.ImageInfo>> getImages(@PathVariable Long id) {
        return Result.success(detectionQueryService.getImages(id));
    }

    /**
     * 获取检测记录列表
     */
    @GetMapping
    @PreAuthorize("hasAnyRole('USER','INSPECTOR','ADMIN')")
    @Operation(summary = "获取检测记录列表", description = "获取检测记录列表，支持分页和筛选")
    @Log(operation = "获取检测记录列表", method = "GET /api/detections", recordParams = false)
    public Result<PageResponse<DetectionResultResponse>> getDetectionList(@ModelAttribute DetectionQueryRequest query) {
        Integer page = query.getPage() == null ? 1 : query.getPage();
        Integer size = query.getSize() == null ? 10 : query.getSize();
        Page<DetectionResultResponse> result = detectionService.getDetectionList(
                page,
                size,
                query.getBuildingId(),
                query.getStatus(),
                query.getRiskLevel(),
                query.getStartDate(),
                query.getEndDate()
        );
        return Result.success(PageResponse.from(result));
    }

    /**
     * 取消检测任务
     */
    @PutMapping("/{id}/cancel")
    @PreAuthorize("hasAnyRole('USER','INSPECTOR','ADMIN')")
    @Operation(summary = "取消检测", description = "取消待处理的检测任务")
    @Log(operation = "取消检测", method = "PUT /api/detections/{id}/cancel")
    public Result<Void> cancelDetection(@PathVariable Long id) {
        detectionService.cancelDetection(id);
        return Result.success("取消成功", null);
    }

    /**
     * 删除检测任务
     */
    @DeleteMapping("/{id}")
    @PreAuthorize("hasAnyRole('USER','INSPECTOR','ADMIN')")
    @Operation(summary = "删除检测任务", description = "删除指定检测任务")
    @Log(operation = "删除检测任务", method = "DELETE /api/detections/{id}", recordParams = false)
    public Result<Void> deleteDetection(@PathVariable Long id) {
        detectionService.deleteDetection(id);
        return Result.success("删除成功", null);
    }
}
