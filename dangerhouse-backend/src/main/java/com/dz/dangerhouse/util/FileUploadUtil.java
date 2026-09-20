package com.dz.dangerhouse.util;

import com.dz.dangerhouse.config.AppProperties;
import com.dz.dangerhouse.exception.BusinessException;
import com.dz.dangerhouse.service.FileStorageService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import org.springframework.web.multipart.MultipartFile;

import java.io.File;
import java.io.InputStream;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.Base64;
import java.util.Locale;
import java.util.UUID;

/**
 * 统一文件上传和访问工具类
 * 封装FileStorageService，提供业务层面的文件操作接口
 */
@Slf4j
@Component
public class FileUploadUtil {

    private static final String AVATAR_DIR = "users/avatars";

    private static final String BUILDING_IMAGE_DIR = "buildings";

    private static final String DETECTION_DIR = "detections";

    private static final String DETECTION_ORIGINAL_SEGMENT = "original";

    private static final String DETECTION_RESULT_SEGMENT = "result";

    private static final String REPORT_SEGMENT = "reports";

    @Value("${file.upload.base-dir:D:/dangerhouse/uploads}")
    private String baseDir;

    @Value("${file.upload.url-prefix:/uploads}")
    private String urlPrefix;

    @Value("${server.port:8080}")
    private String serverPort;

    private final FileStorageService fileStorageService;
    private final AppProperties appProperties;

    public FileUploadUtil(FileStorageService fileStorageService, AppProperties appProperties) {
        this.fileStorageService = fileStorageService;
        this.appProperties = appProperties;
    }

    public String uploadImage(MultipartFile file) {
        return fileStorageService.uploadImage(file);
    }

    public String uploadResultImage(MultipartFile file) {
        return fileStorageService.uploadResultImage(file);
    }

    public String uploadPdf(MultipartFile file) {
        return fileStorageService.uploadPdf(file);
    }

    public String uploadAvatar(MultipartFile file, Long userId) {
        return fileStorageService.uploadFile(file, buildUserAvatarDirectory(userId));
    }

    public String uploadBuildingImage(MultipartFile file, Long buildingId) {
        return fileStorageService.uploadFile(file, buildBuildingImageDirectory(buildingId));
    }

    public String uploadDetectionOriginalImage(MultipartFile file, Long detectionId) {
        return fileStorageService.uploadFile(file, buildDetectionOriginalDirectory(detectionId));
    }

    /**
     * 自动解析Base64数据并上传到检测结果目录
     */
    public String saveDetectionResultImage(String base64Data, Long detectionId) {
        if (base64Data == null || base64Data.isEmpty()) {
            return null;
        }

        try {
            String pureBase64 = base64Data;
            String contentType = "image/jpeg";
            if (base64Data.contains(",")) {
                String[] parts = base64Data.split(",", 2);
                String prefix = parts[0];
                pureBase64 = parts[1];
                if (prefix.contains("image/")) {
                    int start = prefix.indexOf("image/");
                    int end = prefix.indexOf(";", start);
                    if (end > start) {
                        contentType = prefix.substring(start, end);
                    }
                }
            }

            byte[] imageBytes = Base64.getDecoder().decode(pureBase64);
            String extension = getExtensionFromContentType(contentType);
            String fileName = UUID.randomUUID().toString().replace("-", "") + extension;
            return fileStorageService.uploadBytes(
                    imageBytes,
                    fileName,
                    buildDetectionResultDirectory(detectionId),
                    contentType);
        } catch (Exception e) {
            throw new BusinessException("Failed to save detection result image: " + e.getMessage(), e);
        }
    }

    public String uploadReportBytes(byte[] data, String fileName, Long detectionId, String contentType) {
        return fileStorageService.uploadBytes(data, fileName, buildReportDirectory(detectionId), contentType);
    }

    public String uploadFile(MultipartFile file, String subDir) {
        return fileStorageService.uploadFile(file, subDir);
    }

    public String uploadBytes(byte[] data, String fileName, String directory, String contentType) {
        return fileStorageService.uploadBytes(data, fileName, directory, contentType);
    }

    public String uploadStream(InputStream inputStream, String fileName, String directory, String contentType) {
        return fileStorageService.uploadStream(inputStream, fileName, directory, contentType);
    }

    public String saveBase64Image(String base64Data) {
        return fileStorageService.saveBase64Image(base64Data);
    }

    public File saveTempFile(MultipartFile file) {
        return fileStorageService.saveTempFile(file);
    }

    public void deleteTempFile(File file) {
        fileStorageService.deleteTempFile(file);
    }

    public void deleteTempFiles(Iterable<File> files) {
        fileStorageService.deleteTempFiles(files);
    }

    /**
     * 通过API代理方式提供文件访问
     */
    public String getFileUrl(String relativePath) {
        if (relativePath == null || relativePath.isEmpty()) {
            return null;
        }

        if (isExternalUnmanagedUrl(relativePath)) {
            return relativePath;
        }

        String encodedPath = URLEncoder.encode(relativePath, StandardCharsets.UTF_8);
        return buildPublicBaseUrl() + "/api/files/view?path=" + encodedPath;
    }

    public String getSignedUrl(String relativePath, long expireSeconds) {
        return fileStorageService.getSignedUrl(relativePath, expireSeconds);
    }

    public String getSignedUrl(String relativePath) {
        return fileStorageService.getSignedUrl(relativePath);
    }

    public byte[] downloadBytes(String relativePath) {
        return fileStorageService.downloadBytes(relativePath);
    }

    public InputStream downloadStream(String relativePath) {
        return fileStorageService.downloadStream(relativePath);
    }

    public boolean deleteFile(String relativePath) {
        return fileStorageService.deleteFile(relativePath);
    }

    public boolean fileExists(String relativePath) {
        return fileStorageService.fileExists(relativePath);
    }

    public long getFileSize(String relativePath) {
        return fileStorageService.getFileSize(relativePath);
    }

    public String getStorageType() {
        return fileStorageService.getStorageType();
    }

    public String getReportDir() {
        return fileStorageService.getReportDir();
    }

    public String getImageDir() {
        return fileStorageService.getImageDir();
    }

    public String getResultDir() {
        return fileStorageService.getResultDir();
    }

    /**
     * 仅适用于本地存储模式，其他存储类型返回 null
     */
    public String getAbsolutePath(String relativePath) {
        if (relativePath == null || relativePath.isEmpty()) {
            return null;
        }
        if (!"LOCAL".equalsIgnoreCase(fileStorageService.getStorageType())) {
            log.warn("Storage type {} does not support absolute local paths: {}", fileStorageService.getStorageType(), relativePath);
            return null;
        }
        String normalized = normalizeLocalRelativePath(relativePath);
        return Paths.get(baseDir, normalized).toString();
    }

    /**
     * 对于本地存储返回本地文件，对于远程存储下载为临时文件（进程退出时删除）
     */
    public File getFile(String relativePath) {
        if (relativePath == null || relativePath.isEmpty()) {
            return null;
        }

        if ("LOCAL".equalsIgnoreCase(fileStorageService.getStorageType())) {
            String absolutePath = getAbsolutePath(relativePath);
            return absolutePath == null ? null : new File(absolutePath);
        }

        try {
            byte[] data = fileStorageService.downloadBytes(relativePath);
            if (data == null || data.length == 0) {
                return null;
            }
            Path tempPath = Files.createTempFile("dangerhouse-", getFileSuffix(relativePath));
            Files.write(tempPath, data);
            File tempFile = tempPath.toFile();
            tempFile.deleteOnExit();
            return tempFile;
        } catch (Exception e) {
            log.error("Failed to resolve file from remote storage: {}", relativePath, e);
            throw new BusinessException("Failed to read file: " + e.getMessage(), e);
        }
    }

    /**
     * 标准化本地相对路径
     * 去除URL前缀和前导斜杠
     */
    private String normalizeLocalRelativePath(String path) {
        String normalized = path;
        if (normalized.startsWith(urlPrefix + "/")) {
            normalized = normalized.substring((urlPrefix + "/").length());
        }
        if (normalized.startsWith("/")) {
            normalized = normalized.substring(1);
        }
        return normalized.replace("\\", "/");
    }

    private String getFileSuffix(String relativePath) {
        String normalized = relativePath.replace("\\", "/");
        int queryIndex = normalized.indexOf('?');
        if (queryIndex > -1) {
            normalized = normalized.substring(0, queryIndex);
        }
        int dotIndex = normalized.lastIndexOf('.');
        if (dotIndex == -1 || dotIndex == normalized.length() - 1) {
            return ".tmp";
        }
        return normalized.substring(dotIndex).toLowerCase(Locale.ROOT);
    }

    private boolean isExternalUnmanagedUrl(String path) {
        if (!(path.startsWith("http://") || path.startsWith("https://"))) {
            return false;
        }
        String managedUrl = fileStorageService.getFileUrl(path);
        return path.equals(managedUrl) && !path.contains("/uploads/") && !path.contains(".oss-");
    }

    /**
     * 构建公共基础URL
     * 优先使用配置的baseUrl，否则使用localhost
     */
    private String buildPublicBaseUrl() {
        String configuredBaseUrl = appProperties.getBaseUrl();
        if (configuredBaseUrl != null && !configuredBaseUrl.isBlank()) {
            return trimTrailingSlash(configuredBaseUrl);
        }
        return "http://localhost:" + serverPort;
    }

    /**
     * 去除URL末尾的斜杠
     */
    private String trimTrailingSlash(String url) {
        return url.endsWith("/") ? url.substring(0, url.length() - 1) : url;
    }

    private String buildUserAvatarDirectory(Long userId) {
        return AVATAR_DIR + "/" + safeId(userId);
    }

    private String buildBuildingImageDirectory(Long buildingId) {
        return BUILDING_IMAGE_DIR + "/" + safeId(buildingId) + "/images";
    }

    private String buildDetectionOriginalDirectory(Long detectionId) {
        return DETECTION_DIR + "/" + safeId(detectionId) + "/" + DETECTION_ORIGINAL_SEGMENT;
    }

    private String buildDetectionResultDirectory(Long detectionId) {
        return DETECTION_DIR + "/" + safeId(detectionId) + "/" + DETECTION_RESULT_SEGMENT;
    }

    private String buildReportDirectory(Long detectionId) {
        return DETECTION_DIR + "/" + safeId(detectionId) + "/" + REPORT_SEGMENT;
    }

    /**
     * ID 为空时返回 "common"
     */
    private String safeId(Long id) {
        return id == null ? "common" : String.valueOf(id);
    }

    private String getExtensionFromContentType(String contentType) {
        if (contentType == null) {
            return ".jpg";
        }
        switch (contentType.toLowerCase(Locale.ROOT)) {
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
