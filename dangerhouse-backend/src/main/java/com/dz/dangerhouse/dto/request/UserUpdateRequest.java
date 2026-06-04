package com.dz.dangerhouse.dto.request;

import lombok.Data;

/**
 * 用户信息更新请求DTO
 */
@Data
public class UserUpdateRequest {

    /**
     * 用户ID（路径参数）
     */
    private Long id;

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
     * 头像URL
     */
    private String avatar;

    /**
     * 新密码（可选，如果不为空则更新密码）
     */
    private String newPassword;
}