package com.dz.dangerhouse.service;

import com.dz.dangerhouse.dto.response.AdminDashboardResponse;
import com.dz.dangerhouse.dto.response.AiModelResponse;

import java.util.List;

/**
 * 管理员仪表盘服务
 */
public interface AdminDashboardService {
    
    /**
     * 获取仪表盘统计数据
     *
     * @return 仪表盘数据响应
     */
    AdminDashboardResponse getDashboard();

    /**
     * 获取AI模型列表
     *
     * @return AI模型列表
     */
    List<AiModelResponse> getModelList();
}
