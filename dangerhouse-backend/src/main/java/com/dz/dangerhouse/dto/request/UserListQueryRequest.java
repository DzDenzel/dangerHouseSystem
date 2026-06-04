package com.dz.dangerhouse.dto.request;

import lombok.Data;
import lombok.EqualsAndHashCode;

/**
 * 用户列表查询请求
 */
@Data
@EqualsAndHashCode(callSuper = true)
public class UserListQueryRequest extends QueryRequest {

    /**
     * 用户名
     */
    private String username;

    /**
     * 用户状态
     */
    private Integer status;
}
