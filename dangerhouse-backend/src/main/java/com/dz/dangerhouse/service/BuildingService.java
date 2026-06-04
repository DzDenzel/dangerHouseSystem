package com.dz.dangerhouse.service;

import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.baomidou.mybatisplus.extension.service.IService;
import com.dz.dangerhouse.entity.Building;

import java.util.List;

/**
 * 建筑档案服务接口
 */
public interface BuildingService extends IService<Building> {

    /**
     * 分页查询建筑列表
     * @param pageNum 页码
     * @param pageSize 每页数量
     * @param name 建筑名称
     * @param address 地址
     * @param ownerName 业主姓名
     * @param riskLevels 风险等级过滤（逗号分隔）
     * @return 分页结果
     */
    Page<Building> pageBuildings(
            Integer pageNum,
            Integer pageSize,
            String name,
            String address,
            String structureType,
            String ownerName,
            String riskLevels
    );

    /**
     * 根据业主姓名查询建筑列表
     * @param ownerName 业主姓名
     * @return 建筑列表
     */
    List<Building> findByOwnerName(String ownerName);

    /**
     * 根据地址查询建筑列表
     * @param address 地址
     * @return 建筑列表
     */
    List<Building> findByAddress(String address);
}
