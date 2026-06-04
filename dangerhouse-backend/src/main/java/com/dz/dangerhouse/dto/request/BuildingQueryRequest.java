package com.dz.dangerhouse.dto.request;

import lombok.Data;
import lombok.EqualsAndHashCode;

/**
 * 建筑列表查询请求
 */
@Data
@EqualsAndHashCode(callSuper = true)
public class BuildingQueryRequest extends QueryRequest {

    /**
     * 建筑名称
     */
    private String name;

    /**
     * 建筑地址
     */
    private String address;

    /**
     * 结构类型
     */
    private String structureType;

    /**
     * 风险等级（逗号分隔，如 A,B,C）
     */
    private String riskLevels;

    /**
     * 兼容另一种常用页码参数
     */
    private Integer pageNo;
}