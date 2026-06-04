package com.dz.dangerhouse.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.dz.dangerhouse.entity.Building;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;

import java.util.List;

/**
 * 建筑档案表 Mapper
 */
@Mapper
public interface BuildingMapper extends BaseMapper<Building> {

    /**
     * 根据业主姓名模糊查询建筑列表
     */
    @Select("SELECT * FROM building WHERE owner_name LIKE CONCAT('%', #{ownerName}, '%')")
    List<Building> findByOwnerName(@Param("ownerName") String ownerName);

    /**
     * 根据地址模糊查询建筑列表
     */
    @Select("SELECT * FROM building WHERE address LIKE CONCAT('%', #{address}, '%')")
    List<Building> findByAddress(@Param("address") String address);
}
