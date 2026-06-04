package com.dz.dangerhouse.cache;

import lombok.Data;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

/**
 * 缓存配置属性类
 */
@Data
@Component
@ConfigurationProperties(prefix = "app.cache")
public class CacheProperties {

    /**
     * 默认TTL（分钟）
     */
    private long defaultTtlMinutes = 10L;
    
    /**
     * 仪表盘TTL（分钟）
     */
    private long dashboardTtlMinutes = 5L;
    
    /**
     * 认证用户TTL（分钟）
     */
    private long authUserTtlMinutes = 60L;
    
    /**
     * 空值TTL（秒）
     */
    private long nullValueTtlSeconds = 120L;
    
    /**
     * 分布式锁TTL（秒）
     */
    private long mutexLockTtlSeconds = 10L;
    
    /**
     * 锁重试延迟（毫秒）
     */
    private long mutexRetryDelayMillis = 50L;
    
    /**
     * 锁最大重试次数
     */
    private int mutexMaxRetries = 20;
    
    /**
     * TTL抖动时间（秒）
     */
    private long ttlJitterSeconds = 300L;
    
    /**
     * 仪表盘缓存键
     */
    private String dashboardKey = "dashboard:data";
    
    /**
     * 用户详情前缀
     */
    private String userDetailPrefix = "user:detail:";
    
    /**
     * 认证用户前缀
     */
    private String authUserPrefix = "auth:user:";
    
    /**
     * Token黑名单前缀
     */
    private String tokenBlacklistPrefix = "auth:token:blacklist:";
    
    /**
     * 锁前缀
     */
    private String lockPrefix = "lock:cache:";
    
    /**
     * 用户列表前缀
     */
    private String userListPrefix = "user:list:";
    
    /**
     * 建筑详情前缀
     */
    private String buildingDetailPrefix = "building:detail:";
    
    /**
     * 建筑列表前缀
     */
    private String buildingListPrefix = "building:list:";
    
    /**
     * 检测详情前缀
     */
    private String detectionDetailPrefix = "detection:detail:";
    
    /**
     * 检测列表前缀
     */
    private String detectionListPrefix = "detection:list:";
    
    /**
     * 报告详情前缀
     */
    private String reportDetailPrefix = "report:detail:";

    /**
     * 生成用户详情缓存键
     */
    public String userDetailKey(Long userId) {
        return userDetailPrefix + userId;
    }

    /**
     * 生成认证用户缓存键
     */
    public String authUserKey(String account) {
        return authUserPrefix + account;
    }

    /**
     * 生成Token黑名单缓存键
     */
    public String tokenBlacklistKey(String tokenHash) {
        return tokenBlacklistPrefix + tokenHash;
    }

    /**
     * 生成分布式锁键
     */
    public String lockKey(String cacheKey) {
        return lockPrefix + cacheKey;
    }

    /**
     * 生成建筑详情缓存键
     */
    public String buildingDetailKey(Long buildingId) {
        return buildingDetailPrefix + buildingId;
    }

    /**
     * 生成检测详情缓存键
     */
    public String detectionDetailKey(Long detectionId) {
        return detectionDetailPrefix + detectionId;
    }

    /**
     * 生成报告详情缓存键
     */
    public String reportDetailKey(Long reportId) {
        return reportDetailPrefix + reportId;
    }
}
