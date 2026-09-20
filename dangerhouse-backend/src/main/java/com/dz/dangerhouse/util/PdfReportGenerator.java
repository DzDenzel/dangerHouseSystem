package com.dz.dangerhouse.util;

import com.dz.dangerhouse.entity.Building;
import com.dz.dangerhouse.entity.Detection;
import com.dz.dangerhouse.entity.Image;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.lowagie.text.Document;
import com.lowagie.text.Element;
import com.lowagie.text.Font;
import com.lowagie.text.PageSize;
import com.lowagie.text.Paragraph;
import com.lowagie.text.Phrase;
import com.lowagie.text.Rectangle;
import com.lowagie.text.pdf.BaseFont;
import com.lowagie.text.pdf.PdfPCell;
import com.lowagie.text.pdf.PdfPTable;
import com.lowagie.text.pdf.PdfWriter;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import java.awt.Color;
import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.IOException;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.List;

/**
 * PDF报告生成器
 * 用于生成危房智能检测评估报告的PDF文档
 */
@Slf4j
@Component
public class PdfReportGenerator {

    @Value("${file.upload.base-dir:D:/dangerhouse/uploads}")
    private String uploadBaseDir;

    @Autowired
    private FileUploadUtil fileUploadUtil;

    private final ObjectMapper objectMapper = new ObjectMapper();

    private BaseFont chineseFont;

    public String generateReport(Detection detection, Building building, List<Image> images, String reportNo) {
        ByteArrayOutputStream output = new ByteArrayOutputStream();

        try {
            Document document = new Document(PageSize.A4, 40, 40, 48, 48);
            PdfWriter.getInstance(document, output);
            document.open();

            Font titleFont = font(18, Font.BOLD);
            Font subTitleFont = font(11, Font.NORMAL);
            Font sectionFont = font(13, Font.BOLD);
            Font bodyFont = font(10, Font.NORMAL);
            Font smallFont = font(9, Font.NORMAL);

            addTitle(document, reportNo, titleFont, subTitleFont);
            addBasicInfo(document, detection, building, bodyFont);
            addSummary(document, detection, bodyFont);
            addMetrics(document, detection, bodyFont);
            addCrackDetails(document, detection, bodyFont, smallFont);
            addRecommendations(document, detection, bodyFont);
            addEvidence(document, images, sectionFont, bodyFont);
            addFooter(document, smallFont);

            document.close();
        } catch (Exception e) {
            log.error("生成 PDF 报告失败", e);
            throw new RuntimeException("生成 PDF 报告失败: " + e.getMessage(), e);
        }

        return fileUploadUtil.uploadReportBytes(
                output.toByteArray(),
                reportNo + ".pdf",
                detection.getId(),
                "application/pdf"
        );
    }

    private void addTitle(Document document, String reportNo, Font titleFont, Font subTitleFont) throws Exception {
        Paragraph title = new Paragraph("危房智能检测评估报告", titleFont);
        title.setAlignment(Element.ALIGN_CENTER);
        title.setSpacingAfter(8);
        document.add(title);

        Paragraph subtitle = new Paragraph("报告编号: " + reportNo, subTitleFont);
        subtitle.setAlignment(Element.ALIGN_CENTER);
        subtitle.setSpacingAfter(18);
        document.add(subtitle);
    }

    private void addBasicInfo(Document document, Detection detection, Building building, Font bodyFont) throws Exception {
        PdfPTable table = createTable(new float[]{1.2f, 2.3f, 1.2f, 2.3f});
        addKeyValueRow(table, "建筑名称", building == null ? "-" : defaultText(building.getName()), "建筑地址", building == null ? "-" : defaultText(building.getAddress()), bodyFont);
        addKeyValueRow(table, "检测时间", formatDateTime(detection.getDetectTime()), "报告时间", formatDateTime(LocalDateTime.now()), bodyFont);
        addKeyValueRow(table, "检测状态", statusText(detection.getStatus()), "风险等级", riskLevelText(detection.getRiskLevel()), bodyFont);
        addKeyValueRow(table, "裂缝数量", String.valueOf(defaultInt(detection.getCrackCount())), "损伤比例", percentText(detection.getDamageRatio()), bodyFont);
        document.add(table);
        document.add(spacer(12));
    }

    private void addSummary(Document document, Detection detection, Font bodyFont) throws Exception {
        document.add(section("检测结论", bodyFont));
        String summary = "系统已完成本次建筑影像智能分析。"
                + "当前评估风险等级为 " + riskLevelText(detection.getRiskLevel()) + "，"
                + "识别裂缝数量 " + defaultInt(detection.getCrackCount()) + " 处，"
                + "损伤比例 " + percentText(detection.getDamageRatio()) + "。";
        document.add(paragraph(summary, bodyFont));

        String analysis = extractAnalysis(detection.getDetectResult());
        if (!analysis.isBlank()) {
            document.add(paragraph(analysis, bodyFont));
        }
        document.add(spacer(10));
    }

    private void addMetrics(Document document, Detection detection, Font bodyFont) throws Exception {
        document.add(section("关键指标", bodyFont));
        PdfPTable table = createTable(new float[]{1, 1, 1, 1});
        addHeaderRow(table, List.of("指标", "结果", "指标", "结果"), bodyFont);
        addBodyRow(table, List.of(
                "风险等级", riskLevelText(detection.getRiskLevel()),
                "裂缝数量", String.valueOf(defaultInt(detection.getCrackCount()))
        ), bodyFont);
        addBodyRow(table, List.of(
                "损伤比例", percentText(detection.getDamageRatio()),
                "置信度", percentText(detection.getConfidence())
        ), bodyFont);
        document.add(table);
        document.add(spacer(10));
    }

    private void addCrackDetails(Document document, Detection detection, Font bodyFont, Font smallFont) throws Exception {
        List<List<String>> cracks = extractCracks(detection.getDetectResult());
        if (cracks.isEmpty()) {
            return;
        }

        document.add(section("裂缝明细", bodyFont));
        PdfPTable table = createTable(new float[]{0.8f, 1.3f, 1.1f, 3.2f});
        addHeaderRow(table, List.of("序号", "类型", "宽度", "位置"), bodyFont);
        for (List<String> row : cracks) {
            addBodyRow(table, row, smallFont);
        }
        document.add(table);
        document.add(spacer(10));
    }

    private void addRecommendations(Document document, Detection detection, Font bodyFont) throws Exception {
        document.add(section("处置建议", bodyFont));
        List<String> suggestions = buildSuggestions(detection.getRiskLevel());
        for (int i = 0; i < suggestions.size(); i++) {
            document.add(paragraph((i + 1) + ". " + suggestions.get(i), bodyFont));
        }
        document.add(spacer(10));
    }

    private void addEvidence(Document document, List<Image> images, Font sectionFont, Font bodyFont) throws Exception {
        document.add(new Paragraph("检测取证说明", sectionFont));
        document.add(paragraph("本次检测共关联图片 " + (images == null ? 0 : images.size()) + " 张，"
                + "报告结论来源于已归档的原始图片及算法结果图。", bodyFont));
        document.add(spacer(10));
    }

    private void addFooter(Document document, Font smallFont) throws Exception {
        document.add(section("说明", smallFont));
        document.add(paragraph("1. 本报告由系统根据现场图像与算法分析结果自动生成，用于业务留档与辅助判断。", smallFont));
        document.add(paragraph("2. 如需法定鉴定结论，请结合线下复勘与专业鉴定机构意见。", smallFont));
    }

    private PdfPTable createTable(float[] widths) throws Exception {
        PdfPTable table = new PdfPTable(widths.length);
        table.setWidthPercentage(100);
        table.setWidths(widths);
        return table;
    }

    private void addKeyValueRow(PdfPTable table, String key1, String value1, String key2, String value2, Font font) {
        addCell(table, key1, font, true, Element.ALIGN_LEFT);
        addCell(table, value1, font, false, Element.ALIGN_LEFT);
        addCell(table, key2, font, true, Element.ALIGN_LEFT);
        addCell(table, value2, font, false, Element.ALIGN_LEFT);
    }

    private void addHeaderRow(PdfPTable table, List<String> values, Font font) {
        for (String value : values) {
            addCell(table, value, font, true, Element.ALIGN_CENTER);
        }
    }

    private void addBodyRow(PdfPTable table, List<String> values, Font font) {
        for (String value : values) {
            addCell(table, value, font, false, Element.ALIGN_CENTER);
        }
    }

    private void addCell(PdfPTable table, String value, Font font, boolean header, int alignment) {
        PdfPCell cell = new PdfPCell(new Phrase(defaultText(value), font));
        cell.setPadding(7);
        cell.setBorder(Rectangle.BOX);
        cell.setHorizontalAlignment(alignment);
        cell.setVerticalAlignment(Element.ALIGN_MIDDLE);
        if (header) {
            cell.setBackgroundColor(new Color(238, 242, 247));
        }
        table.addCell(cell);
    }

    private Paragraph section(String title, Font font) {
        Paragraph paragraph = new Paragraph(title, font);
        paragraph.setSpacingBefore(4);
        paragraph.setSpacingAfter(8);
        return paragraph;
    }

    private Paragraph paragraph(String content, Font font) {
        Paragraph paragraph = new Paragraph(defaultText(content), font);
        paragraph.setLeading(16);
        paragraph.setSpacingAfter(6);
        return paragraph;
    }

    private Paragraph spacer(float height) {
        Paragraph paragraph = new Paragraph(" ");
        paragraph.setSpacingAfter(height);
        return paragraph;
    }

    private String extractAnalysis(String detectResult) {
        try {
            JsonNode root = objectMapper.readTree(detectResult);
            JsonNode analysis = root.get("analysis");
            return analysis == null ? "" : analysis.asText("");
        } catch (Exception e) {
            return "";
        }
    }

    /**
     * @return 每行为 [序号, 类型, 宽度, 位置]
     */
    private List<List<String>> extractCracks(String detectResult) {
        List<List<String>> rows = new ArrayList<>();
        try {
            JsonNode root = objectMapper.readTree(detectResult);
            JsonNode cracks = root.get("cracks");
            if (cracks == null || !cracks.isArray()) {
                return rows;
            }

            int index = 1;
            for (JsonNode crack : cracks) {
                String width = crack.has("width") ? String.format("%.2f mm", crack.path("width").asDouble()) : "-";
                String position = buildLocationText(crack);
                rows.add(List.of(
                        String.valueOf(index++),
                        crack.path("typeName").asText(crack.path("type").asText("-")),
                        width,
                        position
                ));
            }
        } catch (Exception ignored) {
            return rows;
        }
        return rows;
    }

    private String buildLocationText(JsonNode crack) {
        JsonNode bbox = crack.get("bbox");
        JsonNode center = crack.get("center");

        String bboxText = "-";
        if (bbox != null && bbox.isArray() && bbox.size() >= 4) {
            bboxText = String.format(
                    "bbox[%d,%d,%d,%d]",
                    bbox.get(0).asInt(),
                    bbox.get(1).asInt(),
                    bbox.get(2).asInt(),
                    bbox.get(3).asInt()
            );
        }

        String centerText = "-";
        if (center != null && center.isArray() && center.size() >= 2) {
            centerText = String.format(
                    "center(%d,%d)",
                    center.get(0).asInt(),
                    center.get(1).asInt()
            );
        }

        if ("-".equals(bboxText) && "-".equals(centerText)) {
            return "-";
        }
        if ("-".equals(centerText)) {
            return bboxText;
        }
        if ("-".equals(bboxText)) {
            return centerText;
        }
        return bboxText + " " + centerText;
    }

    private List<String> buildSuggestions(String riskLevel) {
        String level = riskLevel == null ? "" : riskLevel.toUpperCase();
        if ("D".equals(level) || "CRITICAL".equals(level)) {
            return List.of(
                    "立即停止相关区域使用并设置警戒线。",
                    "尽快委托专业机构开展现场复核与结构鉴定。",
                    "根据鉴定意见制定加固或拆除处置方案。"
            );
        }
        if ("C".equals(level) || "HIGH".equals(level)) {
            return List.of(
                    "限制使用高风险区域并安排复检。",
                    "结合裂缝形态与位置开展结构安全复核。",
                    "按专业方案实施局部加固与修复。"
            );
        }
        if ("B".equals(level) || "MEDIUM".equals(level)) {
            return List.of(
                    "纳入定期巡检台账，持续跟踪裂缝变化。",
                    "必要时实施表层修补与防水处理。"
            );
        }
        return List.of(
                "保持常规维护，继续按计划开展巡检。",
                "如现场出现新增裂缝或扩展迹象，应及时复检。"
        );
    }

    private Font font(float size, int style) {
        try {
            return new Font(chineseBaseFont(), size, style);
        } catch (Exception e) {
            return new Font(Font.HELVETICA, size, style);
        }
    }

    /**
     * 优先使用上传目录下的宋体文件（fonts/simsun.ttc），不存在则回退到内置字体
     */
    private BaseFont chineseBaseFont() throws IOException, com.lowagie.text.DocumentException {
        if (chineseFont == null) {
            String fontPath = uploadBaseDir + "/fonts/simsun.ttc";
            File fontFile = new File(fontPath);
            chineseFont = fontFile.exists()
                    ? BaseFont.createFont(fontPath + ",0", BaseFont.IDENTITY_H, BaseFont.EMBEDDED)
                    : BaseFont.createFont("STSong-Light", "UniGB-UCS2-H", BaseFont.NOT_EMBEDDED);
        }
        return chineseFont;
    }

    /**
     * 为空时返回 "-"
     */
    private String defaultText(String value) {
        return value == null || value.isBlank() ? "-" : value;
    }

    /**
     * 为空时返回 0
     */
    private int defaultInt(Integer value) {
        return value == null ? 0 : value;
    }

    /**
     * @return 格式 yyyy-MM-dd HH:mm:ss，为空时返回 "-"
     */
    private String formatDateTime(LocalDateTime value) {
        if (value == null) {
            return "-";
        }
        return value.format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss"));
    }

    /**
     * 保留两位小数，为空时返回 "-"
     */
    private String percentText(BigDecimal value) {
        if (value == null) {
            return "-";
        }
        return String.format("%.2f%%", value.doubleValue());
    }

    /**
     * 保留两位小数，为空时返回 "-"
     */
    private String percentText(Double value) {
        if (value == null) {
            return "-";
        }
        return String.format("%.2f%%", value);
    }

    private String statusText(String status) {
        if (status == null) {
            return "-";
        }
        return switch (status.toUpperCase()) {
            case "CREATED" -> "已创建";
            case "READY" -> "待分析";
            case "PROCESSING" -> "分析中";
            case "COMPLETED" -> "已完成";
            case "FAILED" -> "失败";
            case "CANCELLED" -> "已取消";
            default -> status;
        };
    }

    private String riskLevelText(String riskLevel) {
        if (riskLevel == null) {
            return "-";
        }
        return switch (riskLevel.toUpperCase()) {
            case "A", "LOW" -> "A级";
            case "B", "MEDIUM" -> "B级";
            case "C", "HIGH" -> "C级";
            case "D", "CRITICAL" -> "D级";
            default -> riskLevel;
        };
    }
}
