package com.dz.dangerhouse.entity;

import com.baomidou.mybatisplus.annotation.*;
import lombok.Data;
import java.time.LocalDateTime;

/**
 * 检测报告表实体
 */
@Data
@TableName("report")
public class Report {

    /**
     * 报告ID
     */
    @TableId(type = IdType.AUTO)
    private Long id;

    /**
     * 检测记录ID
     */
    private Long detectionId;

    /**
     * 建筑ID
     */
    private Long buildingId;

    /**
     * 报告编号
     */
    private String reportNo;

    /**
     * 报告文件路径
     */
    private String filePath;

    /**
     * 文件类型(PDF/WORD)
     */
    private String fileType;

    /**
     * 生成时间
     */
    private LocalDateTime generatedAt;

}
