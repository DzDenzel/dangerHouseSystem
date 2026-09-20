package com.dz.dangerhouse.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.dz.dangerhouse.entity.Report;
import com.dz.dangerhouse.mapper.ReportMapper;
import com.dz.dangerhouse.service.DetectionReportService;
import com.dz.dangerhouse.util.ReportNumberGenerator;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;

/**
 * 检测报告服务实现类
 */
@Service
public class DetectionReportServiceImpl implements DetectionReportService {

    @Autowired
    private ReportMapper reportMapper;

    @Autowired
    private ReportNumberGenerator reportNumberGenerator;

    /**
     * 确保检测任务有关联的报告记录
     *
     * @param fileType 文件类型（PDF/WORD）
     */
    @Override
    public Report ensureReport(Long detectionId, Long buildingId, String fileType) {
        Report existing = reportMapper.selectOne(
                new LambdaQueryWrapper<Report>()
                        .eq(Report::getDetectionId, detectionId)
                        .last("LIMIT 1")
        );
        if (existing != null) {
            return existing;
        }

        String type = fileType != null ? fileType.toUpperCase() : "PDF";
        Report report = new Report();
        report.setBuildingId(buildingId);
        report.setDetectionId(detectionId);
        report.setReportNo(reportNumberGenerator.generate(detectionId));
        report.setFileType(type);
        report.setFilePath("/reports/placeholder/" + report.getReportNo() + "." + type.toLowerCase());
        report.setGeneratedAt(LocalDateTime.now());
        reportMapper.insert(report);
        return report;
    }
}