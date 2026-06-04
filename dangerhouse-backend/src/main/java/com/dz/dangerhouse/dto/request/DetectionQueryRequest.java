package com.dz.dangerhouse.dto.request;

import lombok.Data;
import lombok.EqualsAndHashCode;
import org.springframework.format.annotation.DateTimeFormat;

import java.time.LocalDate;

/**
 * 检测记录查询请求
 */
@Data
@EqualsAndHashCode(callSuper = true)
public class DetectionQueryRequest extends QueryRequest {

    /**
     * 建筑ID
     */
    private Long buildingId;

    /**
     * 检测状态
     */
    private String status;

    /**
     * 风险等级
     */
    private String riskLevel;

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
}