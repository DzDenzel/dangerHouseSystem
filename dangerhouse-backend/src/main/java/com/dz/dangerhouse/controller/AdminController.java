package com.dz.dangerhouse.controller;

import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.dz.dangerhouse.annotation.Log;
import com.dz.dangerhouse.common.Result;
import com.dz.dangerhouse.dto.request.OperationLogQueryRequest;
import com.dz.dangerhouse.dto.response.AdminDashboardResponse;
import com.dz.dangerhouse.dto.response.AiModelResponse;
import com.dz.dangerhouse.dto.response.OperationLogResponse;
import com.dz.dangerhouse.dto.response.PageResponse;
import com.dz.dangerhouse.entity.OperationLog;
import com.dz.dangerhouse.service.AdminDashboardService;
import com.dz.dangerhouse.service.OperationLogService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.ModelAttribute;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.stream.Collectors;

/**
 * 管理员控制器
 */
@Slf4j
@RestController
@RequestMapping("/api/admin")
@PreAuthorize("hasRole('ADMIN')")
@Tag(name = "管理员", description = "管理员后台接口")
public class AdminController {

    @Autowired
    private OperationLogService operationLogService;

    @Autowired
    private AdminDashboardService adminDashboardService;

    /**
     * 获取仪表盘统计数据
     */
    @GetMapping("/dashboard")
    @Operation(summary = "仪表盘", description = "获取管理员仪表盘统计数据")
    @Log(operation = "仪表盘", method = "GET /api/admin/dashboard", recordParams = false)
    public Result<AdminDashboardResponse> dashboard() {
        return Result.success(adminDashboardService.getDashboard());
    }

    /**
     * 获取操作日志列表
     */
    @GetMapping("/operation-logs")
    @Operation(summary = "操作日志", description = "获取操作日志列表")
    @Log(operation = "操作日志", method = "GET /api/admin/operation-logs", recordParams = false)
    public Result<PageResponse<OperationLogResponse>> getOperationLogs(@ModelAttribute OperationLogQueryRequest query) {
        Integer page = query.getPage() == null ? 1 : query.getPage();
        Integer size = query.getSize() == null ? 10 : query.getSize();
        Page<OperationLog> result = operationLogService.getOperationLogs(
                page,
                size,
                query.getOperation(),
                query.getUsername(),
                query.getStartDate(),
                query.getEndDate(),
                query.getStatus());

        List<OperationLogResponse> records = result.getRecords().stream()
                .map(this::toOperationLogResponse)
                .collect(Collectors.toList());

        PageResponse<OperationLogResponse> response = PageResponse.<OperationLogResponse>builder()
                .records(records)
                .total(result.getTotal())
                .current(result.getCurrent())
                .size(result.getSize())
                .pages(result.getPages())
                .build();
        return Result.success(response);
    }

    /**
     * 获取 AI 模型列表
     */
    @GetMapping("/models")
    @Operation(summary = "AI 模型", description = "获取 AI 模型列表")
    @Log(operation = "AI 模型", method = "GET /api/admin/models", recordParams = false)
    public Result<List<AiModelResponse>> getModelList() {
        return Result.success(adminDashboardService.getModelList());
    }

    private OperationLogResponse toOperationLogResponse(OperationLog log) {
        if (log == null) {
            return null;
        }
        return OperationLogResponse.builder()
                .id(log.getId())
                .userId(log.getUserId())
                .operation(log.getOperation())
                .method(log.getMethod())
                .params(log.getParams())
                .result(log.getResult())
                .ip(log.getIp())
                .status(log.getStatus())
                .errorMsg(log.getErrorMsg())
                .createTime(log.getCreateTime())
                .build();
    }
}
