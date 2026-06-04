<template>
  <div class="log-page">
    <el-card shadow="never" class="search-card">
      <el-form :model="queryParams" inline @submit.prevent>
        <el-form-item label="操作类型">
          <el-input
            v-model="queryParams.operation"
            placeholder="请输入操作类型"
            clearable
            @keyup.enter="handleQuery"
          />
        </el-form-item>
        <el-form-item label="操作人">
          <el-input
            v-model="queryParams.username"
            placeholder="请输入用户名"
            clearable
            @keyup.enter="handleQuery"
          />
        </el-form-item>
        <el-form-item label="开始日期">
          <el-date-picker
            v-model="queryParams.startDate"
            type="date"
            placeholder="选择开始日期"
            clearable
          />
        </el-form-item>
        <el-form-item label="结束日期">
          <el-date-picker
            v-model="queryParams.endDate"
            type="date"
            placeholder="选择结束日期"
            clearable
          />
        </el-form-item>
        <el-form-item>
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

    <el-card shadow="never" class="table-card">
      <template #header>
        <div class="table-header">
          <div>
            <h3>操作日志</h3>
            <p>默认每页显示 10 条，可分页查看最近日志记录。</p>
          </div>
        </div>
      </template>

      <el-table v-loading="loading" :data="pagedLogList" class="log-table">
        <el-table-column label="日志 ID" prop="id" width="100" />
        <el-table-column label="操作人" min-width="140">
          <template #default="{ row }">
            <div class="user-name-cell">
              <span>{{ getOperatorName(row.userId) }}</span>
              <span class="user-id-text">ID: {{ row.userId ?? "-" }}</span>
            </div>
          </template>
        </el-table-column>
        <el-table-column label="操作类型" min-width="220">
          <template #default="{ row }">
            <el-tag :type="getOperationTagType(row.operation)" effect="light">
              {{ row.operation || "-" }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column label="操作接口" prop="method" min-width="220" />
        <el-table-column label="IP 地址" prop="ip" width="150" />
        <el-table-column label="操作时间" width="180">
          <template #default="{ row }">
            {{ formatDateTime(row.createTime) }}
          </template>
        </el-table-column>

        <template #empty>
          <div class="empty-state">暂无操作日志</div>
        </template>
      </el-table>

      <pagination
        v-if="total > 0"
        v-model:total="total"
        v-model:current-page="queryParams.pageNum"
        v-model:page-size="queryParams.pageSize"
        @pagination-change="handlePaginationChange"
      />
    </el-card>
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted, reactive, ref } from "vue";
import { ElMessage } from "element-plus";

import { getOperationLogsApi } from "@/api/admin";
import type {
  OperationLogQueryRequest,
  OperationLogResponse,
} from "@/api/admin/types";
import { formatDateTime } from "@/utils/time";

const DEFAULT_LOG_PAGE_SIZE = 10;

const loading = ref(false);
const allLogList = ref<OperationLogResponse[]>([]);
const total = ref(0);

const queryParams = reactive<
  OperationLogQueryRequest & {
    pageNum: number;
    pageSize: number;
    startDate?: Date | string;
    endDate?: Date | string;
  }
>({
  pageNum: 1,
  pageSize: DEFAULT_LOG_PAGE_SIZE,
  operation: "",
  username: "",
  startDate: undefined,
  endDate: undefined,
  status: undefined,
});

const pagedLogList = computed(() => {
  const start = (queryParams.pageNum - 1) * queryParams.pageSize;
  const end = start + queryParams.pageSize;
  return allLogList.value.slice(start, end);
});

function formatDateParam(val?: Date | string) {
  if (!val) return undefined;
  if (typeof val === "string") return val.split("T")[0];
  const y = val.getFullYear();
  const m = `${val.getMonth() + 1}`.padStart(2, "0");
  const d = `${val.getDate()}`.padStart(2, "0");
  return `${y}-${m}-${d}`;
}

function getOperatorName(userId?: number) {
  if (!userId) return "系统";
  return `用户 ${userId}`;
}

function getOperationTagType(operation?: string) {
  const text = (operation || "").toLowerCase();
  if (
    text.includes("删除") ||
    text.includes("delete") ||
    text.includes("remove")
  ) {
    return "danger";
  }
  if (
    text.includes("编辑") ||
    text.includes("更新") ||
    text.includes("修改") ||
    text.includes("update") ||
    text.includes("edit")
  ) {
    return "warning";
  }
  if (
    text.includes("新增") ||
    text.includes("创建") ||
    text.includes("create") ||
    text.includes("add")
  ) {
    return "success";
  }
  return "info";
}

async function handleQuery() {
  loading.value = true;
  try {
    const { data } = await getOperationLogsApi({
      page: 1,
      size: 200,
      operation: queryParams.operation || undefined,
      username: queryParams.username || undefined,
      startDate: formatDateParam(queryParams.startDate),
      endDate: formatDateParam(queryParams.endDate),
    });

    allLogList.value = data.records || [];
    total.value = allLogList.value.length;
    queryParams.pageNum = 1;
  } catch {
    allLogList.value = [];
    total.value = 0;
    ElMessage.error("获取操作日志失败");
  } finally {
    loading.value = false;
  }
}

function resetQuery() {
  queryParams.pageNum = 1;
  queryParams.pageSize = DEFAULT_LOG_PAGE_SIZE;
  queryParams.operation = "";
  queryParams.username = "";
  queryParams.startDate = undefined;
  queryParams.endDate = undefined;
  handleQuery();
}

function handlePaginationChange(page: number, pageSize: number) {
  queryParams.pageNum = page;
  queryParams.pageSize = pageSize;
}

onMounted(() => {
  handleQuery();
});
</script>

<style lang="scss" scoped>
.log-page {
  min-height: 100%;
  padding: 24px;
  background: #f6f8fb;
}

.search-card,
.table-card {
  margin-bottom: 16px;
  border: 1px solid rgb(15 23 42 / 8%);
  border-radius: 18px;
  box-shadow: 0 12px 30px rgb(15 23 42 / 5%);
}

.table-header {
  h3 {
    margin: 0 0 6px;
    color: #0f172a;
  }

  p {
    margin: 0;
    color: #64748b;
  }
}

.user-name-cell {
  display: flex;
  flex-direction: column;
  line-height: 1.5;
}

.user-id-text {
  font-size: 12px;
  color: #64748b;
}

.empty-state {
  padding: 48px 0;
  color: #94a3b8;
  text-align: center;
}

.log-table {
  :deep(th.el-table__cell) {
    font-weight: 600;
    color: #334155;
    background: #f8fafc;
  }
}

@media (width <= 768px) {
  .log-page {
    padding: 16px;
  }
}
</style>
