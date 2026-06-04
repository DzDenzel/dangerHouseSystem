package com.dz.dangerhouse.cache;

import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.extern.slf4j.Slf4j;
import org.springframework.dao.DataAccessException;
import org.springframework.data.redis.connection.RedisConnection;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.data.redis.core.script.DefaultRedisScript;
import org.springframework.data.redis.core.ScanOptions;
import org.springframework.stereotype.Service;

import java.io.Serializable;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.UUID;
import java.util.concurrent.ThreadLocalRandom;
import java.util.concurrent.TimeUnit;
import java.util.function.Supplier;

/**
 * 缓存服务封装类
 * 提供Redis缓存读写、分布式锁、穿透防护等功能
 */
@Slf4j
@Service
public class CacheService {

    /**
     * 空值标记（用于缓存穿透防护）
     */
    private enum NullValue implements Serializable {
        INSTANCE
    }

    /**
     * Redis解锁Lua脚本
     */
    private static final DefaultRedisScript<Long> UNLOCK_SCRIPT = new DefaultRedisScript<>(
            "if redis.call('get', KEYS[1]) == ARGV[1] then " +
                    "return redis.call('del', KEYS[1]) " +
                    "else return 0 end",
            Long.class
    );

    private final RedisTemplate<String, Object> redisTemplate;
    private final CacheProperties cacheProperties;
    private final ObjectMapper objectMapper;

    public CacheService(
            RedisTemplate<String, Object> redisTemplate,
            CacheProperties cacheProperties,
            ObjectMapper objectMapper
    ) {
        this.redisTemplate = redisTemplate;
        this.cacheProperties = cacheProperties;
        this.objectMapper = objectMapper;
    }

    /**
     * 获取缓存值
     */
    public <T> T get(String key, Class<T> type) {
        return readCacheValue(key, type).value();
    }

    /**
     * 写入缓存
     */
    public void put(String key, Object value, long timeout, TimeUnit unit) {
        try {
            redisTemplate.opsForValue().set(key, value, timeout, unit);
        } catch (DataAccessException ex) {
            log.warn("Redis写入跳过, key={}, 原因={}", key, ex.getMessage());
        } catch (RuntimeException ex) {
            log.warn("缓存写入失败, key={}, 原因={}", key, ex.getMessage());
        }
    }

    /**
     * 写入缓存（带随机抖动，防止雪崩）
     */
    public void putWithJitter(String key, Object value, long timeout, TimeUnit unit) {
        long timeoutSeconds = unit.toSeconds(timeout);
        if (timeoutSeconds <= 0) {
            put(key, value, timeout, unit);
            return;
        }

        long jitterSeconds = Math.max(0L, cacheProperties.getTtlJitterSeconds());
        long randomizedSeconds = timeoutSeconds
                + (jitterSeconds > 0 ? ThreadLocalRandom.current().nextLong(jitterSeconds + 1) : 0L);
        put(key, value, randomizedSeconds, TimeUnit.SECONDS);
    }

    /**
     * 删除缓存
     */
    public void delete(String key) {
        try {
            redisTemplate.delete(key);
        } catch (DataAccessException ex) {
            log.warn("Redis删除跳过, key={}, 原因={}", key, ex.getMessage());
        } catch (RuntimeException ex) {
            log.warn("缓存删除失败, key={}, 原因={}", key, ex.getMessage());
        }
    }

    /**
     * 按前缀批量删除缓存
     */
    public void deleteByPrefix(String prefix) {
        try {
            List<String> keys = scanKeys(prefix + "*");
            if (!keys.isEmpty()) {
                redisTemplate.delete(keys);
            }
        } catch (DataAccessException ex) {
            log.warn("Redis前缀删除跳过, prefix={}, 原因={}", prefix, ex.getMessage());
        } catch (RuntimeException ex) {
            log.warn("缓存前缀删除失败, prefix={}, 原因={}", prefix, ex.getMessage());
        }
    }

    /**
     * 查询缓存（支持穿透防护）
     */
    public <T> T queryWithPassThrough(String key, Class<T> type, Supplier<T> dbFallback,
            long timeout, TimeUnit unit) {
        CacheLookup<T> lookup = readCacheValue(key, type);
        if (lookup.hit()) {
            return lookup.value();
        }

        T loaded = dbFallback.get();
        if (loaded == null) {
            putNullValue(key);
            return null;
        }

        putWithJitter(key, loaded, timeout, unit);
        return loaded;
    }

    /**
     * 查询缓存（支持分布式锁，防止击穿）
     */
    public <T> T queryWithMutex(String key, Class<T> type, Supplier<T> dbFallback,
            long timeout, TimeUnit unit) {
        String lockKey = cacheProperties.lockKey(key);
        String lockValue = null;

        for (int retry = 0; retry <= cacheProperties.getMutexMaxRetries(); retry++) {
            CacheLookup<T> lookup = readCacheValue(key, type);
            if (lookup.hit()) {
                return lookup.value();
            }

            lockValue = tryLock(lockKey);
            if (lockValue != null) {
                break;
            }

            if (retry < cacheProperties.getMutexMaxRetries()) {
                sleepQuietly(cacheProperties.getMutexRetryDelayMillis());
            }
        }

        if (lockValue == null) {
            return queryWithPassThrough(key, type, dbFallback, timeout, unit);
        }

        try {
            CacheLookup<T> lookup = readCacheValue(key, type);
            if (lookup.hit()) {
                return lookup.value();
            }

            T loaded = dbFallback.get();
            if (loaded == null) {
                putNullValue(key);
                return null;
            }

            putWithJitter(key, loaded, timeout, unit);
            return loaded;
        } finally {
            unlock(lockKey, lockValue);
        }
    }

    /**
     * 尝试获取分布式锁
     */
    public String tryLock(String key) {
        String lockValue = UUID.randomUUID().toString();
        try {
            Boolean locked = redisTemplate.opsForValue().setIfAbsent(
                    key,
                    lockValue,
                    Duration.ofSeconds(cacheProperties.getMutexLockTtlSeconds())
            );
            return Boolean.TRUE.equals(locked) ? lockValue : null;
        } catch (DataAccessException ex) {
            log.warn("Redis加锁跳过, key={}, 原因={}", key, ex.getMessage());
            return null;
        } catch (RuntimeException ex) {
            log.warn("缓存加锁失败, key={}, 原因={}", key, ex.getMessage());
            return null;
        }
    }

    /**
     * 释放分布式锁
     */
    public void unlock(String key, String lockValue) {
        if (lockValue == null) {
            return;
        }
        try {
            redisTemplate.execute(UNLOCK_SCRIPT, Collections.singletonList(key), lockValue);
        } catch (DataAccessException ex) {
            log.warn("Redis解锁跳过, key={}, 原因={}", key, ex.getMessage());
        } catch (RuntimeException ex) {
            log.warn("缓存解锁失败, key={}, 原因={}", key, ex.getMessage());
        }
    }

    /**
     * 从Redis读取原始数据
     */
    private Object getRaw(String key) {
        try {
            return redisTemplate.opsForValue().get(key);
        } catch (DataAccessException ex) {
            log.warn("Redis读取失败，回源数据库, key={}, 原因={}", key, ex.getMessage());
            return null;
        } catch (RuntimeException ex) {
            log.warn("缓存读取失败，回源数据库, key={}, 原因={}", key, ex.getMessage());
            return null;
        }
    }

    /**
     * 写入空值标记（防穿透）
     */
    private void putNullValue(String key) {
        put(key, NullValue.INSTANCE, cacheProperties.getNullValueTtlSeconds(), TimeUnit.SECONDS);
    }

    /**
     * 读取并转换缓存值
     */
    private <T> CacheLookup<T> readCacheValue(String key, Class<T> type) {
        Object value = getRaw(key);
        if (value == null) {
            return CacheLookup.miss();
        }
        if (value == NullValue.INSTANCE) {
            return CacheLookup.hit(null);
        }

        T typedValue = castValue(key, value, type);
        return typedValue != null ? CacheLookup.hit(typedValue) : CacheLookup.miss();
    }

    /**
     * 类型转换（支持自动修复）
     */
    private <T> T castValue(String key, Object value, Class<T> type) {
        // 类型匹配直接返回
        if (type.isInstance(value)) {
            return type.cast(value);
        }

        log.warn("缓存值类型不匹配, key={}, 期望类型={}, 实际类型={}",
                key, type.getName(), value.getClass().getName());

        // Page泛型对象无法安全转换，直接删除旧缓存回源重建
        if ("com.baomidou.mybatisplus.extension.plugins.pagination.Page".equals(type.getName())) {
            log.warn("Page缓存无法安全自动转换，清除无效缓存, key={}", key);
            delete(key);
            return null;
        }

        // 尝试使用Jackson转换
        try {
            T converted = objectMapper.convertValue(value, type);
            log.info("缓存值自动转换成功, key={}, 目标类型={}", key, type.getName());
            return converted;
        } catch (IllegalArgumentException ex) {
            log.warn("缓存值转换失败，清除无效缓存, key={}, 原因={}",
                    key, ex.getMessage());
            delete(key);
            return null;
        }
    }

    /**
     * 扫描匹配的键
     */
    private List<String> scanKeys(String pattern) {
        return redisTemplate.execute((RedisConnection connection) -> {
            List<String> keys = new ArrayList<>();
            ScanOptions options = ScanOptions.scanOptions()
                    .match(pattern)
                    .count(200)
                    .build();
            try (var cursor = connection.scan(options)) {
                while (cursor.hasNext()) {
                    keys.add(new String(cursor.next(), StandardCharsets.UTF_8));
                }
            } catch (Exception ex) {
                throw new IllegalStateException("Redis扫描失败", ex);
            }
            return keys;
        });
    }

    /**
     * 静默休眠
     */
    private void sleepQuietly(long millis) {
        if (millis <= 0) {
            return;
        }
        try {
            Thread.sleep(millis);
        } catch (InterruptedException ex) {
            Thread.currentThread().interrupt();
        }
    }

    /**
     * 缓存查找结果封装
     */
    private record CacheLookup<T>(boolean hit, T value) {
        private static <T> CacheLookup<T> hit(T value) {
            return new CacheLookup<>(true, value);
        }

        private static <T> CacheLookup<T> miss() {
            return new CacheLookup<>(false, null);
        }
    }
}
