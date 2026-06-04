package com.dz.dangerhouse.controller;

import com.dz.dangerhouse.client.AiDetectionClient;
import com.dz.dangerhouse.common.Result;
import com.dz.dangerhouse.dto.response.AiDetectionResponse;
import com.dz.dangerhouse.exception.BusinessException;
import com.dz.dangerhouse.util.FileUploadUtil;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

import java.io.File;
import java.util.ArrayList;
import java.util.List;

/**
 * AI 检测控制器
 */
@Slf4j
@RestController
@RequestMapping("/api/ai")
@Tag(name = "AI服务", description = "独立AI检测接口")
public class AiController {

    @Autowired
    private AiDetectionClient aiDetectionClient;

    @Autowired
    private FileUploadUtil fileUploadUtil;

    /**
     * 运行 AI 检测
     */
    @PostMapping("/detect")
    @PreAuthorize("hasAnyRole('USER','INSPECTOR','ADMIN')")
    @Operation(summary = "运行AI检测", description = "上传图片并直接运行AI分析")
    public Result<AiDetectionResponse> detect(@RequestParam("images") List<MultipartFile> images) {
        log.info("独立AI检测请求, 图片数量={}", images.size());

        List<File> files = new ArrayList<>();
        try {
            for (MultipartFile image : images) {
                if (image != null && !image.isEmpty()) {
                    files.add(fileUploadUtil.saveTempFile(image));
                }
            }

            if (files.isEmpty()) {
                throw new BusinessException(400, "请至少上传一张有效图片");
            }

            return Result.success(aiDetectionClient.detectDamage(files));
        } finally {
            fileUploadUtil.deleteTempFiles(files);
        }
    }
}
