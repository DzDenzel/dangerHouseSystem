package com.dz.dangerhouse.dto.request;

import lombok.Data;
import lombok.EqualsAndHashCode;
import org.springframework.format.annotation.DateTimeFormat;

import java.time.LocalDate;

/**
 * 操作日志查询请求
 */
@Data
@EqualsAndHashCode(callSuper = true)
public class OperationLogQueryRequest extends QueryRequest {

    /**
     * 操作类型
     */
    private String operation;

    /**
     * 用户名
     */
    private String username;

    /**
     * 开始日期
     */
    @DateTimeFormat(pattern = "yyyy-MM-dd")
    private LocalDate startDate;

    /**
     * 结束日期
     */
    @DateTimeFormat(pattern = "yyyy-MM-dd")
    private LocalDate endDate;

    /**
     * 操作状态（1成功 0失败）
     */
    private Integer status;
}