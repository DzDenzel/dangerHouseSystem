package com.dz.dangerhouse.dto.request;

import lombok.Data;

/**
 * 用户信息更新请求DTO
 */
@Data
public class UserUpdateRequest {

    /**
     * 追加在请求体里的用户ID，服务端不使用（实际以路径参数或当前登录用户为准）
     */
    private Long id;

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