<template>
  <div class="app-container">
    <el-card v-if="detectionDetail" shadow="never" class="detail-container">
      <template #header>
        <div class="header-content">
          <h3>检测详情</h3>
          <el-button type="primary" @click="goBack">
            <i-ep-arrow-left />
            返回记录
          </el-button>
        </div>
      </template>

      <el-card shadow="never" class="info-card">
        <template #header>
          <span>基本信息</span>
        </template>
        <el-descriptions :column="2" border>
          <el-descriptions-item label="检测 ID">
            {{ detectionDetail.id }}
          </el-descriptions-item>
          <el-descriptions-item label="任务状态">
            <el-tag :type="getStatusTagType(detectionDetail.status)">
              {{ getStatusText(detectionDetail.status) }}
            </el-tag>
          </el-descriptions-item>
          <el-descriptions-item label="房屋地址">
            {{ displayAddress }}
          </el-descriptions-item>
          <el-descriptions-item label="建筑结构">
            {{ displayStructureType }}
          </el-descriptions-item>
          <el-descriptions-item label="绑定用户 ID">
            {{ displayOwnerUserId }}
          </el-descriptions-item>
          <el-descriptions-item label="创建角色">
            {{ displayCreatedByRole }}
          </el-descriptions-item>
          <el-descriptions-item label="房龄">
            {{ displayHouseAge }}
          </el-descriptions-item>
          <el-descriptions-item label="创建人 ID">
            {{ displayCreatedBy }}
          </el-descriptions-item>
          <el-descriptions-item label="跟进检测员 ID">
            {{ displayAssignedInspectorId }}
          </el-descriptions-item>
          <el-descriptions-item label="风险等级">
            <el-tag
              v-if="detectionDetail.riskLevel"
              :type="getLevelType(detectionDetail.riskLevel)"
            >
              {{ formatRiskLevel(detectionDetail.riskLevel) }}
            </el-tag>
            <el-tag v-else type="info">-</el-tag>
          </el-descriptions-item>
          <el-descriptions-item label="裂缝数量">
            {{ detectionDetail.crackCount ?? "-" }}
          </el-descriptions-item>
          <el-descriptions-item label="损伤比例">
            {{ formatPercent(detectionDetail.damageRatio) }}
          </el-descriptions-item>
          <el-descriptions-item label="AI 置信度">
            {{ formatPercent(detectionDetail.confidence) }}
          </el-descriptions-item>
          <el-descriptions-item label="检测时间">
            {{
              formatDateTime(
                detectionDetail.detectTime || detectionDetail.createdAt
              )
            }}
          </el-descriptions-item>
          <el-descriptions-item label="检测备注" :span="2">
            {{ detectionDetail.description || "-" }}
          </el-descriptions-item>
        </el-descriptions>
      </el-card>

      <el-card shadow="never" class="info-card">
        <template #header>
          <span>检测图片</span>
        </template>

        <div v-if="groupedImageBatches.length > 0" class="image-batch-list">
          <div
            v-for="(batch, batchIndex) in groupedImageBatches"
            :key="`${batch.key}-${batchIndex}`"
            class="image-batch-card"
          >
            <div class="image-batch-head">
              <span>第 {{ batchIndex + 1 }} 批图片</span>
              <span class="image-time">{{ batch.displayTime }}</span>
            </div>

            <div class="image-batch-body">
              <div class="image-panel">
                <div
                  v-for="(image, imageIndex) in batch.images"
                  :key="image.id || imageIndex"
                  class="image-pair-card"
                >
                  <div class="image-pair-index">第 {{ imageIndex + 1 }} 组</div>
                  <div class="image-pair-columns">
                    <div class="image-column">
                      <div class="image-label">原图</div>
                      <el-image
                        v-if="image.imagePath"
                        :src="image.imagePath"
                        :preview-src-list="buildPreviewList(image)"
                        :initial-index="0"
                        fit="cover"
                        class="image-item"
                      />
                      <div v-else class="image-placeholder">暂无原图</div>
                    </div>

                    <div class="image-column">
                      <div class="image-label">检测结果图</div>
                      <el-image
                        v-if="image.resultImagePath"
                        :src="image.resultImagePath"
                        :preview-src-list="buildPreviewList(image)"
                        :initial-index="image.imagePath ? 1 : 0"
                        fit="cover"
                        class="image-item"
                      />
                      <div v-else class="image-placeholder">暂无结果图</div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>

        <div v-else class="empty-images">
          <el-empty description="暂无检测图片" />
        </div>
      </el-card>

      <el-card
        v-if="detectionDetail.status === 'COMPLETED'"
        shadow="never"
        class="info-card"
      >
        <template #header>
          <span>检测结果</span>
        </template>
        <el-descriptions :column="1" border>
          <el-descriptions-item label="风险等级">
            <el-tag :type="getLevelType(detectionDetail.riskLevel || '')">
              {{ formatRiskLevel(detectionDetail.riskLevel) }}
            </el-tag>
          </el-descriptions-item>
          <el-descriptions-item label="等级描述">
            {{ getRiskLevelText(detectionDetail.riskLevel, levelDescription) }}
          </el-descriptions-item>
          <el-descriptions-item label="问题描述">
            {{ issueDescription }}
          </el-descriptions-item>
          <el-descriptions-item label="建议措施">
            {{ suggestions }}
          </el-descriptions-item>
          <el-descriptions-item label="检测方式">
            AI 智能检测
          </el-descriptions-item>
        </el-descriptions>
      </el-card>

      <div class="action-buttons">
        <el-button
          v-if="
            detectionDetail.status === 'CREATED' ||
            detectionDetail.status === 'READY'
          "
          type="warning"
          @click="handleStart"
        >
          <i-ep-video-play />
          启动检测
        </el-button>
        <el-button type="primary" @click="handleReport">
          <i-ep-document />
          查看报告
        </el-button>
        <el-button type="danger" @click="handleDelete">
          <i-ep-delete />
          删除
        </el-button>
      </div>
    </el-card>
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted, ref } from "vue";
import { useRoute } from "vue-router";
import { ElMessage, ElMessageBox } from "element-plus";

import { getBuildingDetailApi } from "@/api/building";
import type { BuildingResponse } from "@/api/building/types";
import {
  deleteDetectionApi,
  getDetectionDetailApi,
  startDetectionApi,
} from "@/api/detection";
import type {
  DetectionDetailResponse,
  DetectionImageResponse,
  DetectionResultMap,
} from "@/api/detection/types";
import { createReportApi } from "@/api/report";
import { getRoleLabel, getStructureTypeLabel } from "@/utils/building";
import { formatDateTime } from "@/utils/time";

const route = useRoute();

const detectionDetail = ref<DetectionDetailResponse | null>(null);
const detectionId = ref<number | null>(null);
const buildingInfo = ref<BuildingResponse | null>(null);

const detectResult = computed<DetectionResultMap>(() => {
  return (detectionDetail.value?.detectResult || {}) as DetectionResultMap;
});

const imagePairs = computed(() => detectionDetail.value?.images || []);

const displayAddress = computed(() => {
  return (
    detectionDetail.value?.buildingAddress || buildingInfo.value?.address || "-"
  );
});

const displayStructureType = computed(() => {
  return getStructureTypeLabel(buildingInfo.value?.structureType);
});

const displayHouseAge = computed(() => {
  const buildYear = buildingInfo.value?.buildYear;
  if (!buildYear) return "-";
  return `${new Date().getFullYear() - buildYear} 年`;
});

const displayOwnerUserId = computed(() => {
  return buildingInfo.value?.ownerUserId ?? "-";
});

const displayCreatedBy = computed(() => {
  return buildingInfo.value?.createdBy ?? "-";
});

const displayAssignedInspectorId = computed(() => {
  return buildingInfo.value?.assignedInspectorId ?? "-";
});

const displayCreatedByRole = computed(() => {
  return getRoleLabel(
    buildingInfo.value?.createdByRole,
    buildingInfo.value?.createdByRoleName
  );
});

const levelDescription = computed(
  () => detectResult.value.severityLevel || "-"
);
const issueDescription = computed(() => detectResult.value.analysis || "-");
const suggestions = computed(() => detectResult.value.suggestions || "-");

const groupedImageBatches = computed(() => {
  const groups = new Map<
    string,
    { key: string; displayTime: string; images: DetectionImageResponse[] }
  >();

  imagePairs.value.forEach((image) => {
    const key = image.uploadTime || "unknown";
    if (!groups.has(key)) {
      groups.set(key, {
        key,
        displayTime: formatDateTime(image.uploadTime) || "未记录上传时间",
        images: [],
      });
    }

    groups.get(key)!.images.push(image);
  });

  return Array.from(groups.values());
});

function buildPreviewList(image: DetectionImageResponse) {
  return [image.imagePath, image.resultImagePath].filter(
    (item): item is string => Boolean(item)
  );
}

function goBack() {
  window.location.href = "#/detection/records";
}

function handleReport() {
  const reportId = detectionDetail.value?.report?.id;
  if (reportId) {
    window.location.href = `#/detection/report?id=${reportId}`;
    return;
  }

  if (detectionDetail.value?.status !== "COMPLETED") {
    ElMessage.warning("检测完成后才能生成报告");
    return;
  }

  createReportApi(detectionDetail.value.id)
    .then((res) => {
      ElMessage.success("报告生成成功");
      window.location.href = `#/detection/report?id=${res.data.reportId}`;
    })
    .catch(() => {
      ElMessage.error("报告生成失败");
    });
}

function handleDelete() {
  ElMessageBox.confirm("确认删除该检测记录？", "警告", {
    confirmButtonText: "确定",
    cancelButtonText: "取消",
    type: "warning",
  }).then(async () => {
    if (!detectionId.value) {
      ElMessage.error("未找到检测 ID");
      return;
    }

    await deleteDetectionApi(detectionId.value);
    ElMessage.success("删除成功");
    goBack();
  });
}

function handleStart() {
  if (!detectionId.value) {
    ElMessage.error("未找到检测 ID");
    return;
  }

  startDetectionApi(detectionId.value)
    .then(() => {
      ElMessage.success("检测任务已启动");
      window.location.reload();
    })
    .catch(() => {
      ElMessage.error("启动检测失败，请确认已上传检测图片");
    });
}

const riskLevelTextMap: Record<string, string> = {
  A: "无风险",
  B: "低风险",
  C: "中风险",
  D: "高风险",
};

function formatRiskLevel(level?: string) {
  if (!level || !riskLevelTextMap[level]) return "-";
  return `${level}级（${riskLevelTextMap[level]}）`;
}

function formatPercent(value?: number | null) {
  if (value === null || value === undefined) return "-";
  return `${value}%`;
}

function getRiskLevelText(level?: string, fallback?: string) {
  if (level && riskLevelTextMap[level]) return riskLevelTextMap[level];
  return fallback || "-";
}

function getLevelType(riskLevel: string) {
  switch (riskLevel) {
    case "A":
      return "success";
    case "B":
      return "info";
    case "C":
      return "warning";
    case "D":
      return "danger";
    default:
      return "info";
  }
}

function getStatusTagType(status?: string | number) {
  if (status === "READY") return "info";
  if (status === "PROCESSING") return "warning";
  if (status === "COMPLETED") return "success";
  if (status === "FAILED" || status === "CANCELLED") return "danger";
  if (status === "CREATED") return "info";
  return "info";
}

function getStatusText(status?: string | number) {
  if (status === "READY") return "待分析";
  if (status === "PROCESSING") return "分析中";
  if (status === "COMPLETED") return "已完成";
  if (status === "FAILED") return "失败";
  if (status === "CREATED") return "已创建";
  if (status === "CANCELLED") return "已取消";
  return "未知";
}

onMounted(async () => {
  const id = Number(route.query.id || 0);
  if (!id) {
    ElMessage.warning("未找到检测 ID");
    return;
  }

  detectionId.value = id;

  try {
    const res = await getDetectionDetailApi(id);
    const detail = res.data as DetectionDetailResponse;
    detectionDetail.value = detail;

    if (detail.buildingId) {
      const buildingRes = await getBuildingDetailApi(detail.buildingId);
      buildingInfo.value = buildingRes.data as BuildingResponse;
    }
  } catch {
    ElMessage.error("获取检测详情失败");
  }
});
</script>

<style scoped>
.app-container {
  padding: 20px;
}

.detail-container {
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

.info-card {
  margin-bottom: 20px;
}

.image-batch-list {
  display: flex;
  flex-direction: column;
  gap: 18px;
}

.image-batch-card {
  overflow: hidden;
  background: #fff;
  border: 1px solid #ebeef5;
  border-radius: 14px;
}

.image-batch-head {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 14px 18px;
  font-weight: 600;
  color: #1f2937;
  background: #f8fafc;
  border-bottom: 1px solid #ebeef5;
}

.image-time {
  font-size: 13px;
  font-weight: 400;
  color: #6b7280;
}

.image-batch-body {
  padding: 18px;
}

.image-panel {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(360px, 1fr));
  gap: 16px;
}

.image-pair-card {
  padding: 14px;
  background: #fcfdff;
  border: 1px solid #ebeef5;
  border-radius: 12px;
}

.image-pair-index {
  margin-bottom: 12px;
  font-size: 13px;
  font-weight: 600;
  color: #6b7280;
}

.image-pair-columns {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 14px;
}

.image-column {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.image-label {
  font-size: 14px;
  font-weight: 600;
  color: #374151;
}

.image-item {
  width: 100%;
  height: 220px;
  background: #f8fafc;
  border: 1px solid #ebeef5;
  border-radius: 12px;
}

.image-placeholder {
  display: flex;
  align-items: center;
  justify-content: center;
  height: 220px;
  color: #9ca3af;
  background: #f9fafb;
  border: 1px dashed #d1d5db;
  border-radius: 12px;
}

.empty-images {
  padding: 40px 0;
  text-align: center;
}

.action-buttons {
  margin-top: 20px;
  text-align: right;
}

.action-buttons .el-button {
  margin-left: 10px;
}

@media (width <= 900px) {
  .image-panel {
    grid-template-columns: 1fr;
  }

  .image-pair-columns {
    grid-template-columns: 1fr;
  }
}
</style>
