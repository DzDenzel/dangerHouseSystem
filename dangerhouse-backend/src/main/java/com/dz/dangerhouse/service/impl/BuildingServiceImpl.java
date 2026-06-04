package com.dz.dangerhouse.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.dz.dangerhouse.cache.CacheProperties;
import com.dz.dangerhouse.cache.CacheService;
import com.dz.dangerhouse.entity.Building;
import com.dz.dangerhouse.entity.Detection;
import com.dz.dangerhouse.mapper.BuildingMapper;
import com.dz.dangerhouse.mapper.DetectionMapper;
import com.dz.dangerhouse.service.BuildingService;
import com.dz.dangerhouse.service.CurrentUserService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.io.Serializable;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.concurrent.TimeUnit;

/**
 * 建筑服务实现类
 */
@Service
public class BuildingServiceImpl extends ServiceImpl<BuildingMapper, Building> implements BuildingService {

    @Autowired
    private DetectionMapper detectionMapper;

    @Autowired
    private CacheService cacheService;

    @Autowired
    private CacheProperties cacheProperties;

    @Autowired
    private CurrentUserService currentUserService;

    /**
     * 根据 ID 获取建筑（带缓存）
     */
    @Override
    public Building getById(Serializable id) {
        if (!(id instanceof Long buildingId)) {
            return super.getById(id);
        }

        return cacheService.queryWithMutex(
                cacheProperties.buildingDetailKey(buildingId),
                Building.class,
                () -> super.getById(id),
                cacheProperties.getDefaultTtlMinutes(),
                TimeUnit.MINUTES
        );
    }

    /**
     * 保存建筑
     */
    @Override
    public boolean save(Building entity) {
        boolean saved = super.save(entity);
        if (saved) {
            cacheService.delete(cacheProperties.getDashboardKey());
            cacheService.deleteByPrefix(cacheProperties.getBuildingListPrefix());
        }
        return saved;
    }

    /**
     * 更新建筑
     */
    @Override
    public boolean updateById(Building entity) {
        boolean updated = super.updateById(entity);
        if (updated && entity != null && entity.getId() != null) {
            evictBuildingCache(entity.getId());
        }
        return updated;
    }

    /**
     * 删除建筑
     */
    @Override
    public boolean removeById(Serializable id) {
        boolean removed = super.removeById(id);
        if (removed && id instanceof Long buildingId) {
            evictBuildingCache(buildingId);
        }
        return removed;
    }

    /**
     * 分页查询建筑列表（带缓存）
     */
    @Override
    public Page<Building> pageBuildings(Integer pageNum, Integer pageSize, String name, String address,
            String structureType, String ownerName, String riskLevels) {
        Long currentUserId = currentUserService.getCurrentUserId();
        boolean userOnly = currentUserService.hasRole("USER");
        String cacheKey = buildListCacheKey(
                pageNum, pageSize, name, address, structureType, ownerName, riskLevels, currentUserId, userOnly);

        @SuppressWarnings("unchecked")
        Page<Building> result = cacheService.queryWithPassThrough(
                cacheKey,
                Page.class,
                () -> loadBuildingPage(
                        pageNum, pageSize, name, address, structureType, ownerName, riskLevels, currentUserId, userOnly),
                cacheProperties.getDefaultTtlMinutes(),
                TimeUnit.MINUTES
        );
        return result;
    }

    /**
     * 加载建筑分页数据
     */
    private Page<Building> loadBuildingPage(Integer pageNum, Integer pageSize, String name, String address,
            String structureType, String ownerName, String riskLevels, Long currentUserId, boolean userOnly) {
        Page<Building> page = new Page<>(pageNum, pageSize);
        QueryWrapper<Building> wrapper = new QueryWrapper<>();

        wrapper.like(name != null && !name.trim().isEmpty(), "name", name)
                .like(address != null && !address.trim().isEmpty(), "address", address)
                .eq(structureType != null && !structureType.trim().isEmpty(), "structure_type", structureType)
                .like(ownerName != null && !ownerName.trim().isEmpty(), "owner_name", ownerName)
                .eq(userOnly, "owner_user_id", currentUserId)
                .orderByDesc("created_at");

        if (riskLevels != null && !riskLevels.trim().isEmpty()) {
            Set<String> targetLevels = new HashSet<>();
            for (String level : riskLevels.split(",")) {
                targetLevels.add(level.trim().toUpperCase());
            }

            List<Long> buildingIdsWithRisk = findBuildingIdsByRiskLevels(targetLevels, currentUserId, userOnly);
            if (buildingIdsWithRisk.isEmpty()) {
                return new Page<>(pageNum, pageSize);
            }
            wrapper.in("id", buildingIdsWithRisk);
        }

        return this.page(page, wrapper);
    }

    /**
     * 根据风险等级查找建筑 ID
     */
    private List<Long> findBuildingIdsByRiskLevels(Set<String> targetLevels, Long currentUserId, boolean userOnly) {
        List<Long> result = new ArrayList<>();

        QueryWrapper<Detection> detectionWrapper = new QueryWrapper<>();
        detectionWrapper.select("building_id", "risk_level")
                .isNotNull("building_id")
                .eq(userOnly, "user_id", currentUserId);

        List<Detection> detections = detectionMapper.selectList(detectionWrapper);

        java.util.Map<Long, Set<String>> buildingRiskMap = new java.util.HashMap<>();
        for (Detection detection : detections) {
            Long buildingId = detection.getBuildingId();
            String riskLevel = detection.getRiskLevel();
            if (buildingId != null && riskLevel != null) {
                buildingRiskMap.computeIfAbsent(buildingId, key -> new HashSet<>())
                        .add(riskLevel.toUpperCase());
            }
        }

        for (java.util.Map.Entry<Long, Set<String>> entry : buildingRiskMap.entrySet()) {
            for (String level : entry.getValue()) {
                if (targetLevels.contains(level)) {
                    result.add(entry.getKey());
                    break;
                }
            }
        }

        return result;
    }

    /**
     * 根据业主姓名查询建筑
     */
    @Override
    public List<Building> findByOwnerName(String ownerName) {
        return baseMapper.findByOwnerName(ownerName);
    }

    /**
     * 根据地址查询建筑
     */
    @Override
    public List<Building> findByAddress(String address) {
        return baseMapper.findByAddress(address);
    }

    /**
     * 清除建筑缓存
     */
    private void evictBuildingCache(Long buildingId) {
        cacheService.delete(cacheProperties.buildingDetailKey(buildingId));
        cacheService.delete(cacheProperties.getDashboardKey());
        cacheService.deleteByPrefix(cacheProperties.getBuildingListPrefix());
    }

    /**
     * 构建列表缓存键
     */
    private String buildListCacheKey(Integer pageNum, Integer pageSize, String name, String address,
            String structureType,
            String ownerName, String riskLevels, Long currentUserId, boolean userOnly) {
        return cacheProperties.getBuildingListPrefix()
                + safe(pageNum) + ":"
                + safe(pageSize) + ":"
                + safe(name) + ":"
                + safe(address) + ":"
                + safe(structureType) + ":"
                + safe(ownerName) + ":"
                + safe(riskLevels) + ":"
                + safe(currentUserId) + ":"
                + safe(userOnly);
    }

    /**
     * 安全转换对象为字符串
     */
    private String safe(Object value) {
        return value == null ? "_" : String.valueOf(value).trim();
    }
}
