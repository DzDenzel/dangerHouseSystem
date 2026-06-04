package com.dz.dangerhouse.client;

import com.dz.dangerhouse.config.AiDetectionProperties;
import com.dz.dangerhouse.dto.response.AiDetectionResponse;
import com.dz.dangerhouse.exception.BusinessException;
import com.dz.dangerhouse.util.FileUploadUtil;
import lombok.extern.slf4j.Slf4j;
import org.springframework.core.io.FileSystemResource;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Component;
import org.springframework.util.LinkedMultiValueMap;
import org.springframework.util.MultiValueMap;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.multipart.MultipartFile;

import java.io.File;
import java.util.ArrayList;
import java.util.List;

/**
 * AI检测服务客户端
 * 负责调用Python FastAPI AI微服务进行损伤检测分析
 */
@Slf4j
@Component
public class AiDetectionClient {

    private final RestTemplate restTemplate;
    private final FileUploadUtil fileUploadUtil;
    private final AiDetectionProperties aiDetectionProperties;

    public AiDetectionClient(
            RestTemplate restTemplate,
            FileUploadUtil fileUploadUtil,
            AiDetectionProperties aiDetectionProperties) {
        this.restTemplate = restTemplate;
        this.fileUploadUtil = fileUploadUtil;
        this.aiDetectionProperties = aiDetectionProperties;
    }

    /**
     * 从多张图片中检测损伤
     *
     * @param imageFiles 图片文件列表
     * @return AI检测结果响应
     */
    public AiDetectionResponse detectDamage(List<File> imageFiles) {
        try {
            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.MULTIPART_FORM_DATA);

            MultiValueMap<String, Object> body = new LinkedMultiValueMap<>();
            for (File file : imageFiles) {
                body.add("images", new FileSystemResource(file));
            }

            String detectionUrl = getDetectionUrl();
            HttpEntity<MultiValueMap<String, Object>> requestEntity = new HttpEntity<>(body, headers);

            log.info("发送AI检测请求: url={}, 图片数量={}", detectionUrl, imageFiles.size());

            ResponseEntity<AiDetectionResponse> response = restTemplate.exchange(
                    detectionUrl,
                    HttpMethod.POST,
                    requestEntity,
                    AiDetectionResponse.class
            );

            if (response.getStatusCode() == HttpStatus.OK && response.getBody() != null) {
                log.info("AI检测完成: code={}", response.getBody().getCode());
                return response.getBody();
            }

            log.error("AI检测请求失败: status={}", response.getStatusCode());
            throw new BusinessException("AI检测请求失败");
        } catch (Exception e) {
            log.error("AI检测请求异常", e);
            throw new BusinessException("AI检测请求失败: " + e.getMessage(), e);
        }
    }

    /**
     * 从单张图片中检测损伤
     *
     * @param imageFile 图片文件
     * @return AI检测结果响应
     */
    public AiDetectionResponse detectDamage(File imageFile) {
        List<File> files = new ArrayList<>();
        files.add(imageFile);
        return detectDamage(files);
    }

    /**
     * 从上传的文件中检测损伤（自动转换为临时文件）
     *
     * @param multipartFile 上传的文件
     * @return AI检测结果响应
     */
    public AiDetectionResponse detectDamage(MultipartFile multipartFile) {
        File tempFile = null;
        try {
            tempFile = fileUploadUtil.saveTempFile(multipartFile);
            return detectDamage(tempFile);
        } finally {
            if (tempFile != null) {
                fileUploadUtil.deleteTempFile(tempFile);
            }
        }
    }

    /**
     * 获取AI检测服务URL
     *
     * @return 检测服务URL
     */
    private String getDetectionUrl() {
        String url = aiDetectionProperties.getUrl();
        if (url == null || url.isBlank()) {
            throw new BusinessException("AI检测服务URL未配置");
        }
        return url;
    }
}
