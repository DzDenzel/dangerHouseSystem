<template>
  <div class="user-page">
    <section class="stats-grid">
      <article class="stat-card stat-card-total">
        <span class="stat-label">用户总数</span>
        <strong>{{ userStats.total }}</strong>
        <p>系统内已注册用户规模</p>
      </article>
      <article class="stat-card stat-card-active">
        <span class="stat-label">启用账户</span>
        <strong>{{ userStats.active }}</strong>
        <p>当前允许正常登录和使用</p>
      </article>
      <article class="stat-card stat-card-disabled">
        <span class="stat-label">禁用账户</span>
        <strong>{{ userStats.disabled }}</strong>
        <p>已限制访问，建议定期复核</p>
      </article>
      <article class="stat-card stat-card-admin">
        <span class="stat-label">管理角色</span>
        <strong>{{ userStats.admin }}</strong>
        <p>具备管理权限的账户数量</p>
      </article>
    </section>

    <el-card shadow="never" class="search-card">
      <el-form :model="queryParams" inline @submit.prevent>
        <el-form-item label="关键词">
          <el-input
            v-model="queryParams.keywords"
            placeholder="用户名 / 昵称"
            clearable
            class="!w-[260px]"
            @keyup.enter="handleQuery"
          />
        </el-form-item>
        <el-form-item label="账户状态">
          <el-select
            v-model="queryParams.status"
            placeholder="全部状态"
            clearable
            class="!w-[160px]"
            @change="handleQuery"
          >
            <el-option label="启用" :value="1" />
            <el-option label="禁用" :value="0" />
          </el-select>
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
            <h3>用户列表</h3>
            <p>共 {{ total }} 条记录，支持账户状态切换与详情查看。</p>
          </div>
        </div>
      </template>

      <el-table v-loading="loading" :data="pageData" class="user-table">
        <el-table-column label="用户信息" min-width="260">
          <template #default="{ row }">
            <div class="user-cell">
              <el-avatar :size="42" :src="resolveAvatarUrl(row.avatar, 84)" />
              <div>
                <div class="user-name-row">
                  <span class="nickname">{{
                    row.nickname || row.username
                  }}</span>
                  <el-tag
                    v-if="isAdminUser(row.roles)"
                    type="danger"
                    effect="light"
                    size="small"
                  >
                    管理员
                  </el-tag>
                </div>
                <div class="sub-text">@{{ row.username }}</div>
              </div>
            </div>
          </template>
        </el-table-column>

        <el-table-column label="联系方式" min-width="220">
          <template #default="{ row }">
            <div class="contact-cell">
              <span>{{ row.phone || "-" }}</span>
              <span class="sub-text">{{ row.email || "未填写邮箱" }}</span>
            </div>
          </template>
        </el-table-column>

        <el-table-column label="角色" min-width="200">
          <template #default="{ row }">
            <div class="role-list">
              <el-tag
                v-for="role in normalizeRoles(row.roles)"
                :key="role"
                size="small"
                effect="plain"
              >
                {{ formatRoleLabel(role) }}
              </el-tag>
              <span
                v-if="normalizeRoles(row.roles).length === 0"
                class="sub-text"
              >
                未分配角色
              </span>
            </div>
          </template>
        </el-table-column>

        <el-table-column label="账户状态" width="150" align="center">
          <template #default="{ row }">
            <el-switch
              :model-value="row.status"
              :active-value="1"
              :inactive-value="0"
              :loading="switchLoadingMap[row.id]"
              inline-prompt
              active-text="启用"
              inactive-text="禁用"
              @change="(value) => handleStatusChange(row, value as number)"
            />
          </template>
        </el-table-column>

        <el-table-column label="创建时间" width="180" align="center">
          <template #default="{ row }">
            {{ formatDateTime(row.createdAt) }}
          </template>
        </el-table-column>

        <el-table-column label="操作" width="180" fixed="right" align="center">
          <template #default="{ row }">
            <div class="action-list">
              <el-button link type="primary" @click="openDetail(row.id)">
                查看详情
              </el-button>
              <el-button
                v-if="!isAdminUser(row.roles)"
                link
                :type="isInspectorUser(row.roles) ? 'warning' : 'success'"
                @click="handleInspectorChange(row)"
              >
                {{ isInspectorUser(row.roles) ? "取消检测员" : "设为检测员" }}
              </el-button>
            </div>
          </template>
        </el-table-column>

        <template #empty>
          <el-empty description="暂无用户数据" />
        </template>
      </el-table>

      <pagination
        v-if="total > 0"
        v-model:total="total"
        v-model:page="queryParams.pageNum"
        v-model:limit="queryParams.pageSize"
        @pagination="handleQuery"
      />
    </el-card>

    <el-drawer
      v-model="detailVisible"
      title="用户详情"
      size="460px"
      destroy-on-close
    >
      <div v-loading="detailLoading" class="detail-panel">
        <template v-if="detailData">
          <div class="detail-profile">
            <el-avatar
              :size="72"
              :src="resolveAvatarUrl(detailData.avatar, 144)"
            />
            <div>
              <h3>{{ detailData.nickname || detailData.username }}</h3>
              <p>@{{ detailData.username }}</p>
              <div class="detail-role-list">
                <el-tag
                  v-for="role in normalizeRoles(detailData.roles)"
                  :key="role"
                  size="small"
                  effect="light"
                >
                  {{ formatRoleLabel(role) }}
                </el-tag>
              </div>
            </div>
          </div>

          <el-descriptions :column="1" border class="detail-descriptions">
            <el-descriptions-item label="账户状态">
              <el-tag :type="detailData.status === 1 ? 'success' : 'info'">
                {{ detailData.status === 1 ? "启用" : "禁用" }}
              </el-tag>
            </el-descriptions-item>
            <el-descriptions-item label="手机号">
              {{ detailData.phone || "-" }}
            </el-descriptions-item>
            <el-descriptions-item label="邮箱">
              {{ detailData.email || "-" }}
            </el-descriptions-item>
            <el-descriptions-item label="最后登录时间">
              {{ formatDateTime(detailData.lastLoginTime) }}
            </el-descriptions-item>
            <el-descriptions-item label="最后登录 IP">
              {{ detailData.lastLoginIp || "-" }}
            </el-descriptions-item>
            <el-descriptions-item label="创建时间">
              {{ formatDateTime(detailData.createdAt) }}
            </el-descriptions-item>
            <el-descriptions-item label="更新时间">
              {{ formatDateTime(detailData.updatedAt) }}
            </el-descriptions-item>
          </el-descriptions>
        </template>

        <el-empty v-else description="未获取到用户详情" />
      </div>
    </el-drawer>
  </div>
</template>

<script setup lang="ts">
defineOptions({
  name: "User",
});

import { computed, onMounted, reactive, ref } from "vue";
import { ElMessage, ElMessageBox } from "element-plus";
import {
  getUserDetailApi,
  getUserListApi,
  updateInspectorRoleApi,
  updateUserStatusApi,
} from "@/api/user";
import type {
  UserInfo,
  UserListQueryRequest,
  UserListResponse,
  UserQuery,
} from "@/api/user/types";
import { resolveAvatarUrl } from "@/utils/avatar";
import { formatDateTime } from "@/utils/time";

type UserStats = {
  total: number;
  active: number;
  disabled: number;
  admin: number;
};

const loading = ref(false);
const detailLoading = ref(false);
const total = ref(0);
const summaryTotal = ref(0);
const pageData = ref<UserListResponse[]>([]);
const detailVisible = ref(false);
const detailData = ref<UserInfo>();
const summaryUsers = ref<UserListResponse[]>([]);
const switchLoadingMap = reactive<Record<number, boolean>>({});

const queryParams = reactive<UserQuery>({
  pageNum: 1,
  pageSize: 10,
  keywords: "",
  status: undefined,
});

const userStats = computed<UserStats>(() => {
  const source = summaryUsers.value;
  return {
    total: summaryTotal.value,
    active: source.filter((item) => item.status === 1).length,
    disabled: source.filter((item) => item.status === 0).length,
    admin: source.filter((item) => isAdminUser(item.roles)).length,
  };
});

function normalizeRoles(roles?: string[]) {
  return Array.isArray(roles) ? roles.filter(Boolean) : [];
}

function isAdminUser(roles?: string[]) {
  return normalizeRoles(roles).some((role) => /admin|manager/i.test(role));
}

function isInspectorUser(roles?: string[]) {
  return normalizeRoles(roles).some(
    (role) => role.trim().toUpperCase() === "INSPECTOR"
  );
}

function formatRoleLabel(role: string) {
  const normalized = role.trim().toUpperCase();
  const roleMap: Record<string, string> = {
    ADMIN: "系统管理员",
    ROLE_ADMIN: "系统管理员",
    SUPER_ADMIN: "超级管理员",
    USER: "普通用户",
    ROLE_USER: "普通用户",
    INSPECTOR: "检测人员",
    REVIEWER: "审核人员",
  };
  return roleMap[normalized] || role;
}

async function loadSummary(totalHint = 0) {
  const summaryQuery: UserListQueryRequest = {
    page: 1,
    size: Math.max(totalHint, 1000),
  };

  const { data } = await getUserListApi(summaryQuery);
  summaryUsers.value = data.records || [];
  summaryTotal.value = data.total || summaryUsers.value.length;
}

async function handleQuery() {
  loading.value = true;
  try {
    const params: UserListQueryRequest = {
      page: queryParams.pageNum,
      size: queryParams.pageSize,
      username: queryParams.keywords || undefined,
      status: queryParams.status,
    };

    const { data } = await getUserListApi(params);
    pageData.value = data.records || [];
    total.value = data.total || 0;
    await loadSummary(total.value);
  } catch {
    ElMessage.error("获取用户列表失败");
  } finally {
    loading.value = false;
  }
}

function resetQuery() {
  queryParams.pageNum = 1;
  queryParams.pageSize = 10;
  queryParams.keywords = "";
  queryParams.status = undefined;
  handleQuery();
}

async function openDetail(userId: number) {
  detailVisible.value = true;
  detailLoading.value = true;
  detailData.value = undefined;
  try {
    const { data } = await getUserDetailApi(userId);
    detailData.value = data;
  } catch {
    ElMessage.error("获取用户详情失败");
  } finally {
    detailLoading.value = false;
  }
}

async function handleStatusChange(row: UserListResponse, nextStatus: number) {
  const previousStatus = row.status ?? 1;
  const actionText = nextStatus === 1 ? "启用" : "禁用";

  try {
    await ElMessageBox.confirm(
      `确定要${actionText}用户“${row.nickname || row.username}”吗？`,
      "状态确认",
      {
        type: "warning",
        confirmButtonText: "确定",
        cancelButtonText: "取消",
      }
    );
  } catch {
    row.status = previousStatus;
    return;
  }

  switchLoadingMap[row.id] = true;
  row.status = nextStatus;

  try {
    await updateUserStatusApi(row.id, nextStatus);
    ElMessage.success(`用户已${actionText}`);
    await handleQuery();

    if (detailData.value?.id === row.id) {
      detailData.value.status = nextStatus;
    }
  } catch {
    row.status = previousStatus;
    ElMessage.error(`${actionText}失败`);
  } finally {
    switchLoadingMap[row.id] = false;
  }
}

async function handleInspectorChange(row: UserListResponse) {
  const nextInspector = !isInspectorUser(row.roles);
  const actionText = nextInspector ? "设为检测员" : "取消检测员";

  try {
    await ElMessageBox.confirm(
      `确定要${actionText}“${row.nickname || row.username}”吗？`,
      "角色确认",
      {
        type: "warning",
        confirmButtonText: "确定",
        cancelButtonText: "取消",
      }
    );
  } catch {
    return;
  }

  try {
    await updateInspectorRoleApi(row.id, nextInspector);
    ElMessage.success(nextInspector ? "已设置为检测员" : "已取消检测员");
    await handleQuery();

    if (detailData.value?.id === row.id) {
      detailData.value.roles = nextInspector ? ["INSPECTOR"] : ["USER"];
    }
  } catch (error: any) {
    ElMessage.error(error?.message || `${actionText}失败`);
  }
}

onMounted(() => {
  handleQuery();
});
</script>

<style lang="scss" scoped>
.user-page {
  min-height: 100%;
  padding: 24px;
  background: transparent;
}

.search-card,
.table-card {
  background: rgb(255 255 255 / 94%);
  backdrop-filter: blur(10px);
  border: 1px solid rgb(15 23 42 / 8%);
  border-radius: 22px;
  box-shadow: 0 18px 40px rgb(15 23 42 / 6%);
}

.stats-grid {
  display: grid;
  grid-template-columns: repeat(4, minmax(0, 1fr));
  gap: 16px;
  margin-bottom: 18px;
}

.stat-card {
  padding: 20px 22px;
  background: rgb(255 255 255 / 92%);
  border: 1px solid rgb(148 163 184 / 18%);
  border-radius: 20px;
  box-shadow: 0 14px 32px rgb(15 23 42 / 5%);

  strong {
    display: block;
    margin: 10px 0 8px;
    font-size: 32px;
    line-height: 1;
    color: #0f172a;
  }

  p {
    margin: 0;
    font-size: 13px;
    color: #64748b;
  }
}

.stat-label {
  font-size: 13px;
  font-weight: 600;
  color: #334155;
}

.stat-card-total {
  background: linear-gradient(180deg, #fff 0%, #eef6ff 100%);
}

.stat-card-active {
  background: linear-gradient(180deg, #fff 0%, #ecfdf5 100%);
}

.stat-card-disabled {
  background: linear-gradient(180deg, #fff 0%, #fff7ed 100%);
}

.stat-card-admin {
  background: linear-gradient(180deg, #fff 0%, #fef2f2 100%);
}

.search-card {
  margin-bottom: 18px;
}

.table-header {
  display: flex;
  gap: 16px;
  align-items: center;
  justify-content: space-between;

  h3 {
    margin: 0 0 6px;
    font-size: 18px;
    color: #0f172a;
  }

  p {
    margin: 0;
    color: #64748b;
  }
}

.user-cell {
  display: flex;
  gap: 12px;
  align-items: center;
}

.user-name-row {
  display: flex;
  gap: 8px;
  align-items: center;
  margin-bottom: 4px;
}

.nickname {
  font-weight: 600;
  color: #0f172a;
}

.contact-cell,
.role-list {
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.role-list {
  flex-flow: row wrap;
}

.sub-text {
  font-size: 12px;
  color: #64748b;
}

.action-list {
  display: flex;
  flex-direction: column;
  gap: 4px;
  align-items: center;
}

.detail-panel {
  min-height: 280px;
}

.detail-profile {
  display: flex;
  gap: 16px;
  align-items: center;
  padding: 18px;
  margin-bottom: 24px;
  background: linear-gradient(135deg, #eff6ff 0%, #f8fafc 100%);
  border-radius: 20px;

  h3 {
    margin: 0 0 6px;
    color: #0f172a;
  }

  p {
    margin: 0 0 10px;
    color: #64748b;
  }
}

.detail-role-list {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
}

.detail-descriptions {
  :deep(.el-descriptions__label) {
    width: 120px;
    color: #475569;
  }
}

.user-table {
  :deep(th.el-table__cell) {
    font-weight: 600;
    color: #334155;
    background: #f8fafc;
  }

  :deep(.el-table__row:hover > td.el-table__cell) {
    background: #f8fbff;
  }
}

@media (width <= 1280px) {
  .stats-grid {
    grid-template-columns: repeat(2, minmax(0, 1fr));
  }
}

@media (width <= 768px) {
  .user-page {
    padding: 16px;
  }

  .hero-panel {
    display: none;
  }

  .stats-grid {
    grid-template-columns: 1fr;
  }
}
</style>
