package com.dz.dangerhouse.util;

import org.springframework.stereotype.Component;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;

/**
 * 报告编号生成器
 * 格式：RPT + 时间戳(yyyyMMddHHmmss) + 检测ID(6位补零)，如 RPT20250405143022000123
 */
@Component
public class ReportNumberGenerator {

    private static final DateTimeFormatter DATE_FORMATTER = DateTimeFormatter.ofPattern("yyyyMMddHHmmss");

    public String generate(Long detectionId) {
        String timestamp = LocalDateTime.now().format(DATE_FORMATTER);
        return "RPT" + timestamp + String.format("%06d", detectionId);
    }
}