package com.dz.dangerhouse.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.dz.dangerhouse.entity.OperationLog;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;

/**
 * 操作日志表 Mapper
 */
@Mapper
public interface OperationLogMapper extends BaseMapper<OperationLog> {

    /**
     * 根据用户ID查询操作日志
     */
    List<OperationLog> findByUserId(@Param("userId") Long userId,
                                     @Param("pageNum") Integer pageNum,
                                     @Param("pageSize") Integer pageSize);
}