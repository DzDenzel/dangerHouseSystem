package com.dz.dangerhouse.service;

import com.dz.dangerhouse.entity.User;

import java.util.List;

/**
 * 当前登录用户服务
 */
public interface CurrentUserService {

    /**
     * 获取当前登录用户 ID
     */
    Long getCurrentUserId();

    /**
     * 获取当前登录用户完整信息
     */
    User getCurrentUser();

    /**
     * 获取当前登录用户角色编码列表
     */
    List<String> getCurrentRoleCodes();

    /**
     * 判断当前用户是否拥有指定角色
     */
    boolean hasRole(String roleCode);
}
