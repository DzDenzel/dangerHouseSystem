package com.dz.dangerhouse.service;

import com.dz.dangerhouse.cache.AuthUserCacheEntry;
import com.dz.dangerhouse.cache.CacheProperties;
import com.dz.dangerhouse.cache.CacheService;
import com.dz.dangerhouse.entity.User;
import com.dz.dangerhouse.mapper.UserMapper;
import jakarta.annotation.Resource;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.concurrent.TimeUnit;
import java.util.stream.Collectors;

/**
 * 自定义用户详情服务
 * 负责加载用户信息并管理认证缓存
 */
@Slf4j
@Service
public class CustomUserDetailsService implements UserDetailsService {

    @Resource
    private UserMapper userMapper;

    @Resource
    private CacheService cacheService;

    @Resource
    private CacheProperties cacheProperties;

    /**
     * 根据账号加载用户详情（支持用户名/手机号/邮箱）
     */
    @Override
    public UserDetails loadUserByUsername(String account) throws UsernameNotFoundException {
        AuthUserCacheEntry cached = cacheService.queryWithMutex(
                cacheProperties.authUserKey(account),
                AuthUserCacheEntry.class,
                () -> loadAuthUserCache(account),
                cacheProperties.getAuthUserTtlMinutes(),
                TimeUnit.MINUTES
        );
        if (cached == null) {
            throw new UsernameNotFoundException("用户不存在：" + account);
        }

        validateCacheEntry(cached, account);
        refreshAuthCache(cached, account);
        return toUserDetails(cached);
    }

    /**
     * 从数据库加载用户认证信息
     */
    private AuthUserCacheEntry loadAuthUserCache(String account) {
        User user = findUserByAccount(account);
        if (user == null) {
            return null;
        }
        if (user.getStatus() != null && user.getStatus() == 0) {
            throw new UsernameNotFoundException("用户已禁用：" + account);
        }

        List<String> roleCodes = userMapper.findRoleCodesByUserId(user.getId());
        if (roleCodes == null || roleCodes.isEmpty()) {
            roleCodes = List.of("USER");
        }

        log.debug("加载用户详情：account={}, roles={}", account, roleCodes);
        return buildCacheEntry(user, roleCodes);
    }

    /**
     * 构建缓存对象
     */
    private AuthUserCacheEntry buildCacheEntry(User user, List<String> roleCodes) {
        AuthUserCacheEntry entry = new AuthUserCacheEntry();
        entry.setUserId(user.getId());
        entry.setUsername(user.getUsername());
        entry.setPhone(user.getPhone());
        entry.setEmail(user.getEmail());
        entry.setPassword(user.getPassword());
        entry.setStatus(user.getStatus());
        entry.setRoleCodes(roleCodes);
        return entry;
    }

    /**
     * 验证缓存条目的有效性
     */
    private void validateCacheEntry(AuthUserCacheEntry entry, String account) {
        if (entry.getStatus() != null && entry.getStatus() == 0) {
            throw new UsernameNotFoundException("用户已禁用：" + account);
        }
    }

    /**
     * 转换为Spring Security的UserDetails对象
     */
    private UserDetails toUserDetails(AuthUserCacheEntry entry) {
        List<String> roleCodes = entry.getRoleCodes();
        if (roleCodes == null || roleCodes.isEmpty()) {
            roleCodes = List.of("USER");
        }

        List<SimpleGrantedAuthority> authorities = roleCodes.stream()
                .map(roleCode -> new SimpleGrantedAuthority("ROLE_" + roleCode))
                .collect(Collectors.toList());

        return new org.springframework.security.core.userdetails.User(
                entry.getUsername(),
                entry.getPassword(),
                entry.getStatus() != null && entry.getStatus() == 1,
                true,
                true,
                true,
                authorities
        );
    }

    /**
     * 根据账号查找用户（支持用户名/手机号/邮箱）
     */
    private User findUserByAccount(String account) {
        if (account == null || account.trim().isEmpty()) {
            return null;
        }

        // 手机号格式
        if (account.matches("^1[3-9]\\d{9}$")) {
            log.debug("通过手机号查找用户：{}", account);
            return userMapper.findByPhone(account);
        }
        // 邮箱格式
        if (account.matches("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$")) {
            log.debug("通过邮箱查找用户：{}", account);
            return userMapper.findByEmail(account);
        }

        // 用户名格式
        log.debug("通过用户名查找用户：{}", account);
        return userMapper.findByUsername(account);
    }

    /**
     * 刷新认证缓存（多账号别名同步）
     */
    private void refreshAuthCache(AuthUserCacheEntry entry, String currentAccount) {
        long ttlMinutes = cacheProperties.getAuthUserTtlMinutes();
        cacheAlias(currentAccount, entry, ttlMinutes);
        cacheAlias(entry.getUsername(), entry, ttlMinutes);
        cacheAlias(entry.getPhone(), entry, ttlMinutes);
        cacheAlias(entry.getEmail(), entry, ttlMinutes);
    }

    /**
     * 缓存单个账号别名
     */
    private void cacheAlias(String account, AuthUserCacheEntry entry, long ttlMinutes) {
        if (account != null && !account.isBlank()) {
            cacheService.putWithJitter(cacheProperties.authUserKey(account), entry, ttlMinutes, TimeUnit.MINUTES);
        }
    }

    /**
     * 清除用户认证缓存
     */
    public void evictAuthCache(User user, String... extraAccounts) {
        if (user != null) {
            deleteIfPresent(user.getUsername());
            deleteIfPresent(user.getPhone());
            deleteIfPresent(user.getEmail());
        }
        if (extraAccounts != null) {
            for (String account : extraAccounts) {
                deleteIfPresent(account);
            }
        }
    }

    /**
     * 删除指定账号的缓存
     */
    private void deleteIfPresent(String account) {
        if (account != null && !account.isBlank()) {
            cacheService.delete(cacheProperties.authUserKey(account));
        }
    }
}
