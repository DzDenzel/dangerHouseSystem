package com.dz.dangerhouse.dto.request;

import lombok.Data;

import java.math.BigDecimal;

/**
 * 建筑创建/更新请求DTO
 * 用于新增或修改建筑档案信息
 */
@Data
public class BuildingRequest {

    /**
     * 建筑名称
     */
    private String name;

    /**
     * 建筑地址
     */
    private String address;

    /**
     * 结构类型（如：砖混、框架、钢结构等）
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
     * 建筑面积（平方米）
     */
    private BigDecimal area;

    /**
     * 业主姓名
     */
    private String ownerName;

    /**
     * 业主联系电话
     */
    private String ownerPhone;

    /**
     * 经度
     */
    private BigDecimal longitude;

    /**
     * 纬度
     */
    private BigDecimal latitude;

    /**
     * 建筑描述
     */
    private String description;

    /**
     * 建筑图片路径
     */
    private String imagePath;
}