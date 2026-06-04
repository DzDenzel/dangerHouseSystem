package com.dz.dangerhouse.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.util.List;

/**
 * 用户列表项响应
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class UserListResponse {

    /**
     * 用户ID
     */
    private Long id;

    /**
     * 用户名
     */
    private String username;

    /**
     * 昵称
     */
    private String nickname;

    /**
     * 邮箱
     */
    private String email;

    /**
     * 手机号
     */
    private String phone;

    /**
     * 头像URL
     */
    private String avatar;

    /**
     * 用户状态
     */
    private Integer status;

    /**
     * 角色列表
     */
    private List<String> roles;

    /**
     * 创建时间
     */
    private LocalDateTime createdAt;
}