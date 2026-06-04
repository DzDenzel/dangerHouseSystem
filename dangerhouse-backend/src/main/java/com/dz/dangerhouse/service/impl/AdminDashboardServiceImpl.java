package com.dz.dangerhouse.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.dz.dangerhouse.cache.CacheProperties;
import com.dz.dangerhouse.cache.CacheService;
import com.dz.dangerhouse.dto.response.AdminDashboardResponse;
import com.dz.dangerhouse.dto.response.AiModelResponse;
import com.dz.dangerhouse.entity.Detection;
import com.dz.dangerhouse.entity.User;
import com.dz.dangerhouse.mapper.BuildingMapper;
import com.dz.dangerhouse.mapper.DetectionMapper;
import com.dz.dangerhouse.mapper.UserMapper;
import com.dz.dangerhouse.service.AdminDashboardService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.TimeUnit;

/**
 * 管理后台仪表盘服务实现
 */
@Service
public class AdminDashboardServiceImpl implements AdminDashboardService {

    @Autowired
    private UserMapper userMapper;

    @Autowired
    private BuildingMapper buildingMapper;

    @Autowired
    private DetectionMapper detectionMapper;

    @Autowired
    private CacheService cacheService;

    @Autowired
    private CacheProperties cacheProperties;

    /**
     * 获取仪表盘统计数据（带缓存）
     */
    @Override
    public AdminDashboardResponse getDashboard() {
        return cacheService.queryWithMutex(
                cacheProperties.getDashboardKey(),
                AdminDashboardResponse.class,
                this::buildDashboardResponse,
                cacheProperties.getDashboardTtlMinutes(),
                TimeUnit.MINUTES
        );
    }

    /**
     * 构建仪表盘响应数据
     */
    private AdminDashboardResponse buildDashboardResponse() {
        AdminDashboardResponse response = new AdminDashboardResponse();

        Long userCount = userMapper.selectCount(null);
        response.setUserCount(userCount != null ? userCount.intValue() : 0);

        Long buildingCount = buildingMapper.selectCount(null);
        response.setBuildingCount(buildingCount != null ? buildingCount.intValue() : 0);

        Long detectionCount = detectionMapper.selectCount(null);
        response.setDetectionCount(detectionCount != null ? detectionCount.intValue() : 0);

        // 统计高风险建筑数量（C级和D级）
        Long cLevelCount = detectionMapper.selectCount(new LambdaQueryWrapper<Detection>()
                .eq(Detection::getRiskLevel, "C"));
        Long dLevelCount = detectionMapper.selectCount(new LambdaQueryWrapper<Detection>()
                .eq(Detection::getRiskLevel, "D"));
        int totalHighRisk = (cLevelCount != null ? cLevelCount.intValue() : 0)
                + (dLevelCount != null ? dLevelCount.intValue() : 0);
        response.setHighRiskCount(totalHighRisk);

        return response;
    }

    /**
     * 获取AI模型列表
     */
    @Override
    public List<AiModelResponse> getModelList() {
        List<AiModelResponse> models = new ArrayList<>();

        AiModelResponse model1 = new AiModelResponse();
        model1.setName("crack_detection_v1");
        model1.setDescription("墙体裂缝检测模型 V1");
        model1.setStatus("ACTIVE");
        models.add(model1);

        AiModelResponse model2 = new AiModelResponse();
        model2.setName("roof_damage_v1");
        model2.setDescription("屋顶损伤检测模型 V1");
        model2.setStatus("ACTIVE");
        models.add(model2);

        AiModelResponse model3 = new AiModelResponse();
        model3.setName("structural_assessment_v1");
        model3.setDescription("结构安全评估模型 V1");
        model3.setStatus("MAINTENANCE");
        models.add(model3);

        return models;
    }
}
