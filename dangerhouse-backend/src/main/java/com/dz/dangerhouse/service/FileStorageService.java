package com.dz.dangerhouse.service;

import org.springframework.web.multipart.MultipartFile;

import java.io.File;
import java.io.InputStream;

/**
 * 文件存储服务接口
 *
 * 提供统一的文件存储抽象，支持多种存储后端实现
 * 如：本地存储、阿里云OSS、腾讯云COS等
 *
 * @author dangerhouse
 */
public interface FileStorageService {

    /**
     * 上传图片文件
     *
     * @param file 图片文件
     * @return 文件相对路径或URL
     */
    String uploadImage(MultipartFile file);

    /**
     * 上传检测结果图片
     *
     * @param file 图片文件
     * @return 文件相对路径或URL
     */
    String uploadResultImage(MultipartFile file);

    /**
     * 上传PDF报告文件
     *
     * @param file PDF文件
     * @return 文件相对路径或URL
     */
    String uploadPdf(MultipartFile file);

    /**
     * 上传文件到指定目录
     *
     * @param file 文件
     * @param directory 目录名称（如：images、reports）
     * @return 文件相对路径或URL
     */
    String uploadFile(MultipartFile file, String directory);

    /**
     * 上传字节数组
     *
     * @param data 文件字节数据
     * @param fileName 文件名
     * @param directory 目录名称
     * @param contentType 内容类型
     * @return 文件相对路径或URL
     */
    String uploadBytes(byte[] data, String fileName, String directory, String contentType);

    /**
     * 上传输入流
     *
     * @param inputStream 输入流
     * @param fileName 文件名
     * @param directory 目录名称
     * @param contentType 内容类型
     * @return 文件相对路径或URL
     */
    String uploadStream(InputStream inputStream, String fileName, String directory, String contentType);

    /**
     * 保存Base64图片
     *
     * @param base64Data Base64编码的图片数据
     * @return 文件相对路径或URL
     */
    String saveBase64Image(String base64Data);

    /**
     * 保存临时文件（用于处理过程中的临时存储）
     *
     * @param file 文件
     * @return 临时文件对象
     */
    File saveTempFile(MultipartFile file);

    /**
     * 删除临时文件
     *
     * @param file 临时文件
     */
    void deleteTempFile(File file);

    /**
     * 批量删除临时文件
     *
     * @param files 临时文件集合
     */
    void deleteTempFiles(Iterable<File> files);

    /**
     * 获取文件访问URL
     *
     * @param relativePath 文件相对路径
     * @return 访问URL
     */
    String getFileUrl(String relativePath);

    /**
     * 获取带签名的临时访问URL（用于私有文件）
     *
     * @param relativePath 文件相对路径
     * @param expireSeconds 过期时间（秒）
     * @return 签名URL
     */
    String getSignedUrl(String relativePath, long expireSeconds);

    /**
     * 获取默认过期时间的签名URL
     *
     * @param relativePath 文件相对路径
     * @return 签名URL
     */
    String getSignedUrl(String relativePath);

    /**
     * 下载文件为字节数组
     *
     * @param relativePath 文件相对路径
     * @return 文件字节数据
     */
    byte[] downloadBytes(String relativePath);

    /**
     * 下载文件为输入流
     *
     * @param relativePath 文件相对路径
     * @return 输入流
     */
    InputStream downloadStream(String relativePath);

    /**
     * 删除文件
     *
     * @param relativePath 文件相对路径
     * @return 是否删除成功
     */
    boolean deleteFile(String relativePath);

    /**
     * 检查文件是否存在
     *
     * @param relativePath 文件相对路径
     * @return 是否存在
     */
    boolean fileExists(String relativePath);

    /**
     * 获取文件大小
     *
     * @param relativePath 文件相对路径
     * @return 文件大小（字节）
     */
    long getFileSize(String relativePath);

    /**
     * 获取存储服务名称
     *
     * @return 存储服务名称（如：OSS、LOCAL）
     */
    String getStorageType();

    /**
     * 获取报告存储目录
     *
     * @return 目录名称
     */
    String getReportDir();

    /**
     * 获取图片存储目录
     *
     * @return 目录名称
     */
    String getImageDir();

    /**
     * 获取检测结果存储目录
     *
     * @return 目录名称
     */
    String getResultDir();
}
