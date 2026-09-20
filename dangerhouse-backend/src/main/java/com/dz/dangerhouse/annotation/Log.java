package com.dz.dangerhouse.annotation;

import java.lang.annotation.*;

/**
 * 操作日志注解
 * 标注在 Controller 方法上，用于记录操作日志
 */
@Target(ElementType.METHOD)
@Retention(RetentionPolicy.RUNTIME)
@Documented
public @interface Log {

    /**
     * 操作描述，如：用户登录、新增建筑、删除检测记录
     */
    String operation() default "";

    /**
     * 接口路径（可选，默认从当前请求自动获取）
     */
    String method() default "";

    boolean recordParams() default true;

    /**
     * 默认不记录，避免响应体中的敏感信息落库
     */
    boolean recordResult() default false;

    boolean requireLogin() default true;
}