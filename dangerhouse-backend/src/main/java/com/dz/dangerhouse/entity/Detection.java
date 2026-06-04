package com.dz.dangerhouse.entity;

import com.baomidou.mybatisplus.annotation.*;
import lombok.Data;
import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * AI检测记录表实体
 */
@Data
@TableName(value = "detection", autoResultMap = true)
public class Detection {

    /**
     * 检测记录ID
     */
    @TableId(type = IdType.AUTO)
    private Long id;

    /**
     * 建筑ID
     */
    private Long buildingId;

    /**
     * 检测人用户ID
     */
    private Long userId;

    /**
     * 检测状态：CREATED-已创建，PROCESSING-检测中，COMPLETED-已完成，FAILED-失败，CANCELLED-已取消
     */
    private String status;

    /**
     * 裂缝数量
     */
    private Integer crackCount;

    /**
     * 损伤比例
     */
    private BigDecimal damageRatio;

    /**
     * 风险等级
     */
    private String riskLevel;

    /**
     * 检测置信度
     */
    private BigDecimal confidence;

    /**
     * 检测结果JSON
     */
    private String detectResult;

    /**
     * 检测时间
     */
    private LocalDateTime detectTime;

    /**
     * 描述信息
     */
    private String description;

    /**
     * 错误信息（检测失败时）
     */
    private String errorMessage;

    /**
     * 创建时间
     */
    @TableField(fill = FieldFill.INSERT)
    private LocalDateTime createdAt;

    /**
     * 更新时间
     */
    @TableField(fill = FieldFill.UPDATE)
    private LocalDateTime updatedAt;

}
