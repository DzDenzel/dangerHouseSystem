package com.dz.dangerhouse.aspect;

import cn.hutool.json.JSONUtil;
import com.dz.dangerhouse.annotation.Log;
import com.dz.dangerhouse.entity.OperationLog;
import com.dz.dangerhouse.filter.JwtAuthenticationFilter;
import com.dz.dangerhouse.service.AsyncOperationLogService;
import com.dz.dangerhouse.util.ServletUtils;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.extern.slf4j.Slf4j;
import org.aspectj.lang.JoinPoint;
import org.aspectj.lang.annotation.AfterReturning;
import org.aspectj.lang.annotation.AfterThrowing;
import org.aspectj.lang.annotation.Aspect;
import org.aspectj.lang.annotation.Pointcut;
import org.aspectj.lang.reflect.MethodSignature;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.context.request.RequestContextHolder;
import org.springframework.web.context.request.ServletRequestAttributes;
import org.springframework.web.multipart.MultipartFile;

import java.lang.reflect.Method;
import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.Map;

/**
 * 操作日志切面
 */
@Slf4j
@Aspect
@Component
public class OperationLogAspect {

    @Autowired
    private AsyncOperationLogService asyncOperationLogService;

    /**
     * 定义切点
     */
    @Pointcut("@annotation(com.dz.dangerhouse.annotation.Log)")
    public void logPointcut() {
    }

    /**
     * 正常返回后记录日志
     */
    @AfterReturning(pointcut = "logPointcut()", returning = "result")
    public void doAfterReturning(JoinPoint joinPoint, Object result) {
        handleLog(joinPoint, null, result);
    }

    /**
     * 异常抛出后记录日志
     */
    @AfterThrowing(pointcut = "logPointcut()", throwing = "e")
    public void doAfterThrowing(JoinPoint joinPoint, Exception e) {
        handleLog(joinPoint, e, null);
    }

    /**
     * 处理日志记录
     */
    private void handleLog(JoinPoint joinPoint, Exception e, Object result) {
        try {
            MethodSignature signature = (MethodSignature) joinPoint.getSignature();
            Method method = signature.getMethod();
            Log logAnnotation = method.getAnnotation(Log.class);
            if (logAnnotation == null) {
                return;
            }

            ServletRequestAttributes attributes = (ServletRequestAttributes) RequestContextHolder.getRequestAttributes();
            if (attributes == null) {
                return;
            }

            HttpServletRequest request = attributes.getRequest();
            Long userId = resolveCurrentUserId(request);

            if (logAnnotation.requireLogin() && userId == null) {
                return;
            }

            OperationLog operationLog = new OperationLog();
            operationLog.setUserId(userId);
            operationLog.setOperation(logAnnotation.operation());
            operationLog.setMethod(logAnnotation.method().isEmpty() ? buildMethod(request) : logAnnotation.method());
            operationLog.setIp(ServletUtils.getClientIp(request));
            operationLog.setCreateTime(LocalDateTime.now());

            if (logAnnotation.recordParams()) {
                operationLog.setParams(buildRequestParams(joinPoint));
            }

            if (logAnnotation.recordResult() && result != null) {
                String resultJson = JSONUtil.toJsonStr(result);
                if (resultJson.length() > 2000) {
                    resultJson = resultJson.substring(0, 2000) + "...";
                }
                operationLog.setResult(resultJson);
            }

            if (e != null) {
                String errorMsg = e.getMessage();
                if (errorMsg != null && errorMsg.length() > 500) {
                    errorMsg = errorMsg.substring(0, 500);
                }
                operationLog.setErrorMsg(errorMsg);
                operationLog.setStatus(0);
            } else {
                operationLog.setStatus(1);
            }

            asyncOperationLogService.save(operationLog);
        } catch (Exception ex) {
            log.error("记录操作日志失败", ex);
        }
    }

    /**
     * 解析当前用户ID
     */
    private Long resolveCurrentUserId(HttpServletRequest request) {
        Object userIdAttr = request.getAttribute(JwtAuthenticationFilter.CURRENT_USER_ID_ATTR);
        if (userIdAttr instanceof Long value) {
            return value;
        }
        if (userIdAttr instanceof Integer value) {
            return value.longValue();
        }
        if (userIdAttr instanceof String value && !value.isBlank()) {
            try {
                return Long.parseLong(value);
            } catch (NumberFormatException ignored) {
                return null;
            }
        }

        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication == null || !authentication.isAuthenticated()
                || "anonymousUser".equals(authentication.getPrincipal())) {
            return null;
        }
        return null;
    }

    /**
     * 构建请求方法标识
     */
    private String buildMethod(HttpServletRequest request) {
        return request.getMethod() + " " + request.getRequestURI();
    }

    /**
     * 构建请求参数
     */
    private String buildRequestParams(JoinPoint joinPoint) {
        try {
            MethodSignature signature = (MethodSignature) joinPoint.getSignature();
            String[] paramNames = signature.getParameterNames();
            Object[] args = joinPoint.getArgs();

            if (paramNames == null || args == null || args.length == 0) {
                return null;
            }

            Map<String, Object> params = new HashMap<>();
            for (int i = 0; i < paramNames.length; i++) {
                Object arg = args[i];
                if (arg instanceof HttpServletRequest || arg instanceof HttpServletResponse || arg instanceof MultipartFile) {
                    continue;
                }
                params.put(paramNames[i], arg);
            }

            if (params.isEmpty()) {
                return null;
            }

            String json = JSONUtil.toJsonStr(params);
            if (json.length() > 1000) {
                json = json.substring(0, 1000) + "...";
            }
            return json;
        } catch (Exception ex) {
            log.warn("构建请求参数失败", ex);
            return null;
        }
    }
}
