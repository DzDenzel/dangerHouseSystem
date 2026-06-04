package com.dz.dangerhouse.config;

import lombok.Data;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

/**
 * AI检测服务配置属性类
 * 从application.yml中读取ai.detection前缀的配置项
 */
@Data
@Component
@ConfigurationProperties(prefix = "ai.detection")
public class AiDetectionProperties {

    /**
     * AI检测服务端点URL
     */
    private String url;
}
