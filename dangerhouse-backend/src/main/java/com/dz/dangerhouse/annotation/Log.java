package com.dz.dangerhouse.annotation;

import java.lang.annotation.*;

/**
 * 操作日志注解
 * 标注在 Controller 方法上，用于记录操作日志
 *
 * 使用示例：
 * @Log(operation = "用户登录", method = "POST /api/auth/login")
 * public Result<LoginResponse> login(@RequestBody LoginRequest request) { ... }
 */
@Target(ElementType.METHOD)
@Retention(RetentionPolicy.RUNTIME)
@Documented
public @interface Log {

    /**
     * 操作描述
     * 例如：用户登录、新增建筑、删除检测记录
     */
    String operation() default "";

    /**
     * 接口路径（可选，默认自动获取）
     * 例如：POST /api/auth/login
     */
    String method() default "";

    /**
     * 是否记录请求参数
     * 默认记录
     */
    boolean recordParams() default true;

    /**
     * 是否记录响应结果
     * 默认不记录（避免敏感信息泄露）
     */
    boolean recordResult() default false;

    /**
     * 是否必须登录
     * 默认必须登录才能记录日志
     */
    boolean requireLogin() default true;
}