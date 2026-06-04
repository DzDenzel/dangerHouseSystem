package com.dz.dangerhouse.controller;

import com.dz.dangerhouse.annotation.Log;
import com.dz.dangerhouse.common.Result;
import com.dz.dangerhouse.dto.request.GenerateReportRequest;
import com.dz.dangerhouse.dto.response.GenerateReportResponse;
import com.dz.dangerhouse.dto.response.ReportResponse;
import com.dz.dangerhouse.entity.Report;
import com.dz.dangerhouse.exception.BusinessException;
import com.dz.dangerhouse.service.ReportService;
import com.dz.dangerhouse.util.FileUploadUtil;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.servlet.http.HttpServletResponse;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.io.OutputStream;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;

/**
 * 报告管理控制器
 */
@Slf4j
@RestController
@RequestMapping("/api/reports")
@Tag(name = "报告管理", description = "检测报告相关接口")
public class ReportController {

    @Autowired
    private ReportService reportService;

    @Autowired
    private FileUploadUtil fileUploadUtil;

    /**
     * 生成正式检测报告文件
     */
    @PostMapping("/generate")
    @PreAuthorize("hasAnyRole('USER','INSPECTOR','ADMIN')")
    @Operation(summary = "生成报告", description = "生成正式检测报告文件")
    @Log(operation = "生成报告", method = "POST /api/reports/generate")
    public Result<GenerateReportResponse> generateReport(
            @Parameter(description = "报告生成请求", required = true) @RequestBody GenerateReportRequest request) {
        GenerateReportResponse response = reportService.generateReport(request.getDetectionId(), request.getFormat());
        return Result.success("报告生成成功", response);
    }

    /**
     * 根据 ID 获取报告详情
     */
    @GetMapping("/{id}")
    @PreAuthorize("hasAnyRole('USER','INSPECTOR','ADMIN')")
    @Operation(summary = "获取报告", description = "根据ID获取报告详情")
    @Log(operation = "获取报告", method = "GET /api/reports/{id}", recordParams = false)
    public Result<ReportResponse> getReportById(@PathVariable Long id) {
        ReportResponse report = reportService.getReportById(id);
        return Result.success(report);
    }

    /**
     * 下载报告文件
     */
    @GetMapping("/{id}/download")
    @PreAuthorize("hasAnyRole('USER','INSPECTOR','ADMIN')")
    @Operation(summary = "下载报告", description = "下载生成的报告文件")
    @Log(operation = "下载报告", method = "GET /api/reports/{id}/download", recordParams = false)
    public void downloadReport(@PathVariable Long id, HttpServletResponse response) {
        try {
            Report report = reportService.getReportEntity(id);
            byte[] fileBytes = fileUploadUtil.downloadBytes(report.getFilePath());
            if (fileBytes == null || fileBytes.length == 0) {
                log.warn("报告文件不存在或为空: {}", report.getFilePath());
                writeErrorResponse(response, HttpServletResponse.SC_NOT_FOUND, "报告文件不存在");
                return;
            }

            response.setContentType(MediaType.APPLICATION_PDF_VALUE);
            String fileName = report.getReportNo() + ".pdf";
            String encodedFileName = URLEncoder.encode(fileName, StandardCharsets.UTF_8).replaceAll("\\+", "%20");
            response.setHeader(
                    HttpHeaders.CONTENT_DISPOSITION,
                    "attachment; filename=\"" + fileName + "\"; filename*=UTF-8''" + encodedFileName);
            response.setHeader(HttpHeaders.CONTENT_LENGTH, String.valueOf(fileBytes.length));

            try (OutputStream os = response.getOutputStream()) {
                os.write(fileBytes);
                os.flush();
            }

            log.info("报告下载完成: reportId={}, reportNo={}", report.getId(), report.getReportNo());
        } catch (BusinessException e) {
            writeErrorResponse(response, e.getCode(), e.getMessage());
        } catch (Exception e) {
            log.error("报告下载失败", e);
            writeErrorResponse(response, HttpServletResponse.SC_INTERNAL_SERVER_ERROR, "下载失败: " + e.getMessage());
        }
    }

    /**
     * 写入错误响应
     */
    private void writeErrorResponse(HttpServletResponse response, int status, String message) {
        try {
            response.setStatus(status);
            response.setContentType(MediaType.APPLICATION_JSON_VALUE);
            response.getWriter().write("{\"code\":" + status + ",\"message\":\"" + message + "\"}");
        } catch (Exception ex) {
            log.error("写入错误响应失败", ex);
        }
    }
}
