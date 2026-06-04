package com.dz.dangerhouse.dto.response;

import lombok.Data;

/**
 * 管理员仪表盘统计数据
 */
@Data
public class AdminDashboardResponse {
    
    /**
     * 用户总数
     */
    private int userCount;
    
    /**
     * 建筑总数
     */
    private int buildingCount;
    
    /**
     * 检测任务总数
     */
    private int detectionCount;
    
    /**
     * 高风险建筑数量（C级和D级）
     */
    private int highRiskCount;
}