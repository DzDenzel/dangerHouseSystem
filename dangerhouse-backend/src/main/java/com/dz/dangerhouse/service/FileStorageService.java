package com.dz.dangerhouse.service;

import org.springframework.web.multipart.MultipartFile;

import java.io.File;
import java.io.InputStream;

/**
 * 文件存储服务接口
 *
 * 本地存储与阿里云OSS两套实现，由配置项 aliyun.oss.enabled 决定装配哪一个
 *
 * @author dangerhouse
 */
public interface FileStorageService {

    String uploadImage(MultipartFile file);

    String uploadResultImage(MultipartFile file);

    String uploadPdf(MultipartFile file);

    /**
     * @param directory 目录名称（如：images、reports）
     */
    String uploadFile(MultipartFile file, String directory);

    String uploadBytes(byte[] data, String fileName, String directory, String contentType);

    String uploadStream(InputStream inputStream, String fileName, String directory, String contentType);

    String saveBase64Image(String base64Data);

    /**
     * 保存临时文件（用于处理过程中的临时存储）
     */
    File saveTempFile(MultipartFile file);

    void deleteTempFile(File file);

    void deleteTempFiles(Iterable<File> files);

    String getFileUrl(String relativePath);

    /**
     * 获取带签名的临时访问URL（用于私有文件）
     */
    String getSignedUrl(String relativePath, long expireSeconds);

    String getSignedUrl(String relativePath);

    byte[] downloadBytes(String relativePath);

    /**
     * 下载文件为输入流（调用者负责关闭）
     */
    InputStream downloadStream(String relativePath);

    boolean deleteFile(String relativePath);

    boolean fileExists(String relativePath);

    /**
     * @return 文件大小（字节）
     */
    long getFileSize(String relativePath);

    /**
     * @return 存储服务名称（如：OSS、LOCAL）
     */
    String getStorageType();

    String getReportDir();

    String getImageDir();

    String getResultDir();
}
