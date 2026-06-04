package com.dz.dangerhouse.util;

import org.springframework.stereotype.Component;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;

/**
 * 报告编号生成器
 * 生成格式：RPT + 时间戳(yyyyMMddHHmmss) + 检测ID(6位补零)
 * 示例：RPT20250405143022000123
 */
@Component
public class ReportNumberGenerator {

    private static final DateTimeFormatter DATE_FORMATTER = DateTimeFormatter.ofPattern("yyyyMMddHHmmss");

    /**
     * 生成报告编号
     *
     * @param detectionId 检测任务ID
     * @return 报告编号字符串
     */
    public String generate(Long detectionId) {
        String timestamp = LocalDateTime.now().format(DATE_FORMATTER);
        return "RPT" + timestamp + String.format("%06d", detectionId);
    }
}