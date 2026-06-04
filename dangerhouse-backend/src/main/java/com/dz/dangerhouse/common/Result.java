package com.dz.dangerhouse.common;

import cn.hutool.core.util.IdUtil;
import lombok.Data;

import java.io.Serializable;
import java.util.concurrent.atomic.AtomicLong;

/**
 * 统一API响应结构
 * 包含状态码、消息、数据、时间戳和请求ID
 *
 * @param <T> 响应数据类型
 */
@Data
public class Result<T> implements Serializable {
    private static final long serialVersionUID = 1L;

    /**
     * 响应状态码（200成功，其他为错误码）
     */
    private Integer code;
    
    /**
     * 响应消息
     */
    private String message;
    
    /**
     * 响应数据
     */
    private T data;
    
    /**
     * 时间戳（秒级）
     */
    private Long timestamp;
    
    /**
     * 请求唯一标识
     */
    private String requestId;

    private static final AtomicLong SEQUENCE = new AtomicLong(0);

    public Result() {}

    public Result(Integer code, String message) {
        this.code = code;
        this.message = message;
        this.timestamp = System.currentTimeMillis() / 1000;
        this.requestId = generateRequestId();
    }

    public Result(Integer code, String message, T data) {
        this.code = code;
        this.message = message;
        this.data = data;
        this.timestamp = System.currentTimeMillis() / 1000;
        this.requestId = generateRequestId();
    }

    /**
     * 私有构造器，用于内部快速创建（不填充timestamp和requestId）
     */
    private Result(Integer code, String message, T data, boolean fast) {
        this.code = code;
        this.message = message;
        this.data = data;
    }

    /**
     * 创建成功响应（无数据）
     */
    public static <T> Result<T> success() {
        return wrap(new Result<>(200, "success", null, true));
    }

    /**
     * 创建成功响应（带数据）
     */
    public static <T> Result<T> success(T data) {
        return wrap(new Result<>(200, "success", data, true));
    }

    /**
     * 创建成功响应（带消息和数据）
     */
    public static <T> Result<T> success(String message, T data) {
        return wrap(new Result<>(200, message, data, true));
    }

    /**
     * 创建失败响应（默认500错误）
     */
    public static <T> Result<T> fail() {
        return wrap(new Result<>(500, "internal error", null, true));
    }

    /**
     * 创建失败响应（带消息）
     */
    public static <T> Result<T> fail(String message) {
        return wrap(new Result<>(500, message, null, true));
    }

    /**
     * 创建失败响应（带状态码和消息）
     */
    public static <T> Result<T> fail(Integer code, String message) {
        return wrap(new Result<>(code, message, null, true));
    }

    /**
     * 创建自定义状态码的响应结果
     */
    public static <T> Result<T> of(Integer code, String message, T data) {
        return new Result<>(code, message, data);
    }

    /**
     * 分页结果包装器
     *
     * @param <T> 记录类型
     */
    public static class PageResult<T> {
        private Long total;
        private Integer page;
        private Integer pageSize;
        private java.util.List<T> records;

        public PageResult() {}

        public PageResult(Long total, Integer page, Integer pageSize, java.util.List<T> records) {
            this.total = total;
            this.page = page;
            this.pageSize = pageSize;
            this.records = records;
        }

        // Getters and Setters
        public Long getTotal() { return total; }
        public void setTotal(Long total) { this.total = total; }
        public Integer getPage() { return page; }
        public void setPage(Integer page) { this.page = page; }
        public Integer getPageSize() { return pageSize; }
        public void setPageSize(Integer pageSize) { this.pageSize = pageSize; }
        public java.util.List<T> getRecords() { return records; }
        public void setRecords(java.util.List<T> records) { this.records = records; }
    }

    /**
     * 包装结果，填充timestamp和requestId
     */
    private static <T> Result<T> wrap(Result<T> result) {
        if (result.timestamp == null) {
            result.timestamp = System.currentTimeMillis() / 1000;
        }
        if (result.requestId == null) {
            result.requestId = generateRequestId();
        }
        return result;
    }

    /**
     * 生成唯一请求ID（UUID）
     */
    private static String generateRequestId() {
        return IdUtil.fastSimpleUUID();
    }
}
