package com.dz.dangerhouse.dto.request;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

/**
 * 用户登录请求
 */
@Data
public class LoginRequest {

    /**
     * 账号（用户名、手机号或邮箱）
     */
    @NotBlank(message = "账号为必填项")
    private String account;

    /**
     * 密码
     */
    @NotBlank(message = "密码为必填项")
    private String password;

    /**
     * 是否记住我
     */
    private Boolean rememberMe;

    /**
     * 登录端类型
     */
    @NotBlank(message = "登录端类型为必填项")
    private String clientType;
}
