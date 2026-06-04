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
 * 企业级文件存储服务，提供：
 * - 文件上传（图片、PDF）
 * - 文件下载
 * - 文件删除
 * - 签名URL生成
 * - 文件校验
 * - 异常处理
 * - 日志记录
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

    /**
     * 图片目录
     */
    private static final String IMAGE_DIR = "images";

    /**
     * 检测结果图片目录
     */
    private static final String RESULT_DIR = "results";

    /**
     * 报告目录
     */
    private static final String REPORT_DIR = "reports";

    /**
     * 临时文件目录
     */
    private static final String TEMP_DIR = "temp";

    /**
     * 日期路径格式
     */
    private static final DateTimeFormatter DATE_FORMATTER = DateTimeFormatter.ofPattern("yyyy/MM/dd");

    /**
     * 允许的图片类型
     */
    private static final Set<String> ALLOWED_IMAGE_TYPES = new HashSet<String>() {{
        add("image/jpeg");
        add("image/jpg");
        add("image/png");
        add("image/gif");
        add("image/webp");
        add("image/bmp");
    }};

    /**
     * 允许的PDF类型
     */
    private static final Set<String> ALLOWED_PDF_TYPES = new HashSet<String>() {{
        add("application/pdf");
    }};

    /**
     * 本地临时文件基础目录（用于临时文件处理）
     */
    private static final String LOCAL_TEMP_BASE_DIR = System.getProperty("java.io.tmpdir") + "/dangerhouse";

    /**
     * 初始化OSS客户端
     */
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

    /**
     * 销毁OSS客户端
     */
    @PreDestroy
    public void destroy() {
        if (ossClient != null) {
            ossClient.shutdown();
            log.info("阿里云OSS客户端已关闭");
        }
    }

    /**
     * 上传图片文件到OSS
     * 自动校验文件类型和大小
     *
     * @param file 图片文件
     * @return OSS对象Key
     */
    @Override
    public String uploadImage(MultipartFile file) {
        validateImageFile(file);
        return uploadFile(file, IMAGE_DIR);
    }

    /**
     * 上传检测结果图片到OSS
     *
     * @param file 结果图片文件
     * @return OSS对象Key
     */
    @Override
    public String uploadResultImage(MultipartFile file) {
        validateImageFile(file);
        return uploadFile(file, RESULT_DIR);
    }

    /**
     * 上传PDF报告文件到OSS
     *
     * @param file PDF文件
     * @return OSS对象Key
     */
    @Override
    public String uploadPdf(MultipartFile file) {
        validatePdfFile(file);
        return uploadFile(file, REPORT_DIR);
    }

    /**
     * 通用文件上传方法
     * 将文件上传到指定的OSS目录
     *
     * @param file      待上传文件
     * @param directory OSS目录
     * @return OSS对象Key（相对路径）
     */
    @Override
    public String uploadFile(MultipartFile file, String directory) {
        validateFile(file);

        try {
            String originalFilename = file.getOriginalFilename();
            String extension = getFileExtension(originalFilename);
            String fileName = generateFileName(extension);
            String objectKey = buildObjectKey(directory, fileName);

            // 设置元数据
            ObjectMetadata metadata = new ObjectMetadata();
            metadata.setContentLength(file.getSize());
            metadata.setContentType(file.getContentType());
            metadata.setCacheControl("max-age=31536000"); // 缓存1年
            metadata.setContentDisposition("inline");

            // 上传到OSS
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
     * 上传字节数组到OSS
     * 适用于从内存直接上传的场景（如Base64解码后的数据）
     *
     * @param data        文件字节数据
     * @param fileName    文件名
     * @param directory   OSS目录
     * @param contentType 内容类型
     * @return OSS对象Key
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
     * 上传输入流到OSS
     * 适用于大文件或流式传输场景
     *
     * @param inputStream 输入流
     * @param fileName    文件名
     * @param directory   OSS目录
     * @param contentType 内容类型
     * @return OSS对象Key
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
     * 保存Base64编码的图片到OSS
     * 自动解析Base64前缀并提取图片类型
     *
     * @param base64Data Base64编码的图片数据
     * @return OSS对象Key
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
     * 保存临时文件到本地磁盘
     * 用于AI检测前的文件预处理
     *
     * @param file 待保存的文件
     * @return 临时文件对象
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

    /**
     * 删除临时文件
     *
     * @param file 待删除的文件
     */
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

    /**
     * 批量删除临时文件
     *
     * @param files 待删除的文件列表
     */
    @Override
    public void deleteTempFiles(Iterable<File> files) {
        if (files == null) {
            return;
        }
        for (File file : files) {
            deleteTempFile(file);
        }
    }

    /**
     * 获取文件访问URL
     * 拼接OSS基础URL和相对路径
     *
     * @param relativePath 文件相对路径或完整URL
     * @return 文件访问URL
     */
    @Override
    public String getFileUrl(String relativePath) {
        if (relativePath == null || relativePath.isEmpty()) {
            return null;
        }

        // 如果已经是完整URL，直接返回
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
     * 生成签名URL（带过期时间）
     * 用于私有bucket的文件临时访问
     *
     * @param relativePath  文件相对路径
     * @param expireSeconds 过期时间（秒）
     * @return 签名URL
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

    /**
     * 生成默认过期时间的签名URL
     */
    @Override
    public String getSignedUrl(String relativePath) {
        return getSignedUrl(relativePath, ossProperties.getSignatureExpireSeconds());
    }

    /**
     * 下载文件为字节数组
     *
     * @param relativePath 文件相对路径
     * @return 文件字节数据
     */
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
     * 下载文件为输入流
     * 适用于大文件流式处理
     *
     * @param relativePath 文件相对路径
     * @return 输入流（调用者负责关闭）
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

    /**
     * 删除OSS文件
     *
     * @param relativePath 文件相对路径
     * @return 是否删除成功
     */
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

    /**
     * 检查文件是否存在
     *
     * @param relativePath 文件相对路径
     * @return 是否存在
     */
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
     * 获取文件大小
     *
     * @param relativePath 文件相对路径
     * @return 文件大小（字节），失败返回0
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

    /**
     * 获取存储类型标识
     */
    @Override
    public String getStorageType() {
        return "OSS";
    }

    /**
     * 获取报告目录
     */
    @Override
    public String getReportDir() {
        return REPORT_DIR;
    }

    /**
     * 获取图片目录
     */
    @Override
    public String getImageDir() {
        return IMAGE_DIR;
    }

    /**
     * 获取结果图目录
     */
    @Override
    public String getResultDir() {
        return RESULT_DIR;
    }

    // ==================== 私有方法 ====================

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

    /**
     * 校验图片文件类型
     */
    private void validateImageFile(MultipartFile file) {
        validateFile(file);

        String contentType = file.getContentType();
        if (contentType == null || !ALLOWED_IMAGE_TYPES.contains(contentType.toLowerCase())) {
            throw new BusinessException("文件类型仅支持图片（jpg、png、gif、webp、bmp）");
        }
    }

    /**
     * 校验PDF文件类型
     */
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
        // 如果是完整URL，提取路径部分
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

    /**
     * 生成唯一文件名（UUID）
     */
    private String generateFileName(String extension) {
        return UUID.randomUUID().toString().replace("-", "") + extension;
    }

    /**
     * 获取文件扩展名
     */
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

    /**
     * 根据Content-Type获取文件扩展名
     */
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
