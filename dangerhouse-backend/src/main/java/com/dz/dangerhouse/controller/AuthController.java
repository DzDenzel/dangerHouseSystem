package com.dz.dangerhouse.controller;

import com.dz.dangerhouse.annotation.Log;
import com.dz.dangerhouse.common.Result;
import com.dz.dangerhouse.dto.request.LoginRequest;
import com.dz.dangerhouse.dto.request.RegisterRequest;
import com.dz.dangerhouse.dto.response.LoginResponse;
import com.dz.dangerhouse.dto.response.RegisterResponse;
import com.dz.dangerhouse.service.AuthService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * 认证授权控制器
 */
@RestController
@RequestMapping("/api/auth")
@Tag(name = "认证授权", description = "用户登录注册相关接口")
public class AuthController {

    @Autowired
    private AuthService authService;

    /**
     * 用户登录
     */
    @PostMapping("/login")
    @Operation(summary = "用户登录", description = "支持用户名、手机号或邮箱登录")
    @Log(operation = "用户登录", method = "POST /api/auth/login", requireLogin = false)
    public Result<LoginResponse> login(@Valid @RequestBody LoginRequest request) {
        return Result.success(authService.login(request));
    }

    /**
     * 用户注册
     */
    @PostMapping("/register")
    @Operation(summary = "用户注册", description = "新用户注册")
    @Log(operation = "用户注册", method = "POST /api/auth/register", requireLogin = false)
    public Result<RegisterResponse> register(@Valid @RequestBody RegisterRequest request) {
        return Result.success("注册成功", authService.register(request));
    }

    /**
     * 退出登录
     */
    @PostMapping("/logout")
    @Operation(summary = "用户退出登录", description = "将当前 token 加入黑名单并立即失效")
    @Log(operation = "用户退出登录", method = "POST /api/auth/logout")
    public Result<Void> logout(HttpServletRequest request) {
        authService.logout(request.getHeader("Authorization"));
        return Result.success("退出登录成功", null);
    }

    /**
     * 检查用户名是否可用
     */
    @GetMapping("/check-username/{username}")
    @Operation(summary = "检查用户名", description = "检查用户名是否已被使用")
    @Log(
            operation = "检查用户名",
            method = "GET /api/auth/check-username/{username}",
            requireLogin = false,
            recordParams = false
    )
    public Result<Boolean> checkUsername(@PathVariable String username) {
        return Result.success(authService.checkUsernameAvailable(username));
    }

    /**
     * 检查手机号是否可用
     */
    @GetMapping("/check-phone/{phone}")
    @Operation(summary = "检查手机号", description = "检查手机号是否已被使用")
    @Log(
            operation = "检查手机号",
            method = "GET /api/auth/check-phone/{phone}",
            requireLogin = false,
            recordParams = false
    )
    public Result<Boolean> checkPhone(@PathVariable String phone) {
        return Result.success(authService.checkPhoneAvailable(phone));
    }
}
