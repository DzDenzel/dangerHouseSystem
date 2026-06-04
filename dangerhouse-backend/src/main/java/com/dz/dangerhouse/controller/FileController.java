package com.dz.dangerhouse.controller;

import com.dz.dangerhouse.exception.BusinessException;
import com.dz.dangerhouse.util.FileUploadUtil;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.servlet.http.HttpServletResponse;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.io.OutputStream;
import java.net.URLEncoder;
import java.net.URLConnection;
import java.nio.charset.StandardCharsets;

/**
 * 统一文件访问代理，解决 OSS 跨域与附件下载头导致的前端展示问题。
 */
@Slf4j
@RestController
@RequestMapping("/api/files")
@Tag(name = "文件访问", description = "统一文件访问接口")
public class FileController {

    @Autowired
    private FileUploadUtil fileUploadUtil;

    /**
     * 通过后端代理读取文件并以内联方式返回（用于预览）
     *
     * @param path     文件路径
     * @param response HTTP响应
     */
    @GetMapping("/view")
    @Operation(summary = "预览文件", description = "通过后端代理读取文件并以内联方式返回")
    public void viewFile(@RequestParam("path") String path, HttpServletResponse response) {
        try {
            byte[] fileBytes = fileUploadUtil.downloadBytes(path);
            if (fileBytes == null || fileBytes.length == 0) {
                response.setStatus(HttpServletResponse.SC_NOT_FOUND);
                return;
            }

            String contentType = URLConnection.guessContentTypeFromName(path);
            if (contentType == null || contentType.isBlank()) {
                contentType = MediaType.APPLICATION_OCTET_STREAM_VALUE;
            }

            response.setContentType(contentType);
            response.setHeader(HttpHeaders.CACHE_CONTROL, "public, max-age=31536000");
            response.setHeader(HttpHeaders.CONTENT_LENGTH, String.valueOf(fileBytes.length));
            response.setHeader(HttpHeaders.CONTENT_DISPOSITION, "inline; filename=\"" + encodeFileName(path) + "\"");

            try (OutputStream os = response.getOutputStream()) {
                os.write(fileBytes);
                os.flush();
            }
        } catch (BusinessException e) {
            log.warn("文件访问失败: {}", path, e);
            response.setStatus(HttpServletResponse.SC_NOT_FOUND);
        } catch (Exception e) {
            log.error("文件代理读取异常: {}", path, e);
            response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
        }
    }

    /**
     * 编码文件名用于HTTP响应头
     *
     * @param path 文件路径
     * @return 编码后的文件名
     */
    private String encodeFileName(String path) {
        String normalized = path.replace("\\", "/");
        int queryIndex = normalized.indexOf('?');
        if (queryIndex > -1) {
            normalized = normalized.substring(0, queryIndex);
        }
        int lastSlash = normalized.lastIndexOf('/');
        String fileName = lastSlash > -1 ? normalized.substring(lastSlash + 1) : normalized;
        return URLEncoder.encode(fileName, StandardCharsets.UTF_8);
    }
}
