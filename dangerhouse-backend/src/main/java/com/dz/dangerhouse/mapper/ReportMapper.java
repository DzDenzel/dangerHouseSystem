package com.dz.dangerhouse.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.dz.dangerhouse.entity.Report;
import org.apache.ibatis.annotations.Mapper;

/**
 * 检测报告 Mapper
 */
@Mapper
public interface ReportMapper extends BaseMapper<Report> {
}