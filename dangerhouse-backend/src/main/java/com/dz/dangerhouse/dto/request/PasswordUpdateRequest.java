package com.dz.dangerhouse.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Data;

/**
 * 密码更新请求
 */
@Data
public class PasswordUpdateRequest {

    /**
     * 原密码
     */
    @NotBlank(message = "原密码为必填项")
    private String oldPassword;

    /**
     * 新密码
     */
    @NotBlank(message = "新密码为必填项")
    @Size(min = 6, max = 32, message = "新密码长度需在 6-32 位之间")
    private String newPassword;
}
