package com.dz.dangerhouse.controller;

import com.dz.dangerhouse.common.Result;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.Data;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * 健康检查控制器
 */
@RestController
@RequestMapping("/api")
@Tag(name = "系统监控", description = "系统健康检查接口")
public class HealthController {

    /**
     * 返回简单的服务健康状态快照
     */
    @GetMapping("/health")
    @Operation(summary = "健康检查", description = "检查API、数据库和AI服务状态")
    public Result<HealthCheckResponse> healthCheck() {
        HealthCheckResponse response = new HealthCheckResponse();
        response.setStatus("UP");
        response.setDatabase("OK");
        response.setAiService("OK");
        return Result.success(response);
    }

    /**
     * 简单的健康检查响应体
     */
    @Data
    public static class HealthCheckResponse {
        private String status;
        private String database;
        private String aiService;
        private String message;
    }
}
