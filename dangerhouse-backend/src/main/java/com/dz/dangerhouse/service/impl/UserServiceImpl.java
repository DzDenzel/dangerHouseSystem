package com.dz.dangerhouse.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.dz.dangerhouse.cache.CacheProperties;
import com.dz.dangerhouse.cache.CacheService;
import com.dz.dangerhouse.dto.request.UserUpdateRequest;
import com.dz.dangerhouse.dto.response.UserInfoResponse;
import com.dz.dangerhouse.dto.response.UserListResponse;
import com.dz.dangerhouse.entity.Role;
import com.dz.dangerhouse.entity.User;
import com.dz.dangerhouse.entity.UserRole;
import com.dz.dangerhouse.mapper.RoleMapper;
import com.dz.dangerhouse.mapper.UserMapper;
import com.dz.dangerhouse.mapper.UserRoleMapper;
import com.dz.dangerhouse.service.CustomUserDetailsService;
import com.dz.dangerhouse.service.UserService;
import com.dz.dangerhouse.util.FileUploadUtil;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.time.LocalDateTime;
import java.util.List;
import java.util.concurrent.TimeUnit;
import java.util.regex.Pattern;

@Slf4j
@Service
public class UserServiceImpl implements UserService {

    private static final Pattern PHONE_PATTERN = Pattern.compile("^1[3-9]\\d{9}$");
    private static final Pattern EMAIL_PATTERN =
            Pattern.compile("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$");

    @Autowired
    private UserMapper userMapper;

    @Autowired
    private UserRoleMapper userRoleMapper;

    @Autowired
    private RoleMapper roleMapper;

    @Autowired
    private PasswordEncoder passwordEncoder;

    @Autowired
    private FileUploadUtil fileUploadUtil;

    @Autowired
    private CacheService cacheService;

    @Autowired
    private CacheProperties cacheProperties;

    @Autowired
    private CustomUserDetailsService customUserDetailsService;

    @Override
    public UserInfoResponse getUserById(Long id) {
        UserInfoResponse response = cacheService.queryWithMutex(
                cacheProperties.userDetailKey(id),
                UserInfoResponse.class,
                () -> loadUserInfo(id),
                cacheProperties.getDefaultTtlMinutes(),
                TimeUnit.MINUTES
        );
        if (response == null) {
            throw new IllegalArgumentException("用户不存在");
        }
        return response;
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public UserInfoResponse updateUser(Long id, UserUpdateRequest request) {
        String currentUsername = SecurityContextHolder.getContext().getAuthentication().getName();
        return updateUser(id, request, currentUsername);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public UserInfoResponse updateUser(Long id, UserUpdateRequest request, String currentUsername) {
        User user = userMapper.selectById(id);
        if (user == null) {
            throw new IllegalArgumentException("用户不存在");
        }

        String oldPhone = user.getPhone();
        String oldEmail = user.getEmail();

        User currentUser = userMapper.findByUsername(currentUsername);
        if (currentUser == null) {
            throw new IllegalArgumentException("当前用户不存在");
        }

        List<String> currentRoles = userMapper.findRoleCodesByUserId(currentUser.getId());
        boolean isAdmin = currentRoles != null && currentRoles.contains("ADMIN");
        if (!isAdmin && !user.getId().equals(currentUser.getId())) {
            throw new IllegalArgumentException("无权修改其他用户信息");
        }

        if (request.getPhone() != null) {
            String phone = request.getPhone().trim();
            if (!phone.isEmpty() && !PHONE_PATTERN.matcher(phone).matches()) {
                throw new IllegalArgumentException("手机号格式不正确");
            }
            User existingUser = phone.isEmpty() ? null : userMapper.findByPhone(phone);
            if (existingUser != null && !existingUser.getId().equals(id)) {
                throw new IllegalArgumentException("该手机号已被其他用户使用");
            }
            user.setPhone(phone.isEmpty() ? null : phone);
        }

        if (request.getEmail() != null) {
            String email = request.getEmail().trim();
            if (!email.isEmpty() && !EMAIL_PATTERN.matcher(email).matches()) {
                throw new IllegalArgumentException("邮箱格式不正确");
            }
            User existingUser = email.isEmpty() ? null : userMapper.findByEmail(email);
            if (existingUser != null && !existingUser.getId().equals(id)) {
                throw new IllegalArgumentException("该邮箱已被其他用户使用");
            }
            user.setEmail(email.isEmpty() ? null : email);
        }

        if (request.getNickname() != null) {
            String nickname = request.getNickname().trim();
            user.setNickname(nickname.isEmpty() ? null : nickname);
        }

        if (request.getAvatar() != null) {
            String avatar = request.getAvatar().trim();
            user.setAvatar(avatar.isEmpty() ? null : avatar);
        }

        if (request.getNewPassword() != null && !request.getNewPassword().trim().isEmpty()) {
            if (request.getNewPassword().length() < 6) {
                throw new IllegalArgumentException("新密码长度不能少于 6 位");
            }
            user.setPassword(passwordEncoder.encode(request.getNewPassword()));
        }

        user.setUpdatedAt(LocalDateTime.now());
        userMapper.updateById(user);
        evictUserCache(id);
        customUserDetailsService.evictAuthCache(user, oldPhone, oldEmail);

        log.info("用户信息更新成功: userId={}, operator={}", id, currentUsername);
        return convertToResponse(user);
    }

    @Override
    public User findByUsername(String username) {
        return userMapper.findByUsername(username);
    }

    @Override
    public Page<UserListResponse> getUserList(Integer page, Integer size, String username, Integer status) {
        String cacheKey = buildUserListCacheKey(page, size, username, status);
        @SuppressWarnings("unchecked")
        Page<UserListResponse> responsePage = cacheService.queryWithPassThrough(
                cacheKey,
                Page.class,
                () -> loadUserList(page, size, username, status),
                cacheProperties.getDefaultTtlMinutes(),
                TimeUnit.MINUTES
        );
        return responsePage;
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void updateUserStatus(Long userId, Integer status) {
        User user = userMapper.selectById(userId);
        if (user == null) {
            throw new IllegalArgumentException("用户不存在");
        }
        if (status == null || (status != 0 && status != 1)) {
            throw new IllegalArgumentException("用户状态参数错误");
        }

        user.setStatus(status);
        user.setUpdatedAt(LocalDateTime.now());
        userMapper.updateById(user);
        evictUserCache(userId);
        customUserDetailsService.evictAuthCache(user);

        log.info("用户状态更新成功: userId={}, status={}", userId, status);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void updatePassword(Long userId, String oldPassword, String newPassword) {
        User user = userMapper.selectById(userId);
        if (user == null) {
            throw new IllegalArgumentException("用户不存在");
        }
        if (!passwordEncoder.matches(oldPassword, user.getPassword())) {
            throw new IllegalArgumentException("原密码不正确");
        }
        if (newPassword == null || newPassword.length() < 6) {
            throw new IllegalArgumentException("新密码长度不能少于 6 位");
        }

        user.setPassword(passwordEncoder.encode(newPassword));
        user.setUpdatedAt(LocalDateTime.now());
        userMapper.updateById(user);
        evictUserCache(userId);
        customUserDetailsService.evictAuthCache(user);

        log.info("用户密码修改成功: userId={}", userId);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void updateInspectorRole(Long userId, boolean inspector) {
        User user = userMapper.selectById(userId);
        if (user == null) {
            throw new IllegalArgumentException("用户不存在");
        }

        List<String> roleCodes = userMapper.findRoleCodesByUserId(userId);
        if (roleCodes != null && roleCodes.contains("ADMIN")) {
            throw new IllegalArgumentException("管理员账号不允许调整检测员角色");
        }

        Role inspectorRole = roleMapper.findByRoleCode("INSPECTOR");
        Role userRole = roleMapper.findByRoleCode("USER");
        if (inspectorRole == null) {
            throw new IllegalStateException("检测员角色不存在，请先初始化角色数据");
        }
        if (userRole == null) {
            throw new IllegalStateException("普通用户角色不存在，请先初始化角色数据");
        }

        int inspectorRoleCount = userRoleMapper.countByUserIdAndRoleId(userId, inspectorRole.getId());
        int userRoleCount = userRoleMapper.countByUserIdAndRoleId(userId, userRole.getId());

        if (inspector) {
            if (inspectorRoleCount == 0) {
                UserRole inspectorUserRole = new UserRole();
                inspectorUserRole.setUserId(userId);
                inspectorUserRole.setRoleId(inspectorRole.getId());
                userRoleMapper.insert(inspectorUserRole);
            }
            if (userRoleCount > 0) {
                userRoleMapper.deleteByUserIdAndRoleId(userId, userRole.getId());
            }
        } else {
            if (inspectorRoleCount > 0) {
                userRoleMapper.deleteByUserIdAndRoleId(userId, inspectorRole.getId());
            }
            if (userRoleCount == 0) {
                UserRole fallbackRole = new UserRole();
                fallbackRole.setUserId(userId);
                fallbackRole.setRoleId(userRole.getId());
                userRoleMapper.insert(fallbackRole);
            }
        }

        user.setUpdatedAt(LocalDateTime.now());
        userMapper.updateById(user);
        evictUserCache(userId);
        customUserDetailsService.evictAuthCache(user);

        log.info("用户检测员角色更新成功: userId={}, inspector={}", userId, inspector);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public String uploadAvatar(Long userId, MultipartFile file) {
        User user = userMapper.selectById(userId);
        if (user == null) {
            throw new IllegalArgumentException("用户不存在");
        }

        String avatarPath = fileUploadUtil.uploadAvatar(file, userId);
        user.setAvatar(avatarPath);
        user.setUpdatedAt(LocalDateTime.now());
        userMapper.updateById(user);
        evictUserCache(userId);
        customUserDetailsService.evictAuthCache(user);

        log.info("用户头像上传成功: userId={}, path={}", userId, avatarPath);
        return fileUploadUtil.getFileUrl(avatarPath);
    }

    private UserInfoResponse loadUserInfo(Long id) {
        User user = userMapper.selectById(id);
        if (user == null) {
            return null;
        }
        return convertToResponse(user);
    }

    private Page<UserListResponse> loadUserList(Integer page, Integer size, String username, Integer status) {
        Page<User> userPage = new Page<>(page, size);
        QueryWrapper<User> wrapper = new QueryWrapper<>();
        wrapper.like(username != null && !username.trim().isEmpty(), "username", username)
                .eq(status != null, "status", status)
                .orderByDesc("created_at");

        userPage = userMapper.selectPage(userPage, wrapper);

        Page<UserListResponse> responsePage =
                new Page<>(userPage.getCurrent(), userPage.getSize(), userPage.getTotal());
        List<UserListResponse> records = userPage.getRecords().stream()
                .map(this::convertToListResponse)
                .toList();
        responsePage.setRecords(records);
        return responsePage;
    }

    private UserInfoResponse convertToResponse(User user) {
        List<String> roles = userMapper.findRoleCodesByUserId(user.getId());
        if (roles == null || roles.isEmpty()) {
            roles = List.of("USER");
        }

        return UserInfoResponse.builder()
                .id(user.getId())
                .username(user.getUsername())
                .phone(user.getPhone())
                .email(user.getEmail())
                .nickname(user.getNickname())
                .avatar(fileUploadUtil.getFileUrl(user.getAvatar()))
                .roles(roles)
                .status(user.getStatus())
                .lastLoginTime(user.getLastLoginTime())
                .lastLoginIp(user.getLastLoginIp())
                .createdAt(user.getCreatedAt())
                .updatedAt(user.getUpdatedAt())
                .build();
    }

    private UserListResponse convertToListResponse(User user) {
        List<String> roles = userMapper.findRoleCodesByUserId(user.getId());
        if (roles == null || roles.isEmpty()) {
            roles = List.of("USER");
        }

        return UserListResponse.builder()
                .id(user.getId())
                .username(user.getUsername())
                .nickname(user.getNickname())
                .email(user.getEmail())
                .phone(user.getPhone())
                .avatar(fileUploadUtil.getFileUrl(user.getAvatar()))
                .status(user.getStatus())
                .roles(roles)
                .createdAt(user.getCreatedAt())
                .build();
    }

    private void evictUserCache(Long userId) {
        cacheService.delete(cacheProperties.userDetailKey(userId));
        cacheService.deleteByPrefix(cacheProperties.getUserListPrefix());
    }

    private String buildUserListCacheKey(Integer page, Integer size, String username, Integer status) {
        return cacheProperties.getUserListPrefix()
                + safe(page) + ":"
                + safe(size) + ":"
                + safe(username) + ":"
                + safe(status);
    }

    private String safe(Object value) {
        return value == null ? "_" : String.valueOf(value).trim();
    }
}
