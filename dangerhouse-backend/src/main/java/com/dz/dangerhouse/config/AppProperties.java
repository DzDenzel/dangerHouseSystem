package com.dz.dangerhouse.config;

import lombok.Data;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

/**
 * 应用配置属性类
 * 从application.yml中读取app前缀的配置项
 */
@Data
@Component
@ConfigurationProperties(prefix = "app")
public class AppProperties {

    /**
     * 后端基础URL，用于构建文件预览和下载链接
     */
    private String baseUrl;
}
