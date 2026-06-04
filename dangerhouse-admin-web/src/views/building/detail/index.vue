<template>
  <div class="app-container">
    <el-card shadow="never">
      <template #header>
        <div class="card-header">
          <el-button type="primary" @click="goBack">
            <i-ep-arrow-left />
            返回列表
          </el-button>
          <span class="title">建筑详情</span>
        </div>
      </template>

      <el-descriptions v-if="buildingInfo" :column="1" border>
        <el-descriptions-item label="建筑 ID">
          {{ buildingInfo.id }}
        </el-descriptions-item>
        <el-descriptions-item label="建筑名称">
          {{ buildingInfo.name }}
        </el-descriptions-item>
        <el-descriptions-item label="建筑地址">
          {{ buildingInfo.address || "-" }}
        </el-descriptions-item>
        <el-descriptions-item label="结构类型">
          {{ getStructureTypeLabel(buildingInfo.structureType) }}
        </el-descriptions-item>
        <el-descriptions-item label="建造年份">
          {{ buildingInfo.buildYear || "-" }}
        </el-descriptions-item>
        <el-descriptions-item label="楼层数">
          {{ buildingInfo.floorCount || "-" }}
        </el-descriptions-item>
        <el-descriptions-item label="建筑面积">
          {{ buildingInfo.area ?? "-" }}
        </el-descriptions-item>
        <el-descriptions-item label="户主姓名">
          {{ buildingInfo.ownerName || "-" }}
        </el-descriptions-item>
        <el-descriptions-item label="户主电话">
          {{ buildingInfo.ownerPhone || "-" }}
        </el-descriptions-item>
        <el-descriptions-item label="绑定用户 ID">
          {{ buildingInfo.ownerUserId ?? "-" }}
        </el-descriptions-item>
        <el-descriptions-item label="创建人 ID">
          {{ buildingInfo.createdBy ?? "-" }}
        </el-descriptions-item>
        <el-descriptions-item label="创建人角色">
          {{
            getRoleLabel(
              buildingInfo.createdByRole,
              buildingInfo.createdByRoleName
            )
          }}
        </el-descriptions-item>
        <el-descriptions-item label="跟进检测员 ID">
          {{ buildingInfo.assignedInspectorId ?? "-" }}
        </el-descriptions-item>
        <el-descriptions-item label="经度">
          {{ buildingInfo.longitude ?? "-" }}
        </el-descriptions-item>
        <el-descriptions-item label="纬度">
          {{ buildingInfo.latitude ?? "-" }}
        </el-descriptions-item>
        <el-descriptions-item label="备注">
          {{ buildingInfo.description || "-" }}
        </el-descriptions-item>
        <el-descriptions-item label="创建时间">
          {{ formatDateTime(buildingInfo.createdAt) }}
        </el-descriptions-item>
        <el-descriptions-item label="更新时间">
          {{ formatDateTime(buildingInfo.updatedAt) }}
        </el-descriptions-item>
      </el-descriptions>

      <el-card shadow="never" class="mt-4">
        <template #header>
          <span>相关检测记录</span>
        </template>
        <el-table v-loading="loading" :data="detectionRecords" border>
          <el-table-column label="检测 ID" prop="id" width="100" />
          <el-table-column label="检测时间" width="180">
            <template #default="scope">
              {{
                formatDateTime(
                  scope.row.detectionDate ||
                    scope.row.detectTime ||
                    scope.row.createdAt
                )
              }}
            </template>
          </el-table-column>
          <el-table-column label="检测类型" prop="detectionType" />
          <el-table-column label="风险等级" prop="riskLevel" width="120">
            <template #default="scope">
              <el-tag :type="getRiskLevelType(scope.row.riskLevel)">
                {{ formatRiskLevel(scope.row.riskLevel) }}
              </el-tag>
            </template>
          </el-table-column>
          <el-table-column
            label="操作"
            align="center"
            width="120"
            fixed="right"
          >
            <template #default="scope">
              <el-button
                type="primary"
                link
                size="small"
                @click="viewDetectionDetail(scope.row.id)"
              >
                查看详情
              </el-button>
            </template>
          </el-table-column>
        </el-table>
        <div v-if="detectionRecords.length === 0" class="empty-text">
          暂无检测记录
        </div>
      </el-card>
    </el-card>
  </div>
</template>

<script setup lang="ts">
import { onMounted, ref } from "vue";
import { useRoute, useRouter } from "vue-router";
import { ElMessage } from "element-plus";

import { getBuildingDetailApi } from "@/api/building";
import type { BuildingResponse } from "@/api/building/types";
import { getDetectionListApi } from "@/api/detection";
import type {
  DetectionListQueryRequest,
  DetectionResponse,
} from "@/api/detection/types";
import { getRoleLabel, getStructureTypeLabel } from "@/utils/building";
import { formatDateTime } from "@/utils/time";

const route = useRoute();
const router = useRouter();

const buildingInfo = ref<BuildingResponse | null>(null);
const detectionRecords = ref<DetectionResponse[]>([]);
const loading = ref(false);

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

function goBack() {
  router.push("/building/list");
}

function getRiskLevelType(level: string) {
  switch (level) {
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

function viewDetectionDetail(id: number) {
  router.push(`/detection/detail?id=${id}`);
}

onMounted(async () => {
  const idParam = route.query.id;
  const id = typeof idParam === "string" ? parseInt(idParam) : Number(idParam);
  if (!id) {
    ElMessage.warning("未找到建筑 ID");
    return;
  }

  loading.value = true;
  try {
    const [buildingRes, detectionRes] = await Promise.all([
      getBuildingDetailApi(id),
      getDetectionListApi({
        page: 1,
        size: 100,
        buildingId: id,
      } as DetectionListQueryRequest),
    ]);

    buildingInfo.value = (buildingRes as any).data as BuildingResponse;
    const page = (detectionRes as any).data as PageResponse<
      DetectionResponse[]
    >;
    detectionRecords.value = page.records || [];
  } catch {
    ElMessage.error("获取建筑详情失败");
  } finally {
    loading.value = false;
  }
});
</script>

<style scoped>
.app-container {
  padding: 20px;
}

.card-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.title {
  font-size: 18px;
  font-weight: bold;
}

.mt-4 {
  margin-top: 20px;
}

.empty-text {
  padding: 40px 0;
  color: #999;
  text-align: center;
}
</style>
