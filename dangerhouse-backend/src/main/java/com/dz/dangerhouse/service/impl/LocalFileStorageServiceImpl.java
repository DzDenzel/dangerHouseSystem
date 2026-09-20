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
 *
 * 当 aliyun.oss.enabled=false 时启用，使用本地文件系统存储文件
 */
@Slf4j
@Service
@ConditionalOnProperty(prefix = "aliyun.oss", name = "enabled", havingValue = "false")
public class LocalFileStorageServiceImpl implements FileStorageService {

    private static final String IMAGE_DIR = "images";

    private static final String RESULT_DIR = "results";

    private static final String REPORT_DIR = "reports";

    private static final String TEMP_DIR = "temp";

    private static final DateTimeFormatter DATE_FORMATTER = DateTimeFormatter.ofPattern("yyyy/MM/dd");

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
            String fileName = generateFileName(getFileExtension(file.getOriginalFilename()));
            String relativePath = buildRelativePath(directory, fileName);
            Path targetPath = buildAbsolutePath(relativePath);
            Files.createDirectories(targetPath.getParent());
            file.transferTo(targetPath.toFile());
            log.info("本地文件上传成功: {}", relativePath);
            return relativePath;
        } catch (IOException e) {
            log.error("本地文件上传失败", e);
            throw new BusinessException("文件上传失败: " + e.getMessage(), e);
        }
    }

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

    @Override
    public String uploadStream(InputStream inputStream, String fileName, String directory, String contentType) {
        if (inputStream == null) throw new BusinessException("输入流不能为空");
        try (InputStream in = inputStream) {
            return uploadBytes(in.readAllBytes(), fileName, directory, contentType);
        } catch (IOException e) {
            throw new BusinessException("文件上传失败: " + e.getMessage(), e);
        }
    }

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

    @Override
    public void deleteTempFile(File file) {
        if (file == null) return;
        try {
            if (file.exists() && !file.delete()) log.warn("删除临时文件失败: {}", file.getAbsolutePath());
        } catch (Exception e) {
            log.warn("删除临时文件异常: {}", file.getAbsolutePath(), e);
        }
    }

    @Override
    public void deleteTempFiles(Iterable<File> files) {
        if (files == null) return;
        for (File file : files) deleteTempFile(file);
    }

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

    @Override
    public String getSignedUrl(String relativePath) {
        return getFileUrl(relativePath);
    }

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

    @Override
    public InputStream downloadStream(String relativePath) {
        byte[] bytes = downloadBytes(relativePath);
        return bytes == null ? null : new ByteArrayInputStream(bytes);
    }

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

    @Override
    public boolean fileExists(String relativePath) {
        if (relativePath == null || relativePath.isEmpty()) return false;
        return Files.exists(buildAbsolutePath(normalizeRelativePath(relativePath)));
    }

    @Override
    public long getFileSize(String relativePath) {
        if (relativePath == null || relativePath.isEmpty()) return 0;
        try {
            return Files.size(buildAbsolutePath(normalizeRelativePath(relativePath)));
        } catch (IOException e) {
            return 0;
        }
    }

    @Override
    public String getStorageType() {
        return "LOCAL";
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

    private void validateFile(MultipartFile file) {
        if (file == null || file.isEmpty()) throw new BusinessException("文件不能为空");
        if (file.getSize() > maxFileSize)
            throw new BusinessException("文件大小不能超过 " + (maxFileSize / 1024 / 1024) + "MB");
    }

    private void validateImageFile(MultipartFile file) {
        validateFile(file);
        String contentType = file.getContentType();
        if (contentType == null || !ALLOWED_IMAGE_TYPES.contains(contentType.toLowerCase(Locale.ROOT)))
            throw new BusinessException("文件类型仅支持图片（jpg、png、gif、webp、bmp）");
    }

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

    private Path buildAbsolutePath(String relativePath) {
        return Paths.get(baseDir, relativePath.replace("/", File.separator));
    }

    private String getFileExtension(String filename) {
        if (filename == null || filename.isEmpty()) return ".jpg";
        int index = filename.lastIndexOf('.');
        if (index == -1 || index == filename.length() - 1) return ".jpg";
        return filename.substring(index);
    }

    private String generateFileName(String extension) {
        return UUID.randomUUID().toString().replace("-", "") + extension;
    }

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
