package com.dz.dangerhouse.cache;

import lombok.Data;

import java.io.Serial;
import java.io.Serializable;
import java.util.List;

/**
 * 认证用户缓存实体
 */
@Data
public class AuthUserCacheEntry implements Serializable {

    @Serial
    private static final long serialVersionUID = 572547735743511287L;
    private Long userId;
    private String username;
    private String phone;
    private String email;
    private String password;
    private Integer status;
    private List<String> roleCodes;
}
