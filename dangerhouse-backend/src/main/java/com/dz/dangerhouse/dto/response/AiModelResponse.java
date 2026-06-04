package com.dz.dangerhouse.dto.response;

import lombok.Data;

/**
 * AI 模型信息响应
 */
@Data
public class AiModelResponse {
    
    /**
     * 模型名称
     */
    private String name;
    
    /**
     * 模型描述
     */
    private String description;
    
    /**
     * 模型状态
     */
    private String status;
}