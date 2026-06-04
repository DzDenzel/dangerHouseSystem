package com.dz.dangerhouse.config;

import lombok.Data;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

/**
 * 阿里云OSS配置属性
 */
@Data
@Component
@ConfigurationProperties(prefix = "aliyun.oss")
public class OssProperties {

    /**
     * OSS端点，例如：oss-cn-hangzhou.aliyuncs.com
     */
    private String endpoint;

    /**
     * 访问密钥ID
     */
    private String accessKeyId;

    /**
     * 访问密钥Secret
     */
    private String accessKeySecret;

    /**
     * 存储桶名称
     */
    private String bucketName;

    /**
     * 公共基础URL，用于构建文件访问链接
     */
    private String baseUrl;

    /**
     * 签名URL过期时间（秒），默认一小时
     */
    private Long signatureExpireSeconds = 3600L;

    /**
     * 最大文件大小（字节），默认10MB
     */
    private Long maxFileSize = 10 * 1024 * 1024L;

    /**
     * 是否启用OSS存储，禁用时回退到本地存储
     */
    private Boolean enabled;
}
