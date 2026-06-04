<template>
  <div class="records-page">
    <el-card shadow="never" class="search-card">
      <el-form :model="queryParams" :inline="true" class="search-form">
        <el-form-item label="所属建筑">
          <el-select
            v-model="queryParams.buildingId"
            placeholder="全部建筑"
            filterable
            clearable
            @change="handleQuery"
          >
            <el-option
              v-for="building in buildingList"
              :key="building.id"
              :label="building.name"
              :value="building.id"
            />
          </el-select>
        </el-form-item>

        <el-form-item label="任务状态">
          <el-select
            v-model="queryParams.status"
            placeholder="全部状态"
            clearable
            @change="handleQuery"
          >
            <el-option label="已创建" value="CREATED" />
            <el-option label="待分析" value="READY" />
            <el-option label="分析中" value="PROCESSING" />
            <el-option label="已完成" value="COMPLETED" />
            <el-option label="失败" value="FAILED" />
            <el-option label="已取消" value="CANCELLED" />
          </el-select>
        </el-form-item>

        <el-form-item label="风险等级">
          <el-select
            v-model="queryParams.riskLevel"
            placeholder="全部等级"
            clearable
            @change="handleQuery"
          >
            <el-option label="A级" value="A" />
            <el-option label="B级" value="B" />
            <el-option label="C级" value="C" />
            <el-option label="D级" value="D" />
          </el-select>
        </el-form-item>

        <el-form-item label="检测日期">
          <el-date-picker
            v-model="dateRange"
            type="daterange"
            value-format="YYYY-MM-DD"
            range-separator="至"
            start-placeholder="开始日期"
            end-placeholder="结束日期"
            clearable
          />
        </el-form-item>

        <el-form-item class="action-item">
          <el-button type="primary" @click="handleQuery">
            <i-ep-search class="mr-1" />
            查询
          </el-button>
          <el-button @click="resetQuery">
            <i-ep-refresh-left class="mr-1" />
            重置
          </el-button>
        </el-form-item>
      </el-form>
    </el-card>

    <section class="records-section">
      <div class="section-header">
        <div>
          <h2>检测记录</h2>
          <p>当前共 {{ total }} 条检测任务</p>
        </div>
        <div class="header-actions">
          <el-button type="primary" @click="handleAdd">
            <i-ep-plus class="mr-1" />
            新增检测
          </el-button>
          <el-button
            type="danger"
            :disabled="ids.length === 0"
            @click="handleDelete()"
          >
            <i-ep-delete class="mr-1" />
            删除
          </el-button>
        </div>
      </div>

      <el-table
        v-loading="loading"
        :data="detectionList"
        border
        class="records-table"
        @selection-change="handleSelectionChange"
      >
        <el-table-column type="selection" width="55" align="center" />
        <el-table-column label="检测 ID" prop="id" width="100" />
        <el-table-column label="建筑名称" prop="buildingName" min-width="180" />
        <el-table-column
          label="房屋地址"
          prop="buildingAddress"
          min-width="220"
        />
        <el-table-column label="任务状态" width="120" align="center">
          <template #default="{ row }">
            <el-tag :type="getStatusTagType(row.status)">
              {{ getStatusText(row.status) }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column label="风险等级" width="120" align="center">
          <template #default="{ row }">
            <el-tag
              v-if="row.riskLevel"
              :type="getRiskLevelTagType(row.riskLevel)"
            >
              {{ formatRiskLevel(row.riskLevel) }}
            </el-tag>
            <el-tag v-else type="info">-</el-tag>
          </template>
        </el-table-column>
        <el-table-column label="裂缝数量" prop="crackCount" width="100" />
        <el-table-column label="损伤比例" width="120">
          <template #default="{ row }">
            {{ formatPercent(row.damageRatio) }}
          </template>
        </el-table-column>
        <el-table-column label="AI 置信度" width="110">
          <template #default="{ row }">
            {{ formatPercent(row.confidence) }}
          </template>
        </el-table-column>
        <el-table-column label="检测时间" width="180">
          <template #default="{ row }">
            {{ formatDateTime(row.detectTime || row.createdAt) }}
          </template>
        </el-table-column>
        <el-table-column label="检测备注" min-width="220">
          <template #default="{ row }">
            <span class="table-remark">{{ row.description || "-" }}</span>
          </template>
        </el-table-column>
        <el-table-column label="操作" fixed="right" width="180" align="center">
          <template #default="{ row }">
            <div class="table-actions">
              <el-button circle @click="handleReport(row.id)">
                <i-ep-document />
              </el-button>
              <el-button type="success" circle @click="handleDetail(row.id)">
                <i-ep-view />
              </el-button>
              <el-button type="danger" circle @click="handleDelete(row.id)">
                <i-ep-delete />
              </el-button>
            </div>
          </template>
        </el-table-column>

        <template #empty>
          <el-empty description="暂无检测记录" />
        </template>
      </el-table>

      <div class="pagination-wrap">
        <pagination
          v-if="total > 0"
          v-model:total="total"
          v-model:page="queryParams.pageNum"
          v-model:limit="queryParams.pageSize"
          @pagination="handleQuery"
        />
      </div>
    </section>

    <el-dialog
      v-model="dialogVisible"
      :title="dialogTitle"
      width="560px"
      @close="closeDialog"
    >
      <el-form ref="formRef" :model="form" :rules="rules" label-width="100px">
        <el-form-item label="所属建筑" prop="buildingId">
          <el-select
            v-model="form.buildingId"
            placeholder="请选择建筑"
            filterable
          >
            <el-option
              v-for="building in buildingList"
              :key="building.id"
              :label="building.name"
              :value="building.id"
            />
          </el-select>
        </el-form-item>
        <el-form-item label="检测备注" prop="description">
          <el-input
            v-model="form.description"
            type="textarea"
            placeholder="如：3月复检、南立面裂缝复核"
            :autosize="{ minRows: 2, maxRows: 2 }"
            maxlength="200"
            show-word-limit
          />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button type="primary" @click="submitForm">确定</el-button>
        <el-button @click="closeDialog">取消</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { onMounted, reactive, ref } from "vue";
import { ElMessage, ElMessageBox } from "element-plus";
import {
  createDetectionApi,
  deleteDetectionApi,
  getDetectionListApi,
} from "@/api/detection";
import { createReportApi } from "@/api/report";
import { getBuildingListApi } from "@/api/building";
import type {
  DetectionListQueryRequest,
  DetectionResponse,
} from "@/api/detection/types";
import type {
  BuildingListQueryRequest,
  BuildingResponse,
} from "@/api/building/types";
import { formatDate, formatDateTime } from "@/utils/time";

const buildingList = ref<BuildingResponse[]>([]);
const detectionList = ref<DetectionResponse[]>([]);
const loading = ref(false);
const ids = ref<number[]>([]);
const total = ref(0);
const dateRange = ref<string[]>([]);

const queryParams = reactive({
  pageNum: 1,
  pageSize: 10,
  buildingId: undefined as number | undefined,
  status: undefined as string | undefined,
  riskLevel: undefined as string | undefined,
});

const dialogVisible = ref(false);
const dialogTitle = ref("");
const formRef = ref();
const form = reactive({
  buildingId: undefined as number | undefined,
  description: "",
});

const rules = reactive({
  buildingId: [{ required: true, message: "请选择建筑", trigger: "change" }],
  description: [
    {
      required: true,
      message: "请填写检测备注，用于区分每次检测记录",
      trigger: "blur",
    },
  ],
});

const riskLevelTextMap: Record<string, string> = {
  A: "无风险",
  B: "低风险",
  C: "中风险",
  D: "高风险",
};

function formatRiskLevel(level?: string) {
  if (!level || !riskLevelTextMap[level]) return "-";
  return `${level}级(${riskLevelTextMap[level]})`;
}

function getRiskLevelTagType(level?: string) {
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

function getStatusTagType(status?: string) {
  switch (status) {
    case "CREATED":
    case "READY":
      return "info";
    case "PROCESSING":
      return "warning";
    case "COMPLETED":
      return "success";
    case "FAILED":
    case "CANCELLED":
      return "danger";
    default:
      return "info";
  }
}

function getStatusText(status?: string) {
  switch (status) {
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
      return "未知";
  }
}

function formatPercent(value?: number | null) {
  if (value === null || value === undefined) return "-";
  return `${value}%`;
}

async function handleQuery() {
  loading.value = true;
  try {
    const params: DetectionListQueryRequest = {
      page: queryParams.pageNum,
      size: queryParams.pageSize,
      buildingId: queryParams.buildingId,
      status: queryParams.status,
      riskLevel: queryParams.riskLevel,
      startDate: dateRange.value[0]
        ? formatDate(dateRange.value[0])
        : undefined,
      endDate: dateRange.value[1] ? formatDate(dateRange.value[1]) : undefined,
    };

    const { data } = await getDetectionListApi(params);
    detectionList.value = data.records || [];
    total.value = data.total || 0;
  } catch {
    ElMessage.error("获取检测记录失败");
  } finally {
    loading.value = false;
  }
}

function resetQuery() {
  queryParams.pageNum = 1;
  queryParams.pageSize = 10;
  queryParams.buildingId = undefined;
  queryParams.status = undefined;
  queryParams.riskLevel = undefined;
  dateRange.value = [];
  handleQuery();
}

function handleSelectionChange(selection: DetectionResponse[]) {
  ids.value = selection.map((item) => item.id);
}

function handleAdd() {
  dialogTitle.value = "新增检测";
  form.buildingId = undefined;
  form.description = "";
  dialogVisible.value = true;
}

function handleDetail(id: number) {
  window.location.href = `#/detection/detail?id=${id}`;
}

function handleReport(id: number) {
  const row = detectionList.value.find((item) => item.id === id);
  const reportId = row?.report?.id;

  if (reportId) {
    window.location.href = `#/detection/report?id=${reportId}`;
    return;
  }

  if (row?.status !== "COMPLETED") {
    ElMessage.warning("检测完成后才能生成报告");
    return;
  }

  createReportApi(id)
    .then((res) => {
      ElMessage.success("报告生成成功");
      window.location.href = `#/detection/report?id=${res.data.reportId}`;
    })
    .catch(() => {
      ElMessage.error("报告生成失败");
    });
}

function handleDelete(id?: number) {
  const deleteIds = id ? [id] : ids.value;
  if (deleteIds.length === 0) {
    ElMessage.warning("请选择要删除的记录");
    return;
  }

  ElMessageBox.confirm("确定删除选中的检测记录吗？", "删除确认", {
    type: "warning",
    confirmButtonText: "确定",
    cancelButtonText: "取消",
  }).then(async () => {
    for (const detectionId of deleteIds) {
      await deleteDetectionApi(detectionId);
    }
    ids.value = [];
    await handleQuery();
    ElMessage.success("删除成功");
  });
}

function submitForm() {
  formRef.value?.validate(async (valid: boolean) => {
    if (!valid) return;

    try {
      await createDetectionApi({
        buildingId: form.buildingId as number,
        description: form.description,
      });
      ElMessage.success("新增检测记录成功");
      dialogVisible.value = false;
      await handleQuery();
    } catch {
      ElMessage.error("新增检测记录失败");
    }
  });
}

function closeDialog() {
  dialogVisible.value = false;
  formRef.value?.clearValidate();
}

async function loadBuildings() {
  const params: BuildingListQueryRequest = { page: 1, size: 1000 };
  try {
    const { data } = await getBuildingListApi(params);
    buildingList.value = data.records || [];
  } catch {
    ElMessage.error("获取建筑列表失败");
  }
}

onMounted(() => {
  loadBuildings();
  handleQuery();
});
</script>

<style lang="scss" scoped>
.records-page {
  min-height: 100%;
  padding: 24px;
  background: transparent;
}

.search-card,
.records-section {
  margin-bottom: 18px;
  background: rgb(255 255 255 / 94%);
  backdrop-filter: blur(14px);
  border: 1px solid rgb(15 23 42 / 8%);
  border-radius: 20px;
  box-shadow: 0 14px 35px rgb(15 23 42 / 5%);
}

.search-card {
  padding: 4px 6px 0;
}

.search-form {
  display: flex;
  flex-wrap: wrap;
  gap: 4px 16px;
  align-items: center;

  :deep(.el-form-item) {
    margin-right: 0;
    margin-bottom: 12px;
  }

  :deep(.el-input),
  :deep(.el-select) {
    width: 190px;
  }

  :deep(.el-date-editor) {
    width: 250px;
  }
}

.action-item {
  :deep(.el-form-item__content) {
    display: flex;
    gap: 12px;
  }
}

.records-section {
  padding: 22px;
}

.section-header {
  display: flex;
  gap: 16px;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 20px;

  h2 {
    margin: 0 0 6px;
    font-size: 24px;
    color: #0f172a;
  }

  p {
    margin: 0;
    color: #64748b;
  }
}

.header-actions {
  display: flex;
  gap: 12px;
}

.records-table {
  overflow: hidden;
  border-radius: 18px;

  :deep(th.el-table__cell) {
    font-weight: 600;
    color: #334155;
    background: #f8fafc;
  }

  :deep(.el-table__row:hover > td.el-table__cell) {
    background: #f8fbff;
  }
}

.table-actions {
  display: flex;
  gap: 10px;
  justify-content: center;
}

.table-remark {
  display: inline-block;
  max-width: 100%;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.pagination-wrap {
  display: flex;
  justify-content: center;
  margin-top: 22px;
}

@media (width <= 768px) {
  .records-page {
    padding: 16px;
  }

  .section-header {
    flex-direction: column;
    align-items: flex-start;
  }

  .header-actions {
    justify-content: space-between;
    width: 100%;
  }

  .search-form {
    :deep(.el-input),
    :deep(.el-select),
    :deep(.el-date-editor) {
      width: 100%;
    }
  }
}
</style>
