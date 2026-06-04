package com.dz.dangerhouse.service;

import com.dz.dangerhouse.entity.OperationLog;

/**
 * 异步操作日志服务接口
 */
public interface AsyncOperationLogService {

    /**
     * 异步保存操作日志
     */
    void save(OperationLog operationLog);
}
