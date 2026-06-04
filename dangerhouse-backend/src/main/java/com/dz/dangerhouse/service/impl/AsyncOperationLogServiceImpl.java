package com.dz.dangerhouse.service.impl;

import com.dz.dangerhouse.entity.OperationLog;
import com.dz.dangerhouse.mapper.OperationLogMapper;
import com.dz.dangerhouse.service.AsyncOperationLogService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;

/**
 * 异步操作日志服务实现类
 */
@Slf4j
@Service
public class AsyncOperationLogServiceImpl implements AsyncOperationLogService {

    private final OperationLogMapper operationLogMapper;

    public AsyncOperationLogServiceImpl(OperationLogMapper operationLogMapper) {
        this.operationLogMapper = operationLogMapper;
    }

    /**
     * 异步保存操作日志
     */
    @Override
    @Async("operationLogExecutor")
    public void save(OperationLog operationLog) {
        try {
            operationLogMapper.insert(operationLog);
            log.debug("操作日志异步入库成功: operation={}, userId={}, ip={}",
                    operationLog.getOperation(), operationLog.getUserId(), operationLog.getIp());
        } catch (Exception ex) {
            log.error("异步记录操作日志失败", ex);
        }
    }
}
