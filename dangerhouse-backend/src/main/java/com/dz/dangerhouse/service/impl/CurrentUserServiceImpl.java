package com.dz.dangerhouse.service.impl;

import com.dz.dangerhouse.entity.User;
import com.dz.dangerhouse.exception.BusinessException;
import com.dz.dangerhouse.mapper.UserMapper;
import com.dz.dangerhouse.service.CurrentUserService;
import com.dz.dangerhouse.service.UserService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;

import java.util.List;

/**
 * 当前登录用户服务实现
 */
@Service
public class CurrentUserServiceImpl implements CurrentUserService {

    @Autowired
    private UserService userService;

    @Autowired
    private UserMapper userMapper;

    /**
     * 获取当前用户 ID
     */
    @Override
    public Long getCurrentUserId() {
        return getCurrentUser().getId();
    }

    /**
     * 获取当前用户信息
     */
    @Override
    public User getCurrentUser() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication == null || !authentication.isAuthenticated()) {
            throw new BusinessException(401, "未授权");
        }

        String username = authentication.getName();
        if (username == null || username.isEmpty()) {
            throw new BusinessException(401, "未授权");
        }

        User user = userService.findByUsername(username);
        if (user == null) {
            throw new BusinessException(401, "用户不存在");
        }
        return user;
    }

    /**
     * 获取当前用户角色编码列表
     */
    @Override
    public List<String> getCurrentRoleCodes() {
        User currentUser = getCurrentUser();
        List<String> roleCodes = userMapper.findRoleCodesByUserId(currentUser.getId());
        if (roleCodes == null || roleCodes.isEmpty()) {
            return List.of("USER");
        }
        return roleCodes;
    }

    /**
     * 检查当前用户是否拥有指定角色
     */
    @Override
    public boolean hasRole(String roleCode) {
        return getCurrentRoleCodes().stream()
                .anyMatch(role -> roleCode.equalsIgnoreCase(role));
    }
}
