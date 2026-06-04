package com.dz.dangerhouse.service;

import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.dz.dangerhouse.entity.OperationLog;

import java.time.LocalDate;

/**
 * 操作日志服务接口
 */
public interface OperationLogService {

    /**
     * 获取操作日志列表（分页）
     *
     * @param page       页码
     * @param size       每页数量
     * @param operation  操作类型
     * @param username   用户名
     * @param startDate  开始日期
     * @param endDate    结束日期
     * @param status     操作状态
     * @return 分页结果
     */
    Page<OperationLog> getOperationLogs(Integer page, Integer size, String operation, String username, LocalDate startDate, LocalDate endDate, Integer status);
}