package com.dz.dangerhouse.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * 建筑档案响应
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class BuildingResponse {

    /**
     * 建筑 ID
     */
    private Long id;

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
     * 建造年份
     */
    private Integer buildYear;

    /**
     * 楼层数
     */
    private Integer floorCount;

    /**
     * 建筑面积
     */
    private BigDecimal area;

    /**
     * 业主姓名
     */
    private String ownerName;

    /**
     * 业主电话
     */
    private String ownerPhone;

    /**
     * 业主用户 ID
     */
    private Long ownerUserId;

    /**
     * 创建人 ID
     */
    private Long createdBy;

    /**
     * 创建人角色 ID
     */
    private Long createdByRole;

    /**
     * 创建人角色名称
     */
    private String createdByRoleName;

    /**
     * 指派检测员 ID
     */
    private Long assignedInspectorId;

    /**
     * 经度
     */
    private BigDecimal longitude;

    /**
     * 纬度
     */
    private BigDecimal latitude;

    /**
     * 描述
     */
    private String description;

    /**
     * 图片路径
     */
    private String imagePath;

    /**
     * 创建时间
     */
    private LocalDateTime createdAt;

    /**
     * 更新时间
     */
    private LocalDateTime updatedAt;
}
