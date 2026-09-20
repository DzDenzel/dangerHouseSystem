package com.dz.dangerhouse.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.dz.dangerhouse.entity.OperationLog;
import com.dz.dangerhouse.mapper.OperationLogMapper;
import com.dz.dangerhouse.service.OperationLogService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.time.LocalDate;

/**
 * 操作日志服务实现类
 */
@Slf4j
@Service
public class OperationLogServiceImpl implements OperationLogService {

    @Autowired
    private OperationLogMapper operationLogMapper;

    /**
     * 分页查询操作日志
     *
     * @param operation 操作类型（模糊查询）
     * @param username  用户名（当前未参与筛选条件）
     * @param status    状态（1成功 0失败）
     */
    @Override
    public Page<OperationLog> getOperationLogs(Integer page, Integer size, String operation, String username, LocalDate startDate, LocalDate endDate, Integer status) {
        Page<OperationLog> logPage = new Page<>(page, size);
        LambdaQueryWrapper<OperationLog> wrapper = new LambdaQueryWrapper<>();

        wrapper.like(operation != null && !operation.isEmpty(), OperationLog::getOperation, operation)
               .eq(status != null, OperationLog::getStatus, status)
               .orderByDesc(OperationLog::getCreateTime);

        if (startDate != null) {
            wrapper.ge(OperationLog::getCreateTime, startDate.atStartOfDay());
        }

        if (endDate != null) {
            wrapper.le(OperationLog::getCreateTime, endDate.plusDays(1).atStartOfDay());
        }

        return operationLogMapper.selectPage(logPage, wrapper);
    }
}
