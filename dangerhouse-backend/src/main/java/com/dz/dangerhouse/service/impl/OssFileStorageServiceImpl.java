package com.dz.dangerhouse.service.impl;

import com.aliyun.oss.OSS;
import com.aliyun.oss.OSSClientBuilder;
import com.aliyun.oss.model.OSSObject;
import com.aliyun.oss.model.ObjectMetadata;
import com.dz.dangerhouse.config.OssProperties;
import com.dz.dangerhouse.exception.BusinessException;
import com.dz.dangerhouse.service.FileStorageService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import jakarta.annotation.PostConstruct;
import jakarta.annotation.PreDestroy;
import java.io.ByteArrayInputStream;
import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.net.URL;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.Date;
import java.util.HashSet;
import java.util.Set;
import java.util.UUID;

/**
 * 阿里云OSS文件存储服务实现
 *
 * 启用条件：配置 aliyun.oss.enabled=true（默认启用）
 *
 * @author dangerhouse
 */
@Slf4j
@Service
@ConditionalOnProperty(prefix = "aliyun.oss", name = "enabled", havingValue = "true")
public class OssFileStorageServiceImpl implements FileStorageService {

    @Autowired
    private OssProperties ossProperties;

    private OSS ossClient;

    private static final String IMAGE_DIR = "images";

    private static final String RESULT_DIR = "results";

    private static final String REPORT_DIR = "reports";

    private static final String TEMP_DIR = "temp";

    private static final DateTimeFormatter DATE_FORMATTER = DateTimeFormatter.ofPattern("yyyy/MM/dd");

    private static final Set<String> ALLOWED_IMAGE_TYPES = new HashSet<String>() {{
        add("image/jpeg");
        add("image/jpg");
        add("image/png");
        add("image/gif");
        add("image/webp");
        add("image/bmp");
    }};

    private static final Set<String> ALLOWED_PDF_TYPES = new HashSet<String>() {{
        add("application/pdf");
    }};

    /**
     * 临时文件不落OSS，统一写到本地磁盘（AI检测需要可读的本地文件路径）
     */
    private static final String LOCAL_TEMP_BASE_DIR = System.getProperty("java.io.tmpdir") + "/dangerhouse";

    @PostConstruct
    public void init() {
        try {
            ossClient = new OSSClientBuilder().build(
                    ossProperties.getEndpoint(),
                    ossProperties.getAccessKeyId(),
                    ossProperties.getAccessKeySecret()
            );
            log.info("阿里云OSS客户端初始化成功，endpoint: {}, bucket: {}",
                    ossProperties.getEndpoint(), ossProperties.getBucketName());
        } catch (Exception e) {
            log.error("阿里云OSS客户端初始化失败", e);
            throw new BusinessException("OSS客户端初始化失败: " + e.getMessage(), e);
        }
    }

    @PreDestroy
    public void destroy() {
        if (ossClient != null) {
            ossClient.shutdown();
            log.info("阿里云OSS客户端已关闭");
        }
    }

    @Override
    public String uploadImage(MultipartFile file) {
        validateImageFile(file);
        return uploadFile(file, IMAGE_DIR);
    }

    @Override
    public String uploadResultImage(MultipartFile file) {
        validateImageFile(file);
        return uploadFile(file, RESULT_DIR);
    }

    @Override
    public String uploadPdf(MultipartFile file) {
        validatePdfFile(file);
        return uploadFile(file, REPORT_DIR);
    }

    @Override
    public String uploadFile(MultipartFile file, String directory) {
        validateFile(file);

        try {
            String originalFilename = file.getOriginalFilename();
            String extension = getFileExtension(originalFilename);
            String fileName = generateFileName(extension);
            String objectKey = buildObjectKey(directory, fileName);

            ObjectMetadata metadata = new ObjectMetadata();
            metadata.setContentLength(file.getSize());
            metadata.setContentType(file.getContentType());
            metadata.setCacheControl("max-age=31536000"); // 缓存1年
            metadata.setContentDisposition("inline");

            ossClient.putObject(
                    ossProperties.getBucketName(),
                    objectKey,
                    file.getInputStream(),
                    metadata
            );

            log.info("文件上传OSS成功: {}", objectKey);
            return objectKey;
        } catch (IOException e) {
            log.error("文件上传OSS失败", e);
            throw new BusinessException("文件上传失败: " + e.getMessage(), e);
        } catch (Exception e) {
            log.error("OSS上传异常", e);
            throw new BusinessException("文件上传失败: " + e.getMessage(), e);
        }
    }

    /**
     * 适用于从内存直接上传的场景（如Base64解码后的数据）
     */
    @Override
    public String uploadBytes(byte[] data, String fileName, String directory, String contentType) {
        if (data == null || data.length == 0) {
            throw new BusinessException("文件数据不能为空");
        }

        try {
            String objectKey = buildObjectKey(directory, fileName);

            ObjectMetadata metadata = new ObjectMetadata();
            metadata.setContentLength(data.length);
            metadata.setContentType(contentType);
            metadata.setCacheControl("max-age=31536000");
            metadata.setContentDisposition("inline");

            ossClient.putObject(
                    ossProperties.getBucketName(),
                    objectKey,
                    new ByteArrayInputStream(data),
                    metadata
            );

            log.info("字节数据上传OSS成功: {}, 大小: {} bytes", objectKey, data.length);
            return objectKey;
        } catch (Exception e) {
            log.error("字节数据上传OSS失败", e);
            throw new BusinessException("文件上传失败: " + e.getMessage(), e);
        }
    }

    /**
     * 适用于大文件或流式传输场景
     */
    @Override
    public String uploadStream(InputStream inputStream, String fileName, String directory, String contentType) {
        if (inputStream == null) {
            throw new BusinessException("输入流不能为空");
        }

        try {
            String objectKey = buildObjectKey(directory, fileName);

            ObjectMetadata metadata = new ObjectMetadata();
            metadata.setContentType(contentType);
            metadata.setCacheControl("max-age=31536000");
            metadata.setContentDisposition("inline");

            ossClient.putObject(
                    ossProperties.getBucketName(),
                    objectKey,
                    inputStream,
                    metadata
            );

            log.info("流数据上传OSS成功: {}", objectKey);
            return objectKey;
        } catch (Exception e) {
            log.error("流数据上传OSS失败", e);
            throw new BusinessException("文件上传失败: " + e.getMessage(), e);
        }
    }

    /**
     * 自动解析Base64前缀并提取图片类型
     */
    @Override
    public String saveBase64Image(String base64Data) {
        if (base64Data == null || base64Data.isEmpty()) {
            return null;
        }

        try {
            // 解析Base64数据
            String contentType = "image/jpeg";
            String pureBase64 = base64Data;

            // 处理带前缀的Base64（如 data:image/png;base64,xxxxx）
            if (base64Data.contains(",")) {
                String[] parts = base64Data.split(",");
                String prefix = parts[0];
                pureBase64 = parts[1];

                // 提取图片类型
                if (prefix.contains("image/")) {
                    int start = prefix.indexOf("image/");
                    int end = prefix.indexOf(";", start);
                    if (end > start) {
                        contentType = prefix.substring(start, end);
                    }
                }
            }

            byte[] imageBytes = java.util.Base64.getDecoder().decode(pureBase64);
            String extension = getExtensionFromContentType(contentType);
            String fileName = generateFileName(extension);

            return uploadBytes(imageBytes, fileName, RESULT_DIR, contentType);
        } catch (Exception e) {
            log.error("Base64图片保存失败", e);
            throw new BusinessException("Base64图片保存失败: " + e.getMessage(), e);
        }
    }

    /**
     * 保存临时文件到本地磁盘（用于AI检测前的文件预处理）
     */
    @Override
    public File saveTempFile(MultipartFile file) {
        try {
            validateFile(file);

            String originalFilename = file.getOriginalFilename();
            String extension = getFileExtension(originalFilename);
            String newFileName = generateFileName(extension);

            String datePath = LocalDateTime.now().format(DATE_FORMATTER);
            Path targetDir = Paths.get(LOCAL_TEMP_BASE_DIR, TEMP_DIR, datePath);
            Path targetPath = targetDir.resolve(newFileName);

            Files.createDirectories(targetDir);
            file.transferTo(targetPath.toFile());

            log.info("临时文件保存成功: {}", targetPath);
            return targetPath.toFile();
        } catch (IOException e) {
            log.error("保存临时文件失败", e);
            throw new BusinessException("保存临时文件失败: " + e.getMessage(), e);
        }
    }

    @Override
    public void deleteTempFile(File file) {
        if (file == null) {
            return;
        }
        try {
            if (file.exists() && !file.delete()) {
                log.warn("删除临时文件失败: {}", file.getAbsolutePath());
            }
        } catch (Exception e) {
            log.warn("删除临时文件异常: {}", file.getAbsolutePath(), e);
        }
    }

    @Override
    public void deleteTempFiles(Iterable<File> files) {
        if (files == null) {
            return;
        }
        for (File file : files) {
            deleteTempFile(file);
        }
    }

    @Override
    public String getFileUrl(String relativePath) {
        if (relativePath == null || relativePath.isEmpty()) {
            return null;
        }

        if (relativePath.startsWith("http://") || relativePath.startsWith("https://")) {
            return relativePath;
        }

        // 拼接基础URL
        String baseUrl = ossProperties.getBaseUrl();
        if (baseUrl.endsWith("/")) {
            baseUrl = baseUrl.substring(0, baseUrl.length() - 1);
        }

        String path = relativePath;
        if (path.startsWith("/")) {
            path = path.substring(1);
        }

        return baseUrl + "/" + path;
    }

    /**
     * 用于私有bucket的文件临时访问
     */
    @Override
    public String getSignedUrl(String relativePath, long expireSeconds) {
        if (relativePath == null || relativePath.isEmpty()) {
            return null;
        }

        try {
            String objectKey = resolveObjectKey(relativePath);

            Date expiration = new Date(System.currentTimeMillis() + expireSeconds * 1000);
            URL url = ossClient.generatePresignedUrl(
                    ossProperties.getBucketName(),
                    objectKey,
                    expiration
            );

            return url.toString();
        } catch (Exception e) {
            log.error("生成签名URL失败: {}", relativePath, e);
            throw new BusinessException("生成签名URL失败: " + e.getMessage(), e);
        }
    }

    @Override
    public String getSignedUrl(String relativePath) {
        return getSignedUrl(relativePath, ossProperties.getSignatureExpireSeconds());
    }

    @Override
    public byte[] downloadBytes(String relativePath) {
        if (relativePath == null || relativePath.isEmpty()) {
            return null;
        }

        try (OSSObject ossObject = ossClient.getObject(ossProperties.getBucketName(), resolveObjectKey(relativePath));
             InputStream inputStream = ossObject.getObjectContent()) {

            return inputStream.readAllBytes();
        } catch (Exception e) {
            log.error("下载文件失败: {}", relativePath, e);
            throw new BusinessException("下载文件失败: " + e.getMessage(), e);
        }
    }

    /**
     * 适用于大文件流式处理，返回的输入流由调用者负责关闭
     */
    @Override
    public InputStream downloadStream(String relativePath) {
        if (relativePath == null || relativePath.isEmpty()) {
            return null;
        }

        try {
            OSSObject ossObject = ossClient.getObject(ossProperties.getBucketName(), resolveObjectKey(relativePath));
            return ossObject.getObjectContent();
        } catch (Exception e) {
            log.error("下载文件失败: {}", relativePath, e);
            throw new BusinessException("下载文件失败: " + e.getMessage(), e);
        }
    }

    @Override
    public boolean deleteFile(String relativePath) {
        if (relativePath == null || relativePath.isEmpty()) {
            return false;
        }

        try {
            String objectKey = resolveObjectKey(relativePath);

            ossClient.deleteObject(ossProperties.getBucketName(), objectKey);
            log.info("文件删除成功: {}", objectKey);
            return true;
        } catch (Exception e) {
            log.error("删除文件失败: {}", relativePath, e);
            return false;
        }
    }

    @Override
    public boolean fileExists(String relativePath) {
        if (relativePath == null || relativePath.isEmpty()) {
            return false;
        }

        try {
            String objectKey = resolveObjectKey(relativePath);

            return ossClient.doesObjectExist(ossProperties.getBucketName(), objectKey);
        } catch (Exception e) {
            log.error("检查文件存在失败: {}", relativePath, e);
            return false;
        }
    }

    /**
     * 查询失败时返回 0 而不是抛异常
     */
    @Override
    public long getFileSize(String relativePath) {
        if (relativePath == null || relativePath.isEmpty()) {
            return 0;
        }

        try {
            String objectKey = resolveObjectKey(relativePath);

            ObjectMetadata metadata = ossClient.getObjectMetadata(ossProperties.getBucketName(), objectKey);
            return metadata.getContentLength();
        } catch (Exception e) {
            log.error("获取文件大小失败: {}", relativePath, e);
            return 0;
        }
    }

    @Override
    public String getStorageType() {
        return "OSS";
    }

    @Override
    public String getReportDir() {
        return REPORT_DIR;
    }

    @Override
    public String getImageDir() {
        return IMAGE_DIR;
    }

    @Override
    public String getResultDir() {
        return RESULT_DIR;
    }

    /**
     * 校验文件基本信息（非空、大小限制）
     */
    private void validateFile(MultipartFile file) {
        if (file == null || file.isEmpty()) {
            throw new BusinessException("文件不能为空");
        }

        long maxSize = ossProperties.getMaxFileSize();
        if (file.getSize() > maxSize) {
            throw new BusinessException("文件大小不能超过 " + (maxSize / 1024 / 1024) + "MB");
        }
    }

    private void validateImageFile(MultipartFile file) {
        validateFile(file);

        String contentType = file.getContentType();
        if (contentType == null || !ALLOWED_IMAGE_TYPES.contains(contentType.toLowerCase())) {
            throw new BusinessException("文件类型仅支持图片（jpg、png、gif、webp、bmp）");
        }
    }

    private void validatePdfFile(MultipartFile file) {
        validateFile(file);

        String contentType = file.getContentType();
        if (contentType == null || !ALLOWED_PDF_TYPES.contains(contentType.toLowerCase())) {
            throw new BusinessException("文件类型仅支持PDF");
        }
    }

    /**
     * 构建OSS对象Key（包含日期路径）
     * 格式：directory/yyyy/MM/dd/filename
     */
    private String buildObjectKey(String directory, String fileName) {
        String datePath = LocalDateTime.now().format(DATE_FORMATTER);
        return directory + "/" + datePath + "/" + fileName;
    }

    /**
     * 统一解析OSS对象Key
     * 支持相对路径、完整URL、带前导/的路径
     */
    private String resolveObjectKey(String path) {
        if (path == null || path.isEmpty()) {
            return path;
        }

        String objectKey = path;
        if (path.startsWith("http://") || path.startsWith("https://")) {
            String baseUrl = ossProperties.getBaseUrl();
            if (baseUrl != null && !baseUrl.isEmpty() && path.startsWith(baseUrl)) {
                objectKey = path.substring(baseUrl.length());
            }
        }

        // 去除前导斜杠
        while (objectKey.startsWith("/")) {
            objectKey = objectKey.substring(1);
        }
        return objectKey;
    }

    private String generateFileName(String extension) {
        return UUID.randomUUID().toString().replace("-", "") + extension;
    }

    private String getFileExtension(String filename) {
        if (filename == null || filename.isEmpty()) {
            return ".jpg";
        }
        int lastDotIndex = filename.lastIndexOf('.');
        if (lastDotIndex == -1 || lastDotIndex == filename.length() - 1) {
            return ".jpg";
        }
        return filename.substring(lastDotIndex);
    }

    private String getExtensionFromContentType(String contentType) {
        if (contentType == null) {
            return ".jpg";
        }
        switch (contentType.toLowerCase()) {
            case "image/png":
                return ".png";
            case "image/gif":
                return ".gif";
            case "image/webp":
                return ".webp";
            case "image/bmp":
                return ".bmp";
            case "application/pdf":
                return ".pdf";
            default:
                return ".jpg";
        }
    }
}
