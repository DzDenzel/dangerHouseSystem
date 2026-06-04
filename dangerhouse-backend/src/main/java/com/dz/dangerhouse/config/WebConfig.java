package com.dz.dangerhouse.config;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.ResourceHandlerRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

/**
 * Web MVC配置类
 */
@Slf4j
@Configuration
public class WebConfig implements WebMvcConfigurer {

    @Value("${file.upload.base-dir:D:/dangerhouse/uploads}")
    private String uploadBaseDir;

    @Value("${file.upload.url-prefix:/uploads}")
    private String urlPrefix;

    /**
     * 添加静态资源映射
     */
    @Override
    public void addResourceHandlers(ResourceHandlerRegistry registry) {
        String location = "file:" + uploadBaseDir + "/";
        registry.addResourceHandler(urlPrefix + "/**")
                .addResourceLocations(location);
        log.info("静态资源映射: {} -> {}", urlPrefix + "/**", location);
    }
}
