package com.dz.dangerhouse.entity;

import com.baomidou.mybatisplus.annotation.*;
import lombok.Data;
import java.time.LocalDateTime;

/**
 * 操作日志表实体
 */
@Data
@TableName("operation_log")
public class OperationLog {

    /**
     * 日志ID
     */
    @TableId(type = IdType.AUTO)
    private Long id;

    /**
     * 操作用户ID
     */
    private Long userId;

    /**
     * 操作类型描述
     */
    private String operation;

    /**
     * 接口方法（如：POST /api/auth/login）
     */
    private String method;

    /**
     * 请求参数（JSON 格式）
     */
    private String params;

    /**
     * 响应结果（JSON 格式）
     */
    private String result;

    /**
     * 操作IP
     */
    private String ip;

    /**
     * 操作状态（1成功 0失败）
     */
    private Integer status;

    /**
     * 错误信息
     */
    private String errorMsg;

    /**
     * 创建时间
     */
    @TableField(fill = FieldFill.INSERT)
    private LocalDateTime createTime;
}