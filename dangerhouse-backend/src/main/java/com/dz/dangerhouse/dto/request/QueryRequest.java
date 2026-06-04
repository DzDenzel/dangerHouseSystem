package com.dz.dangerhouse.dto.request;

import lombok.Data;

/**
 * 查询条件基础 DTO
 */
@Data
public class QueryRequest {

    /**
     * 页码
     */
    private Integer page;

    /**
     * 每页数量
     */
    private Integer size;
}