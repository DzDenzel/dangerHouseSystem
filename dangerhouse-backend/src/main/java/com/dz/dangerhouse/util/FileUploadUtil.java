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
 * 包括头像、建筑图片、检测图片、报告等不同类型的文件管理
 */
@Slf4j
@Component
public class FileUploadUtil {

    /**
     * 用户头像目录
     */
    private static final String AVATAR_DIR = "users/avatars";
    
    /**
     * 建筑图片目录
     */
    private static final String BUILDING_IMAGE_DIR = "buildings";
    
    /**
     * 检测任务目录
     */
    private static final String DETECTION_DIR = "detections";
    
    /**
     * 原始图片子目录
     */
    private static final String DETECTION_ORIGINAL_SEGMENT = "original";
    
    /**
     * 结果图片子目录
     */
    private static final String DETECTION_RESULT_SEGMENT = "result";
    
    /**
     * 报告子目录
     */
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

    /**
     * 上传图片文件
     *
     * @param file 图片文件
     * @return 文件相对路径
     */
    public String uploadImage(MultipartFile file) {
        return fileStorageService.uploadImage(file);
    }

    /**
     * 上传检测结果图片
     *
     * @param file 结果图片文件
     * @return 文件相对路径
     */
    public String uploadResultImage(MultipartFile file) {
        return fileStorageService.uploadResultImage(file);
    }

    /**
     * 上传PDF报告文件
     *
     * @param file PDF文件
     * @return 文件相对路径
     */
    public String uploadPdf(MultipartFile file) {
        return fileStorageService.uploadPdf(file);
    }

    /**
     * 上传用户头像
     *
     * @param file 头像文件
     * @param userId 用户ID
     * @return 文件相对路径
     */
    public String uploadAvatar(MultipartFile file, Long userId) {
        return fileStorageService.uploadFile(file, buildUserAvatarDirectory(userId));
    }

    /**
     * 上传建筑图片
     *
     * @param file 建筑图片
     * @param buildingId 建筑ID
     * @return 文件相对路径
     */
    public String uploadBuildingImage(MultipartFile file, Long buildingId) {
        return fileStorageService.uploadFile(file, buildBuildingImageDirectory(buildingId));
    }

    /**
     * 上传检测原始图片
     *
     * @param file 原始图片
     * @param detectionId 检测任务ID
     * @return 文件相对路径
     */
    public String uploadDetectionOriginalImage(MultipartFile file, Long detectionId) {
        return fileStorageService.uploadFile(file, buildDetectionOriginalDirectory(detectionId));
    }

    /**
     * 保存检测结果图片（Base64格式）
     * 自动解析Base64数据并上传到检测结果目录
     *
     * @param base64Data Base64编码的图片数据
     * @param detectionId 检测任务ID
     * @return 文件相对路径
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

    /**
     * 上传报告字节数据
     *
     * @param data 报告字节数据
     * @param fileName 文件名
     * @param detectionId 检测任务ID
     * @param contentType 内容类型
     * @return 文件相对路径
     */
    public String uploadReportBytes(byte[] data, String fileName, Long detectionId, String contentType) {
        return fileStorageService.uploadBytes(data, fileName, buildReportDirectory(detectionId), contentType);
    }

    /**
     * 上传文件到指定子目录
     *
     * @param file 待上传文件
     * @param subDir 子目录
     * @return 文件相对路径
     */
    public String uploadFile(MultipartFile file, String subDir) {
        return fileStorageService.uploadFile(file, subDir);
    }

    /**
     * 上传字节数组
     *
     * @param data 字节数据
     * @param fileName 文件名
     * @param directory 目标目录
     * @param contentType 内容类型
     * @return 文件相对路径
     */
    public String uploadBytes(byte[] data, String fileName, String directory, String contentType) {
        return fileStorageService.uploadBytes(data, fileName, directory, contentType);
    }

    /**
     * 上传输入流
     *
     * @param inputStream 输入流
     * @param fileName 文件名
     * @param directory 目标目录
     * @param contentType 内容类型
     * @return 文件相对路径
     */
    public String uploadStream(InputStream inputStream, String fileName, String directory, String contentType) {
        return fileStorageService.uploadStream(inputStream, fileName, directory, contentType);
    }

    /**
     * 保存Base64图片
     *
     * @param base64Data Base64数据
     * @return 文件相对路径
     */
    public String saveBase64Image(String base64Data) {
        return fileStorageService.saveBase64Image(base64Data);
    }

    /**
     * 保存临时文件
     *
     * @param file 待保存文件
     * @return 临时文件对象
     */
    public File saveTempFile(MultipartFile file) {
        return fileStorageService.saveTempFile(file);
    }

    /**
     * 删除临时文件
     *
     * @param file 待删除文件
     */
    public void deleteTempFile(File file) {
        fileStorageService.deleteTempFile(file);
    }

    /**
     * 批量删除临时文件
     *
     * @param files 待删除文件列表
     */
    public void deleteTempFiles(Iterable<File> files) {
        fileStorageService.deleteTempFiles(files);
    }

    /**
     * 获取文件访问URL
     * 通过API代理方式提供文件访问
     *
     * @param relativePath 文件相对路径
     * @return 文件访问URL
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

    /**
     * 生成签名URL（带过期时间）
     *
     * @param relativePath 文件相对路径
     * @param expireSeconds 过期时间（秒）
     * @return 签名URL
     */
    public String getSignedUrl(String relativePath, long expireSeconds) {
        return fileStorageService.getSignedUrl(relativePath, expireSeconds);
    }

    /**
     * 生成默认过期时间的签名URL
     */
    public String getSignedUrl(String relativePath) {
        return fileStorageService.getSignedUrl(relativePath);
    }

    /**
     * 下载文件为字节数组
     *
     * @param relativePath 文件相对路径
     * @return 文件字节数据
     */
    public byte[] downloadBytes(String relativePath) {
        return fileStorageService.downloadBytes(relativePath);
    }

    /**
     * 下载文件为输入流
     *
     * @param relativePath 文件相对路径
     * @return 输入流
     */
    public InputStream downloadStream(String relativePath) {
        return fileStorageService.downloadStream(relativePath);
    }

    /**
     * 删除文件
     *
     * @param relativePath 文件相对路径
     * @return 是否删除成功
     */
    public boolean deleteFile(String relativePath) {
        return fileStorageService.deleteFile(relativePath);
    }

    /**
     * 检查文件是否存在
     *
     * @param relativePath 文件相对路径
     * @return 是否存在
     */
    public boolean fileExists(String relativePath) {
        return fileStorageService.fileExists(relativePath);
    }

    /**
     * 获取文件大小
     *
     * @param relativePath 文件相对路径
     * @return 文件大小（字节）
     */
    public long getFileSize(String relativePath) {
        return fileStorageService.getFileSize(relativePath);
    }

    /**
     * 获取存储类型
     *
     * @return 存储类型（OSS/LOCAL）
     */
    public String getStorageType() {
        return fileStorageService.getStorageType();
    }

    /**
     * 获取报告目录
     */
    public String getReportDir() {
        return fileStorageService.getReportDir();
    }

    /**
     * 获取图片目录
     */
    public String getImageDir() {
        return fileStorageService.getImageDir();
    }

    /**
     * 获取结果图目录
     */
    public String getResultDir() {
        return fileStorageService.getResultDir();
    }

    /**
     * 解析本地文件的绝对路径
     * 仅适用于本地存储模式
     *
     * @param relativePath 文件相对路径
     * @return 绝对路径
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
     * 获取可读的文件对象
     * 对于本地存储返回本地文件，对于远程存储创建临时文件
     *
     * @param relativePath 文件相对路径
     * @return 文件对象
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

    /**
     * 获取文件后缀名
     */
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

    /**
     * 判断是否为外部未管理的URL
     */
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

    /**
     * 构建用户头像目录
     */
    private String buildUserAvatarDirectory(Long userId) {
        return AVATAR_DIR + "/" + safeId(userId);
    }

    /**
     * 构建建筑图片目录
     */
    private String buildBuildingImageDirectory(Long buildingId) {
        return BUILDING_IMAGE_DIR + "/" + safeId(buildingId) + "/images";
    }

    /**
     * 构建检测原始图片目录
     */
    private String buildDetectionOriginalDirectory(Long detectionId) {
        return DETECTION_DIR + "/" + safeId(detectionId) + "/" + DETECTION_ORIGINAL_SEGMENT;
    }

    /**
     * 构建检测结果图片目录
     */
    private String buildDetectionResultDirectory(Long detectionId) {
        return DETECTION_DIR + "/" + safeId(detectionId) + "/" + DETECTION_RESULT_SEGMENT;
    }

    /**
     * 构建报告目录
     */
    private String buildReportDirectory(Long detectionId) {
        return DETECTION_DIR + "/" + safeId(detectionId) + "/" + REPORT_SEGMENT;
    }

    /**
     * 安全处理ID，为空时返回"common"
     */
    private String safeId(Long id) {
        return id == null ? "common" : String.valueOf(id);
    }

    /**
     * 根据Content-Type获取文件扩展名
     */
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
