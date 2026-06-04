package com.dz.dangerhouse.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.dz.dangerhouse.entity.Detection;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;

/**
 * 检测数据访问层
 */
@Mapper
public interface DetectionMapper extends BaseMapper<Detection> {

    /**
     * 按风险等级统计检测数量
     */
    @Select("SELECT COUNT(*) FROM detection WHERE risk_level = #{riskLevel}")
    Long countByRiskLevel(@Param("riskLevel") String riskLevel);
}
