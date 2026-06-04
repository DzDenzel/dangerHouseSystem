<template>
  <div class="app-container">
    <el-card shadow="never" class="report-container">
      <template #header>
        <div class="header-content">
          <h3>检测报告</h3>
          <div class="header-buttons">
            <el-button type="primary" @click="handlePrint">
              <i-ep-printer />
              打印报告
            </el-button>
            <el-button @click="handleDownload">
              <i-ep-download />
              下载报告
            </el-button>
            <el-button @click="goBack">
              <i-ep-arrow-left />
              返回详情
            </el-button>
          </div>
        </div>
      </template>

      <div v-if="reportView" ref="reportContent" class="report-content">
        <div class="pdf-title">
          <h1>危房智能检测评估报告</h1>
          <p>报告编号：{{ reportView.reportNo }}</p>
        </div>

        <section class="report-section">
          <h2 class="section-title">基本信息</h2>
          <table class="pdf-table">
            <tbody>
              <tr>
                <th>建筑名称</th>
                <td>{{ reportView.buildingName }}</td>
                <th>建筑地址</th>
                <td>{{ reportView.buildingAddress }}</td>
              </tr>
              <tr>
                <th>检测时间</th>
                <td>{{ reportView.detectionTime }}</td>
                <th>报告时间</th>
                <td>{{ reportView.reportTime }}</td>
              </tr>
              <tr>
                <th>检测状态</th>
                <td>{{ reportView.statusText }}</td>
                <th>风险等级</th>
                <td>{{ reportView.riskLevelText }}</td>
              </tr>
              <tr>
                <th>裂缝数量</th>
                <td>{{ reportView.crackCount }}</td>
                <th>损伤比例</th>
                <td>{{ reportView.damageRatioText }}</td>
              </tr>
              <tr>
                <th>绑定用户 ID</th>
                <td>{{ reportView.ownerUserId }}</td>
                <th>创建角色</th>
                <td>{{ reportView.createdByRoleName }}</td>
              </tr>
            </tbody>
          </table>
        </section>

        <section class="report-section">
          <h2 class="section-title">检测结论</h2>
          <p class="report-paragraph">{{ reportView.summary }}</p>
          <p v-if="reportView.analysis" class="report-paragraph">
            {{ reportView.analysis }}
          </p>
        </section>

        <section class="report-section">
          <h2 class="section-title">关键指标</h2>
          <table class="pdf-table metrics-table">
            <thead>
              <tr>
                <th>指标</th>
                <th>结果</th>
                <th>指标</th>
                <th>结果</th>
              </tr>
            </thead>
            <tbody>
              <tr>
                <td>风险等级</td>
                <td>{{ reportView.riskLevelText }}</td>
                <td>裂缝数量</td>
                <td>{{ reportView.crackCount }}</td>
              </tr>
              <tr>
                <td>损伤比例</td>
                <td>{{ reportView.damageRatioText }}</td>
                <td>置信度</td>
                <td>{{ reportView.confidenceText }}</td>
              </tr>
            </tbody>
          </table>
        </section>

        <section v-if="reportView.cracks.length > 0" class="report-section">
          <h2 class="section-title">裂缝明细</h2>
          <table class="pdf-table crack-table">
            <thead>
              <tr>
                <th>序号</th>
                <th>类型</th>
                <th>宽度</th>
                <th>位置</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="item in reportView.cracks" :key="item.index">
                <td>{{ item.index }}</td>
                <td>{{ item.type }}</td>
                <td>{{ item.width }}</td>
                <td>{{ item.position }}</td>
              </tr>
            </tbody>
          </table>
        </section>

        <section class="report-section">
          <h2 class="section-title">处置建议</h2>
          <div class="ordered-paragraphs">
            <p v-for="(item, index) in reportView.suggestions" :key="index">
              {{ index + 1 }}. {{ item }}
            </p>
          </div>
        </section>

        <section class="report-section">
          <h2 class="section-title">检测取证说明</h2>
          <p class="report-paragraph">{{ reportView.evidenceText }}</p>
        </section>

        <section class="report-section footer-note">
          <h2 class="section-title small">说明</h2>
          <div class="ordered-paragraphs small">
            <p>
              1.
              本报告由系统根据现场图像与算法分析结果自动生成，用于业务留档与辅助判断。
            </p>
            <p>2. 如需法定鉴定结论，请结合线下复核与专业鉴定机构意见。</p>
          </div>
        </section>
      </div>
    </el-card>
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted, ref } from "vue";
import { ElMessage } from "element-plus";

import { getBuildingDetailApi } from "@/api/building";
import type { BuildingResponse } from "@/api/building/types";
import { getDetectionDetailApi } from "@/api/detection";
import type { DetectionDetailResponse } from "@/api/detection/types";
import { getReportDetailApi } from "@/api/report";
import type { ReportResponse } from "@/api/report/types";
import { getRoleLabel } from "@/utils/building";
import { formatDateTime } from "@/utils/time";

type CrackRow = {
  index: number;
  type: string;
  width: string;
  position: string;
};

const reportContent = ref<HTMLElement>();
const currentReportId = ref<number | null>(null);
const reportRaw = ref<ReportResponse | null>(null);
const detectionRaw = ref<DetectionDetailResponse | null>(null);
const buildingRaw = ref<BuildingResponse | null>(null);

const reportView = computed(() => {
  if (!reportRaw.value || !detectionRaw.value || !buildingRaw.value)
    return null;

  const detection = detectionRaw.value;
  const building = buildingRaw.value;
  const detectResult = (detection.detectResult || {}) as any;
  const cracks = buildCracks(detectResult);

  return {
    reportNo: reportRaw.value.reportNo,
    buildingName: building.name || detection.buildingName || "-",
    buildingAddress: building.address || detection.buildingAddress || "-",
    ownerUserId: building.ownerUserId ?? "-",
    createdByRoleName: getRoleLabel(
      building.createdByRole,
      building.createdByRoleName
    ),
    detectionTime: formatDateTime(detection.detectTime || detection.createdAt),
    reportTime: formatDateTime(reportRaw.value.generatedAt),
    statusText: statusText(detection.status),
    riskLevelText: riskLevelText(detection.riskLevel),
    crackCount: detection.crackCount ?? 0,
    damageRatioText: percentText(detection.damageRatio),
    confidenceText: percentText(detection.confidence),
    analysis: extractAnalysis(detectResult),
    summary: `系统已完成本次建筑影像智能分析。当前评估风险等级为 ${riskLevelText(
      detection.riskLevel
    )}，识别裂缝数量 ${detection.crackCount ?? 0} 处，损伤比例 ${percentText(
      detection.damageRatio
    )}。`,
    cracks,
    suggestions: buildSuggestions(detection.riskLevel),
    evidenceText: `本次检测共关联图片 ${
      detection.images?.length || 0
    } 张，报告结论来源于已归档的原始图片及算法结果图。`,
    detectionId: detection.id,
  };
});

function buildCracks(detectResult: any): CrackRow[] {
  const source = detectResult?.cracks;
  if (!Array.isArray(source)) return [];

  return source.map((item: any, index: number) => {
    const width =
      typeof item?.width === "number" ? `${item.width.toFixed(2)} mm` : "-";
    const type = item?.typeName || item?.type || "-";
    const position = buildLocationText(item);
    return {
      index: index + 1,
      type,
      width,
      position,
    };
  });
}

function buildLocationText(crack: any) {
  const bbox = Array.isArray(crack?.bbox) ? crack.bbox : null;
  const center = Array.isArray(crack?.center) ? crack.center : null;

  let bboxText = "-";
  if (bbox && bbox.length >= 4) {
    bboxText = `bbox[${Math.round(bbox[0])},${Math.round(bbox[1])},${Math.round(
      bbox[2]
    )},${Math.round(bbox[3])}]`;
  }

  let centerText = "-";
  if (center && center.length >= 2) {
    centerText = `center(${Math.round(center[0])},${Math.round(center[1])})`;
  }

  if (bboxText === "-" && centerText === "-") return "-";
  if (bboxText === "-") return centerText;
  if (centerText === "-") return bboxText;
  return `${bboxText} ${centerText}`;
}

function extractAnalysis(detectResult: any) {
  return typeof detectResult?.analysis === "string"
    ? detectResult.analysis
    : "";
}

function buildSuggestions(riskLevel?: string) {
  const level = (riskLevel || "").toUpperCase();
  if (level === "D" || level === "CRITICAL") {
    return [
      "立即停止相关区域使用并设置警戒线。",
      "尽快委托专业机构开展现场复核与结构鉴定。",
      "根据鉴定意见制定加固或拆除处置方案。",
    ];
  }
  if (level === "C" || level === "HIGH") {
    return [
      "限制使用高风险区域并安排复检。",
      "结合裂缝形态与位置开展结构安全复核。",
      "按专业方案实施局部加固与修复。",
    ];
  }
  if (level === "B" || level === "MEDIUM") {
    return [
      "纳入定期巡检台账，持续跟踪裂缝变化。",
      "必要时实施表层修补与防水处理。",
    ];
  }
  return [
    "保持常规维护，继续按计划开展巡检。",
    "如现场出现新增裂缝或扩展迹象，应及时复检。",
  ];
}

function statusText(status?: string) {
  switch ((status || "").toUpperCase()) {
    case "CREATED":
      return "已创建";
    case "READY":
      return "待分析";
    case "PROCESSING":
      return "分析中";
    case "COMPLETED":
      return "已完成";
    case "FAILED":
      return "失败";
    case "CANCELLED":
      return "已取消";
    default:
      return status || "-";
  }
}

function riskLevelText(level?: string) {
  switch ((level || "").toUpperCase()) {
    case "A":
    case "LOW":
      return "A级";
    case "B":
    case "MEDIUM":
      return "B级";
    case "C":
    case "HIGH":
      return "C级";
    case "D":
    case "CRITICAL":
      return "D级";
    default:
      return level || "-";
  }
}

function percentText(value?: number | null) {
  if (value === null || value === undefined || Number.isNaN(Number(value))) {
    return "-";
  }
  return `${Number(value).toFixed(2)}%`;
}

function goBack() {
  const detectionId = reportView.value?.detectionId;
  if (!detectionId) {
    window.location.href = "#/detection/records";
    return;
  }
  window.location.href = `#/detection/detail?id=${detectionId}`;
}

function buildPrintDocument() {
  const reportHtml = reportContent.value?.innerHTML;
  if (!reportHtml) {
    ElMessage.warning("暂无可打印内容");
    return null;
  }

  return `
    <!DOCTYPE html>
    <html lang="zh-CN">
      <head>
        <meta charset="UTF-8" />
        <title>检测报告打印</title>
        <style>
          body { margin: 0; padding: 24px; font-family: "Microsoft YaHei", "PingFang SC", sans-serif; color: #111827; background: #fff; }
          .pdf-title { text-align: center; margin-bottom: 20px; }
          .pdf-title h1 { margin: 0 0 8px; font-size: 26px; }
          .pdf-title p { margin: 0; font-size: 14px; color: #6b7280; }
          .report-section { margin-bottom: 22px; }
          .section-title { margin: 0 0 10px; font-size: 16px; font-weight: 700; }
          .section-title.small { font-size: 13px; }
          .pdf-table { width: 100%; border-collapse: collapse; }
          .pdf-table th, .pdf-table td { border: 1px solid #dbe1ea; padding: 10px 12px; font-size: 14px; }
          .pdf-table th { background: #eef2f7; font-weight: 700; text-align: left; }
          .metrics-table th, .metrics-table td, .crack-table th, .crack-table td { text-align: center; }
          .report-paragraph { margin: 0 0 6px; line-height: 1.8; font-size: 14px; }
          .ordered-paragraphs p { margin: 0 0 8px; line-height: 1.8; font-size: 14px; }
          .ordered-paragraphs.small p { font-size: 12px; color: #4b5563; }
        </style>
      </head>
      <body>${reportHtml}</body>
    </html>
  `;
}

function handlePrint() {
  const printWindow = window.open("", "_blank", "width=1100,height=800");
  const html = buildPrintDocument();
  if (!printWindow || !html) {
    ElMessage.warning("打印窗口打开失败");
    return;
  }
  printWindow.document.open();
  printWindow.document.write(html);
  printWindow.document.close();
  printWindow.onload = () => {
    printWindow.focus();
    printWindow.print();
    printWindow.close();
  };
}

async function handleDownload() {
  if (!currentReportId.value) {
    ElMessage.warning("暂无可下载的报告");
    return;
  }

  const token = localStorage.getItem("token");
  const baseUrl = import.meta.env.VITE_APP_BASE_API;
  const fileName = `${reportRaw.value?.reportNo || "检测报告"}.pdf`;
  const request = new XMLHttpRequest();

  request.open(
    "GET",
    `${baseUrl}/reports/${currentReportId.value}/download`,
    true
  );
  request.responseType = "blob";
  request.setRequestHeader(
    "Accept",
    "application/pdf, application/octet-stream"
  );
  if (token) {
    request.setRequestHeader("Authorization", `Bearer ${token}`);
  }

  request.onload = () => {
    if (request.status < 200 || request.status >= 300) {
      ElMessage.error("报告下载失败");
      return;
    }
    const blob = request.response;
    if (!(blob instanceof Blob) || !blob.size) {
      ElMessage.error("报告下载失败");
      return;
    }
    const objectUrl = window.URL.createObjectURL(blob);
    const link = document.createElement("a");
    link.href = objectUrl;
    link.download = fileName;
    link.style.display = "none";
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
    window.URL.revokeObjectURL(objectUrl);
  };

  request.onerror = () => {
    ElMessage.error("报告下载失败");
  };

  request.send();
}

onMounted(async () => {
  const paramsString = window.location.hash.split("?")[1];
  if (!paramsString) {
    ElMessage.warning("未找到报告 ID");
    return;
  }

  const urlParams = new URLSearchParams(paramsString);
  const id = parseInt(urlParams.get("id") || "0");
  if (!id) {
    ElMessage.warning("未找到报告 ID");
    return;
  }

  currentReportId.value = id;

  try {
    const reportRes = await getReportDetailApi(id);
    const report = (reportRes as any).data as ReportResponse;
    reportRaw.value = report;

    const [detectionRes, buildingRes] = await Promise.all([
      getDetectionDetailApi(report.detectionId),
      getBuildingDetailApi(report.buildingId),
    ]);

    detectionRaw.value = (detectionRes as any).data as DetectionDetailResponse;
    buildingRaw.value = (buildingRes as any).data as BuildingResponse;
  } catch {
    ElMessage.warning("未找到对应检测报告");
  }
});
</script>

<style scoped>
.app-container {
  padding: 20px;
}

.report-container {
  margin-bottom: 20px;
}

.header-content {
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.header-content h3 {
  margin: 0;
}

.header-buttons .el-button {
  margin-left: 10px;
}

.report-content {
  padding: 40px;
  background: #fff;
  border: 1px solid #e4e7ed;
  border-radius: 8px;
}

.pdf-title {
  margin-bottom: 20px;
  text-align: center;
}

.pdf-title h1 {
  margin: 0 0 8px;
  font-size: 26px;
  font-weight: 700;
}

.pdf-title p {
  margin: 0;
  font-size: 14px;
  color: #6b7280;
}

.report-section {
  margin-bottom: 22px;
}

.section-title {
  margin: 0 0 10px;
  font-size: 16px;
  font-weight: 700;
  color: #111827;
}

.section-title.small {
  font-size: 13px;
}

.pdf-table {
  width: 100%;
  border-collapse: collapse;
}

.pdf-table th,
.pdf-table td {
  padding: 10px 12px;
  font-size: 14px;
  border: 1px solid #dbe1ea;
}

.pdf-table th {
  font-weight: 700;
  text-align: left;
  background: #eef2f7;
}

.metrics-table th,
.metrics-table td,
.crack-table th,
.crack-table td {
  text-align: center;
}

.report-paragraph {
  margin: 0 0 6px;
  font-size: 14px;
  line-height: 1.8;
  color: #374151;
}

.ordered-paragraphs p {
  margin: 0 0 8px;
  font-size: 14px;
  line-height: 1.8;
  color: #374151;
}

.ordered-paragraphs.small p {
  font-size: 12px;
  color: #4b5563;
}
</style>
