package com.dz.dangerhouse.config;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.data.redis.connection.RedisConnectionFactory;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.data.redis.serializer.GenericJackson2JsonRedisSerializer;
import org.springframework.data.redis.serializer.StringRedisSerializer;

/**
 * Redis配置类
 * 配置RedisTemplate序列化方式，支持JSON格式存储和Java 8日期时间类型
 */
@Configuration
public class RedisConfig {

    /**
     * 配置RedisTemplate
     * key使用String序列化，value使用JSON序列化（支持LocalDateTime等Java 8时间类型）
     *
     * @param factory Redis连接工厂
     * @param objectMapper Jackson对象映射器（Spring Boot自动配置，已注册JavaTimeModule）
     * @return 配置好的RedisTemplate
     */
    @Bean
    public RedisTemplate<String, Object> redisTemplate(RedisConnectionFactory factory, ObjectMapper objectMapper) {
        RedisTemplate<String, Object> template = new RedisTemplate<>();
        template.setConnectionFactory(factory);

        // key使用字符串序列化
        template.setKeySerializer(new StringRedisSerializer());
        template.setHashKeySerializer(new StringRedisSerializer());

        // 使用Spring Boot自动配置的ObjectMapper（已包含JavaTimeModule）
        // 创建支持Java 8时间类型的JSON序列化器
        GenericJackson2JsonRedisSerializer serializer = new GenericJackson2JsonRedisSerializer(objectMapper);
        template.setValueSerializer(serializer);
        template.setHashValueSerializer(serializer);

        template.afterPropertiesSet();
        return template;
    }
}
