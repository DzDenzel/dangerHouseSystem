package com.dz.dangerhouse.dto.response;

import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;
import lombok.Builder;

import java.time.LocalDateTime;
import java.util.List;

/**
 * 用户登录响应 DTO
 * 返回用户登录成功后的信息（包含用户ID，可用于后续修改用户信息）
 * 支持多角色返回
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class LoginResponse {

    /**
     * 用户 ID（重要：用于后续获取/更新用户信息）
     */
    private Long id;

    /**
     * JWT Token
     */
    private String token;

    /**
     * 用户角色列表（支持多角色）
     */
    private List<String> roles;

    /**
     * 用户名
     */
    private String username;

    /**
     * 手机号
     */
    private String phone;

    /**
     * 邮箱
     */
    private String email;

    /**
     * 昵称
     */
    private String nickname;

    /**
     * 头像 URL
     */
    private String avatar;

    /**
     * 最后登录时间
     */
    private LocalDateTime lastLoginTime;

    /**
     * 创建时间
     */
    private LocalDateTime createdAt;

    /**
     * 更新时间
     */
    private LocalDateTime updatedAt;

    /**
     * 用户状态(1-正常，0-禁用)
     */
    private Integer status;

    /**
     * 判断是否为管理员（基于多角色）
     */
    public boolean isAdmin() {
        return roles != null && roles.stream()
                .anyMatch(role -> "ADMIN".equals(role) || "ROLE_ADMIN".equals(role));
    }

    /**
     * 判断是否拥有某个角色
     */
    public boolean hasRole(String roleCode) {
        return roles != null && roles.stream()
                .anyMatch(role -> roleCode.equalsIgnoreCase(role) ||
                        ("ROLE_" + roleCode).equalsIgnoreCase(role));
    }
}