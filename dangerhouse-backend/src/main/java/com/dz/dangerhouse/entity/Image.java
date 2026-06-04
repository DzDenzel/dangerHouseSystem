package com.dz.dangerhouse.entity;

import com.baomidou.mybatisplus.annotation.*;
import lombok.Data;
import java.time.LocalDateTime;

/**
 * 检测图片表实体
 */
@Data
@TableName("image")
public class Image {

    /**
     * 图片 ID
     */
    @TableId(type = IdType.AUTO)
    private Long id;

    /**
     * 检测记录ID
     */
    private Long detectionId;

    /**
     * 原始图片路径
     */
    private String imagePath;

    /**
     * 检测结果图片路径
     */
    private String resultImagePath;

    /**
     * 图片类型 (ORIGINAL-原图，RESULT-结果图)
     */
    private String imageType;

    /**
     * 上传时间
     */
    @TableField(fill = FieldFill.INSERT)
    private LocalDateTime uploadTime;

}
