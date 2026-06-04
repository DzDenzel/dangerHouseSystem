package com.dz.dangerhouse.dto.request;

import lombok.Data;

/**
 * 用户注册请求
 */
@Data
public class RegisterRequest {

    /**
     * 用户名
     */
    private String username;

    /**
     * 密码
     */
    private String password;

    /**
     * 手机号
     */
    private String phone;

    /**
     * 角色（默认 USER）
     */
    private String role = "USER";
}
