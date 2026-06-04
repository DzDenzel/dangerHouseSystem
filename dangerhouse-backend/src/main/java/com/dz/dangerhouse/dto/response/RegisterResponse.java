package com.dz.dangerhouse.dto.response;

import lombok.Data;
import java.time.LocalDateTime;

/**
 * 用户注册响应
 */
@Data
public class RegisterResponse {
    
    /**
     * 用户ID
     */
    private Long id;
    
    /**
     * 用户名
     */
    private String username;
    
    /**
     * 手机号
     */
    private String phone;
    
    /**
     * 角色
     */
    private String role;
    
    /**
     * 提示信息
     */
    private String message;
    
    /**
     * 创建时间
     */
    private LocalDateTime createTime;
}
