package com.dz.dangerhouse.service.impl;

import com.dz.dangerhouse.cache.CacheProperties;
import com.dz.dangerhouse.cache.CacheService;
import com.dz.dangerhouse.dto.request.LoginRequest;
import com.dz.dangerhouse.dto.request.RegisterRequest;
import com.dz.dangerhouse.dto.response.LoginResponse;
import com.dz.dangerhouse.dto.response.RegisterResponse;
import com.dz.dangerhouse.entity.Role;
import com.dz.dangerhouse.entity.User;
import com.dz.dangerhouse.entity.UserRole;
import com.dz.dangerhouse.exception.BusinessException;
import com.dz.dangerhouse.mapper.RoleMapper;
import com.dz.dangerhouse.mapper.UserMapper;
import com.dz.dangerhouse.mapper.UserRoleMapper;
import com.dz.dangerhouse.service.AuthService;
import com.dz.dangerhouse.service.CustomUserDetailsService;
import com.dz.dangerhouse.util.FileUploadUtil;
import com.dz.dangerhouse.util.JwtUtil;
import com.dz.dangerhouse.util.ServletUtils;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Lazy;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.AuthenticationException;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.TimeUnit;
import java.util.regex.Pattern;

/**
 * 认证服务实现类
 */
@Slf4j
@Service
public class AuthServiceImpl implements AuthService {
    private static final Pattern USERNAME_PATTERN = Pattern.compile("^[A-Za-z][A-Za-z0-9_]{3,19}$");
    private static final Pattern MOBILE_PHONE_PATTERN = Pattern.compile("^1[3-9]\\d{9}$");
    private static final Pattern EMAIL_PATTERN =
            Pattern.compile("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$");
    private static final String CLIENT_TYPE_APP = "APP";
    private static final String CLIENT_TYPE_WEB = "WEB";

    @Autowired
    private CustomUserDetailsService userDetailsService;

    @Autowired
    private JwtUtil jwtUtil;

    @Autowired
    @Lazy
    private AuthenticationManager authenticationManager;

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

    /**
     * 用户登录
     */
    @Override
    public LoginResponse login(LoginRequest request) {
        String account = normalizeAccount(request.getAccount());
        String password = request.getPassword() == null ? "" : request.getPassword().trim();
        String clientType = normalizeClientType(request.getClientType());
        if (account == null || account.isEmpty()) {
            throw new BusinessException(400, "请输入登录账号");
        }
        if (password.isEmpty()) {
            throw new BusinessException(400, "请输入登录密码");
        }
        if (clientType == null) {
            throw new BusinessException(400, "请明确当前登录端类型");
        }

        User user = findUserByAccount(account);
        if (user == null) {
            throw new BusinessException(404, "该账号未注册，请先注册普通用户账号或联系管理员创建账号");
        }
        if (user.getStatus() != null && user.getStatus() == 0) {
            throw new BusinessException(403, "该账号已被禁用，请联系管理员");
        }

        try {
            Authentication authentication = authenticationManager.authenticate(
                    new UsernamePasswordAuthenticationToken(user.getUsername(), password)
            );

            User authenticatedUser = userMapper.findByUsername(authentication.getName());
            if (authenticatedUser == null) {
                throw new BusinessException(404, "账号状态异常，请联系管理员");
            }

            List<String> roleCodes = userMapper.findRoleCodesByUserId(authenticatedUser.getId());
            if (roleCodes == null || roleCodes.isEmpty()) {
                roleCodes = List.of("USER");
            }
            validateClientAccess(clientType, roleCodes);

            Map<String, Object> claims = new HashMap<>();
            claims.put("userId", authenticatedUser.getId());
            claims.put("username", authenticatedUser.getUsername());
            claims.put("roles", roleCodes);

            boolean rememberMe = Boolean.TRUE.equals(request.getRememberMe());
            String token = rememberMe
                    ? jwtUtil.generateRememberToken(claims)
                    : jwtUtil.generateToken(claims);

            userMapper.updateLastLoginInfo(
                    authenticatedUser.getId(),
                    LocalDateTime.now(),
                    ServletUtils.getClientIp()
            );

            log.info(
                    "登录成功: userId={}, username={}, roles={}, rememberMe={}",
                    authenticatedUser.getId(),
                    authenticatedUser.getUsername(),
                    roleCodes,
                    rememberMe
            );

            return LoginResponse.builder()
                    .id(authenticatedUser.getId())
                    .token(token)
                    .roles(roleCodes)
                    .username(authenticatedUser.getUsername())
                    .phone(authenticatedUser.getPhone())
                    .email(authenticatedUser.getEmail())
                    .nickname(authenticatedUser.getNickname())
                    .avatar(fileUploadUtil.getFileUrl(authenticatedUser.getAvatar()))
                    .lastLoginTime(authenticatedUser.getLastLoginTime())
                    .createdAt(authenticatedUser.getCreatedAt())
                    .updatedAt(authenticatedUser.getUpdatedAt())
                    .status(authenticatedUser.getStatus())
                    .build();
        } catch (BadCredentialsException e) {
            log.warn("登录失败: account={}, reason=password_mismatch", account);
            throw new BusinessException(401, "密码错误，请重新输入");
        } catch (AuthenticationException e) {
            log.warn("登录认证失败: account={}, reason={}", account, e.getMessage());
            throw new BusinessException(401, "登录认证失败，请稍后重试");
        }
    }

    /**
     * 用户注册
     */
    @Override
    @Transactional(rollbackFor = Exception.class)
    public RegisterResponse register(RegisterRequest request) {
        validateRegisterRequest(request);

        String username = request.getUsername().trim();
        String phone = request.getPhone().trim();

        if (userMapper.existsUserByUsername(username) > 0) {
            throw new IllegalArgumentException("该用户名已被使用，请更换后重试");
        }
        if (userMapper.existsUserByPhone(phone) > 0) {
            throw new IllegalArgumentException("该手机号已经注册过账户，请直接登录");
        }

        User user = new User();
        user.setUsername(username);
        user.setPassword(passwordEncoder.encode(request.getPassword().trim()));
        user.setPhone(phone);
        user.setStatus(1);
        user.setCreatedAt(LocalDateTime.now());
        user.setUpdatedAt(LocalDateTime.now());

        userMapper.insert(user);
        cacheService.delete(cacheProperties.getDashboardKey());
        userDetailsService.evictAuthCache(user);

        String roleCode = "USER";
        assignRoleToUser(user.getId(), roleCode);
        userDetailsService.evictAuthCache(user);

        RegisterResponse response = new RegisterResponse();
        response.setId(user.getId());
        response.setUsername(user.getUsername());
        response.setPhone(user.getPhone());
        response.setRole(roleCode);
        response.setMessage("注册成功");
        response.setCreateTime(user.getCreatedAt());

        log.info("注册成功: userId={}, username={}, role={}", user.getId(), user.getUsername(), roleCode);
        return response;
    }

    /**
     * 退出登录
     */
    @Override
    public void logout(String authorizationHeader) {
        String token = extractBearerToken(authorizationHeader);
        if (token == null) {
            throw new IllegalArgumentException("缺少有效的 Authorization 令牌");
        }

        long remainingSeconds = jwtUtil.getRemainingValiditySeconds(token);
        if (remainingSeconds > 0) {
            String blacklistKey = cacheProperties.tokenBlacklistKey(jwtUtil.hashToken(token));
            cacheService.put(blacklistKey, Boolean.TRUE, remainingSeconds, TimeUnit.SECONDS);
        }

        log.info("退出登录成功，token 已加入黑名单");
    }

    /**
     * 分配角色给用户
     */
    private void assignRoleToUser(Long userId, String roleCode) {
        Role role = roleMapper.findByRoleCode(roleCode);
        Long roleId = role != null ? role.getId() : null;

        if (roleId == null) {
            log.warn("角色 {} 不存在，回退到 USER", roleCode);
            Role defaultRole = roleMapper.findByRoleCode("USER");
            roleId = defaultRole != null ? defaultRole.getId() : null;
            if (roleId == null) {
                throw new RuntimeException("默认角色 USER 不存在");
            }
        }

        UserRole userRole = new UserRole();
        userRole.setUserId(userId);
        userRole.setRoleId(roleId);
        userRole.setCreatedAt(LocalDateTime.now());
        userRoleMapper.insert(userRole);

        log.debug("分配角色: userId={}, role={}", userId, roleCode);
    }

    /**
     * 检查用户名是否可用
     */
    @Override
    public boolean checkUsernameAvailable(String username) {
        if (username == null || username.isBlank()) {
            return false;
        }
        String normalizedUsername = username.trim();
        if (!USERNAME_PATTERN.matcher(normalizedUsername).matches()) {
            return false;
        }
        return userMapper.existsUserByUsername(normalizedUsername) == 0;
    }

    /**
     * 检查手机号是否可用
     */
    @Override
    public boolean checkPhoneAvailable(String phone) {
        if (phone == null || phone.isBlank()) {
            return false;
        }
        String normalizedPhone = phone.trim();
        if (!MOBILE_PHONE_PATTERN.matcher(normalizedPhone).matches()) {
            return false;
        }
        return userMapper.existsUserByPhone(normalizedPhone) == 0;
    }

    /**
     * 提取 Bearer Token
     */
    private String extractBearerToken(String authorizationHeader) {
        if (authorizationHeader == null || authorizationHeader.isBlank()) {
            return null;
        }
        if (!authorizationHeader.startsWith("Bearer ")) {
            return null;
        }
        String token = authorizationHeader.substring(7).trim();
        return token.isEmpty() ? null : token;
    }

    /**
     * 验证注册请求参数
     */
    private void validateRegisterRequest(RegisterRequest request) {
        if (request.getUsername() == null || request.getUsername().isBlank()) {
            throw new IllegalArgumentException("用户名为必填项");
        }
        if (!USERNAME_PATTERN.matcher(request.getUsername().trim()).matches()) {
            throw new IllegalArgumentException("用户名需以字母开头，只能包含字母、数字、下划线，长度为 4-20 位");
        }
        if (request.getPhone() == null || request.getPhone().isBlank()) {
            throw new IllegalArgumentException("手机号为必填项");
        }
        if (!MOBILE_PHONE_PATTERN.matcher(request.getPhone().trim()).matches()) {
            throw new IllegalArgumentException("请输入正确的 11 位手机号");
        }
        if (request.getPassword() == null || request.getPassword().isBlank()) {
            throw new IllegalArgumentException("密码为必填项");
        }
        if (request.getPassword().trim().length() < 6) {
            throw new IllegalArgumentException("密码长度不能少于 6 位");
        }
    }

    /**
     * 标准化账号
     */
    private String normalizeAccount(String account) {
        return account == null ? null : account.trim();
    }

    /**
     * 根据账号查找用户
     */
    private User findUserByAccount(String account) {
        if (account == null || account.isBlank()) {
            return null;
        }
        if (MOBILE_PHONE_PATTERN.matcher(account).matches()) {
            return userMapper.findByPhone(account);
        }
        if (EMAIL_PATTERN.matcher(account).matches()) {
            return userMapper.findByEmail(account);
        }
        return userMapper.findByUsername(account);
    }

    /**
     * 标准化客户端类型
     */
    private String normalizeClientType(String clientType) {
        if (clientType == null || clientType.isBlank()) {
            return null;
        }
        return clientType.trim().toUpperCase();
    }

    /**
     * 验证客户端访问权限
     */
    private void validateClientAccess(String clientType, List<String> roleCodes) {
        boolean isAdmin = roleCodes.stream().anyMatch(role -> "ADMIN".equalsIgnoreCase(role));

        if (CLIENT_TYPE_APP.equals(clientType) && isAdmin) {
            throw new BusinessException(403, "管理员账号仅允许登录 Web 后台，不允许登录 App");
        }

        if (CLIENT_TYPE_WEB.equals(clientType) && !isAdmin) {
            throw new BusinessException(403, "当前账号无权登录 Web 后台，请使用管理员账号");
        }

        if (!CLIENT_TYPE_APP.equals(clientType) && !CLIENT_TYPE_WEB.equals(clientType)) {
            throw new BusinessException(400, "不支持的登录端类型");
        }
    }
}
