package com.dz.dangerhouse.entity;

import com.baomidou.mybatisplus.annotation.FieldFill;
import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * 建筑档案实体
 */
@Data
@TableName("building")
public class Building {

    /**
     * 建筑 ID
     */
    @TableId(type = IdType.AUTO)
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
     * 绑定的普通用户账号 ID，可为空
     */
    private Long ownerUserId;

    /**
     * 房屋创建人 ID
     */
    private Long createdBy;

    /**
     * 创建人角色 ID
     */
    private Long createdByRole;

    /**
     * 当前主要跟进检测员 ID，可为空
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
    @TableField(fill = FieldFill.INSERT)
    private LocalDateTime createdAt;

    /**
     * 更新时间
     */
    @TableField(fill = FieldFill.INSERT_UPDATE)
    private LocalDateTime updatedAt;

}
