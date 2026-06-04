package com.dz.dangerhouse.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.client.SimpleClientHttpRequestFactory;
import org.springframework.web.client.RestTemplate;

/**
 * RestTemplate 配置类
 * 用于配置 HTTP 客户端，调用外部 AI 微服务
 */
@Configuration
public class RestTemplateConfig {

    /**
     * 注册 RestTemplate Bean
     * 设置超时时间：连接超时 5 秒，读取超时 30 秒
     */
    @Bean
    public RestTemplate restTemplate() {
        SimpleClientHttpRequestFactory factory = new SimpleClientHttpRequestFactory();
        factory.setConnectTimeout(5000);  // 连接超时：5 秒
        factory.setReadTimeout(30000);    // 读取超时：30 秒（AI 推理可能较慢）
        return new RestTemplate(factory);
    }
}