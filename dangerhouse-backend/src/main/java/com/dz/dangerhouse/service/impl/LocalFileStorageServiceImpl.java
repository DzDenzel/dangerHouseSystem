package com.dz.dangerhouse.service.impl;

import com.dz.dangerhouse.exception.BusinessException;
import com.dz.dangerhouse.service.FileStorageService;
import jakarta.annotation.PostConstruct;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.*;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.*;

/**
 * 本地文件存储服务实现
 * 当aliyun.oss.enabled=false时启用，使用本地文件系统存储文件
 * <p>
 * 提供功能：
 * - 文件上传（图片、PDF）
 * - 文件下载
 * - 文件删除
 * - 文件校验
 * - 临时文件管理
 */
@Slf4j
@Service
@ConditionalOnProperty(prefix = "aliyun.oss", name = "enabled", havingValue = "false")
public class LocalFileStorageServiceImpl implements FileStorageService {

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
    private static final Set<String> ALLOWED_IMAGE_TYPES = new HashSet<String>() {
        @Serial
        private static final long serialVersionUID = 5487236665013349756L;

        {
            add("image/jpeg");
            add("image/jpg");
            add("image/png");
            add("image/gif");
            add("image/webp");
            add("image/bmp");
        }
    };

    /**
     * 允许的PDF类型
     */
    private static final Set<String> ALLOWED_PDF_TYPES = new HashSet<String>() {
        @Serial
        private static final long serialVersionUID = 2128851390154883227L;

        {
            add("application/pdf");
        }
    };

    @Value("${file.upload.base-dir:uploads}")
    private String baseDir;

    @Value("${file.upload.url-prefix:/uploads}")
    private String urlPrefix;

    @Value("${aliyun.oss.max-file-size:10485760}")
    private long maxFileSize;

    /**
     * 初始化时将相对路径转换为基于项目根目录的绝对路径
     */
    @PostConstruct
    public void init() {
        if (baseDir != null && !baseDir.isEmpty()) {
            java.io.File dir = new java.io.File(baseDir);
            if (!dir.isAbsolute()) {
                String projectRoot = System.getProperty("user.dir");
                baseDir = new java.io.File(projectRoot, baseDir).getAbsolutePath();
            }
            log.info("本地存储根目录: {}", baseDir);
        }
    }

    /**
     * 上传图片文件
     */
    @Override
    public String uploadImage(MultipartFile file) {
        validateImageFile(file);
        return uploadFile(file, IMAGE_DIR);
    }

    /**
     * 上传检测结果图片
     */
    @Override
    public String uploadResultImage(MultipartFile file) {
        validateImageFile(file);
        return uploadFile(file, RESULT_DIR);
    }

    /**
     * 上传PDF报告文件
     */
    @Override
    public String uploadPdf(MultipartFile file) {
        validatePdfFile(file);
        return uploadFile(file, REPORT_DIR);
    }

    /**
     * 通用文件上传方法
     * 将文件保存到本地指定目录
     *
     * @param file      待上传文件
     * @param directory 目标目录
     * @return 文件相对路径
     */
    @Override
    public String uploadFile(MultipartFile file, String directory) {
        validateFile(file);
        try {
            // 生成文件名
            String fileName = generateFileName(getFileExtension(file.getOriginalFilename()));
            // 构建相对路径（包含日期）
            String relativePath = buildRelativePath(directory, fileName);
            // 构建绝对路径
            Path targetPath = buildAbsolutePath(relativePath);
            // 创建目标目录
            Files.createDirectories(targetPath.getParent());
            // 保存文件
            file.transferTo(targetPath.toFile());
            log.info("本地文件上传成功: {}", relativePath);
            return relativePath;
        } catch (IOException e) {
            log.error("本地文件上传失败", e);
            throw new BusinessException("文件上传失败: " + e.getMessage(), e);
        }
    }

    /**
     * 上传字节数组到本地文件
     *
     * @param data        文件字节数据
     * @param fileName    文件名
     * @param directory   目标目录
     * @param contentType 内容类型
     * @return 文件相对路径
     */
    @Override
    public String uploadBytes(byte[] data, String fileName, String directory, String contentType) {
        if (data == null || data.length == 0) throw new BusinessException("文件数据不能为空");
        String finalName = fileName == null || fileName.isEmpty() ? generateFileName(".bin") : fileName;
        String relativePath = buildRelativePath(directory, finalName);
        try {
            Path targetPath = buildAbsolutePath(relativePath);
            Files.createDirectories(targetPath.getParent());
            Files.write(targetPath, data);
            log.info("本地字节数据上传成功: {}", relativePath);
            return relativePath;
        } catch (IOException e) {
            log.error("本地字节数据上传失败", e);
            throw new BusinessException("文件上传失败: " + e.getMessage(), e);
        }
    }

    /**
     * 上传输入流到本地文件
     *
     * @param inputStream 输入流
     * @param fileName    文件名
     * @param directory   目标目录
     * @param contentType 内容类型
     * @return 文件相对路径
     */
    @Override
    public String uploadStream(InputStream inputStream, String fileName, String directory, String contentType) {
        if (inputStream == null) throw new BusinessException("输入流不能为空");
        try (InputStream in = inputStream) {
            return uploadBytes(in.readAllBytes(), fileName, directory, contentType);
        } catch (IOException e) {
            throw new BusinessException("文件上传失败: " + e.getMessage(), e);
        }
    }

    /**
     * 保存Base64编码的图片
     *
     * @param base64Data Base64数据
     * @return 文件相对路径
     */
    @Override
    public String saveBase64Image(String base64Data) {
        if (base64Data == null || base64Data.isEmpty()) return null;
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
                    if (end > start) contentType = prefix.substring(start, end);
                }
            }
            byte[] imageBytes = Base64.getDecoder().decode(pureBase64);
            String fileName = generateFileName(getExtensionFromContentType(contentType));
            return uploadBytes(imageBytes, fileName, RESULT_DIR, contentType);
        } catch (Exception e) {
            throw new BusinessException("Base64 图片保存失败: " + e.getMessage(), e);
        }
    }

    /**
     * 保存临时文件
     *
     * @param file 待保存文件
     * @return 临时文件对象
     */
    @Override
    public File saveTempFile(MultipartFile file) {
        validateFile(file);
        try {
            String fileName = generateFileName(getFileExtension(file.getOriginalFilename()));
            String datePath = LocalDateTime.now().format(DATE_FORMATTER);
            Path targetDir = Paths.get(baseDir, TEMP_DIR, datePath);
            Path targetPath = targetDir.resolve(fileName);
            Files.createDirectories(targetDir);
            file.transferTo(targetPath.toFile());
            return targetPath.toFile();
        } catch (IOException e) {
            throw new BusinessException("保存临时文件失败: " + e.getMessage(), e);
        }
    }

    /**
     * 删除临时文件
     */
    @Override
    public void deleteTempFile(File file) {
        if (file == null) return;
        try {
            if (file.exists() && !file.delete()) log.warn("删除临时文件失败: {}", file.getAbsolutePath());
        } catch (Exception e) {
            log.warn("删除临时文件异常: {}", file.getAbsolutePath(), e);
        }
    }

    /**
     * 批量删除临时文件
     */
    @Override
    public void deleteTempFiles(Iterable<File> files) {
        if (files == null) return;
        for (File file : files) deleteTempFile(file);
    }

    /**
     * 获取文件访问URL
     * 拼接URL前缀和相对路径
     */
    @Override
    public String getFileUrl(String relativePath) {
        if (relativePath == null || relativePath.isEmpty()) return null;
        if (relativePath.startsWith("http://") || relativePath.startsWith("https://")) return relativePath;
        String path = normalizeRelativePath(relativePath);
        return urlPrefix + "/" + path;
    }

    /**
     * 生成签名URL（本地存储不支持，直接返回普通URL）
     */
    @Override
    public String getSignedUrl(String relativePath, long expireSeconds) {
        return getFileUrl(relativePath);
    }

    /**
     * 生成默认签名URL
     */
    @Override
    public String getSignedUrl(String relativePath) {
        return getFileUrl(relativePath);
    }

    /**
     * 下载文件为字节数组
     */
    @Override
    public byte[] downloadBytes(String relativePath) {
        if (relativePath == null || relativePath.isEmpty()) return null;
        String normalized = normalizeRelativePath(relativePath);
        try {
            return Files.readAllBytes(buildAbsolutePath(normalized));
        } catch (IOException e) {
            throw new BusinessException("文件下载失败: " + e.getMessage(), e);
        }
    }

    /**
     * 下载文件为输入流
     */
    @Override
    public InputStream downloadStream(String relativePath) {
        byte[] bytes = downloadBytes(relativePath);
        return bytes == null ? null : new ByteArrayInputStream(bytes);
    }

    /**
     * 删除本地文件
     */
    @Override
    public boolean deleteFile(String relativePath) {
        if (relativePath == null || relativePath.isEmpty()) return false;
        try {
            return Files.deleteIfExists(buildAbsolutePath(normalizeRelativePath(relativePath)));
        } catch (IOException e) {
            log.error("删除本地文件失败: {}", relativePath, e);
            return false;
        }
    }

    /**
     * 检查文件是否存在
     */
    @Override
    public boolean fileExists(String relativePath) {
        if (relativePath == null || relativePath.isEmpty()) return false;
        return Files.exists(buildAbsolutePath(normalizeRelativePath(relativePath)));
    }

    /**
     * 获取文件大小
     */
    @Override
    public long getFileSize(String relativePath) {
        if (relativePath == null || relativePath.isEmpty()) return 0;
        try {
            return Files.size(buildAbsolutePath(normalizeRelativePath(relativePath)));
        } catch (IOException e) {
            return 0;
        }
    }

    /**
     * 获取存储类型标识
     */
    @Override
    public String getStorageType() {
        return "LOCAL";
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

    /**
     * 校验文件基本信息
     */
    private void validateFile(MultipartFile file) {
        if (file == null || file.isEmpty()) throw new BusinessException("文件不能为空");
        if (file.getSize() > maxFileSize)
            throw new BusinessException("文件大小不能超过 " + (maxFileSize / 1024 / 1024) + "MB");
    }

    /**
     * 校验图片文件类型
     */
    private void validateImageFile(MultipartFile file) {
        validateFile(file);
        String contentType = file.getContentType();
        if (contentType == null || !ALLOWED_IMAGE_TYPES.contains(contentType.toLowerCase(Locale.ROOT)))
            throw new BusinessException("文件类型仅支持图片（jpg、png、gif、webp、bmp）");
    }

    /**
     * 校验PDF文件类型
     */
    private void validatePdfFile(MultipartFile file) {
        validateFile(file);
        String contentType = file.getContentType();
        if (contentType == null || !ALLOWED_PDF_TYPES.contains(contentType.toLowerCase(Locale.ROOT)))
            throw new BusinessException("文件类型仅支持 PDF");
    }

    /**
     * 构建相对路径（包含日期）
     * 格式：directory/yyyy/MM/dd/filename
     */
    private String buildRelativePath(String directory, String fileName) {
        String datePath = LocalDateTime.now().format(DATE_FORMATTER);
        return directory + "/" + datePath + "/" + fileName;
    }

    /**
     * 构建绝对路径
     */
    private Path buildAbsolutePath(String relativePath) {
        return Paths.get(baseDir, relativePath.replace("/", File.separator));
    }

    /**
     * 获取文件扩展名
     */
    private String getFileExtension(String filename) {
        if (filename == null || filename.isEmpty()) return ".jpg";
        int index = filename.lastIndexOf('.');
        if (index == -1 || index == filename.length() - 1) return ".jpg";
        return filename.substring(index);
    }

    /**
     * 生成唯一文件名（UUID）
     */
    private String generateFileName(String extension) {
        return UUID.randomUUID().toString().replace("-", "") + extension;
    }

    /**
     * 根据Content-Type获取扩展名
     */
    private String getExtensionFromContentType(String contentType) {
        if (contentType == null) return ".jpg";
        switch (contentType.toLowerCase(Locale.ROOT)) {
            case "image/png":
                return ".png";
            case "image/gif":
                return ".gif";
            case "image/webp":
                return ".webp";
            case "image/bmp":
                return ".bmp";
            default:
                return ".jpg";
        }
    }

    /**
     * 标准化相对路径
     * 去除URL前缀和前导斜杠
     */
    private String normalizeRelativePath(String relativePath) {
        String normalized = relativePath;
        if (normalized.startsWith("http://") || normalized.startsWith("https://")) {
            int idx = normalized.indexOf(urlPrefix + "/");
            if (idx >= 0) normalized = normalized.substring(idx + (urlPrefix + "/").length());
        }
        if (normalized.startsWith(urlPrefix + "/")) normalized = normalized.substring((urlPrefix + "/").length());
        if (normalized.startsWith("/")) normalized = normalized.substring(1);
        return normalized;
    }
}
