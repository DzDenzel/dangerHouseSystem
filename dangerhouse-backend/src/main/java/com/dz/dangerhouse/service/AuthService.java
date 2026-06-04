package com.dz.dangerhouse.service;

import com.dz.dangerhouse.dto.request.LoginRequest;
import com.dz.dangerhouse.dto.request.RegisterRequest;
import com.dz.dangerhouse.dto.response.LoginResponse;
import com.dz.dangerhouse.dto.response.RegisterResponse;

/**
 * 认证服务接口
 */
public interface AuthService {

    /**
     * 用户登录
     */
    LoginResponse login(LoginRequest request);

    /**
     * 用户注册
     */
    RegisterResponse register(RegisterRequest request);

    /**
     * 用户退出
     */
    void logout(String authorizationHeader);

    /**
     * 检查用户名是否可用
     */
    boolean checkUsernameAvailable(String username);

    /**
     * 检查手机号是否可用
     */
    boolean checkPhoneAvailable(String phone);
}
