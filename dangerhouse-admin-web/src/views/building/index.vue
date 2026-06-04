<template>
  <div class="building-page">
    <el-card shadow="never" class="search-card">
      <el-form :model="queryParams" :inline="true" class="search-form">
        <el-form-item label="建筑名称">
          <el-input
            v-model="queryParams.name"
            placeholder="请输入建筑名称"
            clearable
            @keyup.enter="handleQuery"
          />
        </el-form-item>
        <el-form-item label="建筑地址">
          <el-input
            v-model="queryParams.address"
            placeholder="请输入建筑地址"
            clearable
            @keyup.enter="handleQuery"
          />
        </el-form-item>
        <el-form-item label="结构类型">
          <el-select
            v-model="queryParams.structureType"
            placeholder="请选择结构类型"
            clearable
            @change="handleQuery"
          >
            <el-option
              v-for="item in structureTypeOptions"
              :key="item.value"
              :label="item.label"
              :value="item.value"
            />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-button type="primary" @click="handleQuery">
            <i-ep-search class="mr-1" />
            搜索
          </el-button>
          <el-button @click="resetQuery">
            <i-ep-refresh-left class="mr-1" />
            重置
          </el-button>
        </el-form-item>
      </el-form>
    </el-card>

    <section class="building-list-section">
      <div class="list-header">
        <div>
          <h2>建筑列表</h2>
          <p>当前共 {{ total }} 条建筑记录</p>
        </div>
        <div class="header-actions">
          <el-button type="primary" @click="handleAdd">
            <i-ep-plus class="mr-1" />
            新增
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

      <div v-loading="loading" class="building-cards">
        <article
          v-for="building in buildingList"
          :key="building.id"
          class="building-card"
        >
          <div class="card-image">
            <img :src="building.imagePath || fallbackImage" alt="建筑图片" />
          </div>
          <div class="card-content">
            <div class="card-header">
              <div>
                <h3>{{ building.name }}</h3>
                <p>#{{ building.id }}</p>
              </div>
              <el-tag effect="plain">
                {{ getBuildingAge(building.buildYear) }}
              </el-tag>
            </div>

            <div class="info-list">
              <div class="info-item">
                <span class="label">地址</span>
                <span class="value">{{ building.address || "-" }}</span>
              </div>
              <div class="info-item">
                <span class="label">结构</span>
                <span class="value">{{
                  getStructureTypeLabel(building.structureType)
                }}</span>
              </div>
              <div class="info-item">
                <span class="label">建造年份</span>
                <span class="value">{{ building.buildYear || "-" }}</span>
              </div>
              <div class="info-item">
                <span class="label">业主</span>
                <span class="value">{{ building.ownerName || "-" }}</span>
              </div>
              <div class="info-item">
                <span class="label">创建角色</span>
                <span class="value">{{
                  getRoleLabel(
                    building.createdByRole,
                    building.createdByRoleName
                  )
                }}</span>
              </div>
              <div class="info-item">
                <span class="label">绑定用户</span>
                <span class="value">{{ building.ownerUserId ?? "-" }}</span>
              </div>
            </div>

            <div class="card-actions">
              <el-button circle @click="handleView(building)">
                <i-ep-view />
              </el-button>
              <el-button type="primary" circle @click="handleEdit(building)">
                <i-ep-edit />
              </el-button>
              <el-button
                type="danger"
                circle
                @click="handleDelete(building.id)"
              >
                <i-ep-delete />
              </el-button>
            </div>
          </div>
        </article>
      </div>

      <el-empty
        v-if="!loading && buildingList.length === 0"
        description="暂无建筑数据"
      />

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
      width="600px"
      @close="closeDialog"
    >
      <el-form ref="formRef" :model="form" :rules="rules" label-width="100px">
        <el-form-item label="建筑名称" prop="name">
          <el-input v-model="form.name" placeholder="请输入建筑名称" />
        </el-form-item>
        <el-form-item label="建筑地址" prop="address">
          <el-input v-model="form.address" placeholder="请输入建筑地址" />
        </el-form-item>
        <el-form-item label="结构类型" prop="structureType">
          <el-select v-model="form.structureType" placeholder="请选择结构类型">
            <el-option
              v-for="item in structureTypeOptions"
              :key="item.value"
              :label="item.label"
              :value="item.value"
            />
          </el-select>
        </el-form-item>
        <el-form-item label="建造年份" prop="buildYear">
          <el-input-number v-model="form.buildYear" :min="1900" :max="2100" />
        </el-form-item>
        <el-form-item label="楼层数" prop="floorCount">
          <el-input-number v-model="form.floorCount" :min="1" />
        </el-form-item>
        <el-form-item label="建筑面积" prop="area">
          <el-input-number v-model="form.area" :min="0" :step="0.01" />
        </el-form-item>
        <el-form-item label="业主姓名" prop="ownerName">
          <el-input v-model="form.ownerName" placeholder="请输入业主姓名" />
        </el-form-item>
        <el-form-item label="业主电话" prop="ownerPhone">
          <el-input v-model="form.ownerPhone" placeholder="请输入业主电话" />
        </el-form-item>
        <el-form-item label="经度" prop="longitude">
          <el-input-number v-model="form.longitude" :step="0.000001" />
        </el-form-item>
        <el-form-item label="纬度" prop="latitude">
          <el-input-number v-model="form.latitude" :step="0.000001" />
        </el-form-item>
        <el-form-item label="备注" prop="description">
          <el-input
            v-model="form.description"
            type="textarea"
            placeholder="请输入备注"
            :autosize="{ minRows: 2, maxRows: 4 }"
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
import { useRouter } from "vue-router";
import {
  createBuildingApi,
  deleteBuildingApi,
  getBuildingListApi,
  updateBuildingApi,
} from "@/api/building";
import type {
  BuildingListQueryRequest,
  BuildingRequest,
  BuildingResponse,
} from "@/api/building/types";
import {
  getRoleLabel,
  getStructureTypeLabel,
  getStructureTypeOptions,
} from "@/utils/building";

const router = useRouter();
const structureTypeOptions = getStructureTypeOptions();
const fallbackImage =
  "data:image/svg+xml;utf8," +
  encodeURIComponent(`
    <svg xmlns="http://www.w3.org/2000/svg" width="800" height="480" viewBox="0 0 800 480">
      <defs>
        <linearGradient id="bg" x1="0" y1="0" x2="1" y2="1">
          <stop offset="0%" stop-color="#dbeafe" />
          <stop offset="100%" stop-color="#f8fafc" />
        </linearGradient>
      </defs>
      <rect width="800" height="480" fill="url(#bg)" />
      <rect x="170" y="160" width="460" height="220" rx="20" fill="#94a3b8" />
      <rect x="220" y="200" width="120" height="180" fill="#e2e8f0" />
      <rect x="370" y="200" width="120" height="180" fill="#e2e8f0" />
      <rect x="520" y="200" width="60" height="180" fill="#e2e8f0" />
      <path d="M140 180L400 70l260 110" stroke="#475569" stroke-width="20" stroke-linecap="round" fill="none" />
    </svg>
  `);

const buildingList = ref<BuildingResponse[]>([]);
const loading = ref(false);
const ids = ref<number[]>([]);
const total = ref(0);

const queryParams = reactive({
  pageNum: 1,
  pageSize: 10,
  name: "",
  address: "",
  structureType: undefined as string | undefined,
});

const dialogVisible = ref(false);
const dialogTitle = ref("");
const formRef = ref();
const form = reactive({
  id: undefined as number | undefined,
  name: "",
  address: "",
  structureType: "",
  buildYear: new Date().getFullYear(),
  floorCount: 1,
  area: 0,
  ownerName: "",
  ownerPhone: "",
  longitude: 0,
  latitude: 0,
  description: "",
});

const rules = reactive({
  name: [{ required: true, message: "请输入建筑名称", trigger: "blur" }],
  address: [{ required: true, message: "请输入建筑地址", trigger: "blur" }],
  structureType: [
    { required: true, message: "请选择结构类型", trigger: "change" },
  ],
  buildYear: [{ required: true, message: "请输入建造年份", trigger: "blur" }],
  floorCount: [{ required: true, message: "请输入楼层数", trigger: "blur" }],
});

async function handleQuery() {
  loading.value = true;
  try {
    const params: BuildingListQueryRequest = {
      page: queryParams.pageNum,
      size: queryParams.pageSize,
      name: queryParams.name || undefined,
      address: queryParams.address || undefined,
      structureType: queryParams.structureType || undefined,
    };
    const { data } = await getBuildingListApi(params);
    buildingList.value = data.records || [];
    total.value = data.total || 0;
  } catch {
    ElMessage.error("获取建筑列表失败");
  } finally {
    loading.value = false;
  }
}

function resetQuery() {
  queryParams.pageNum = 1;
  queryParams.pageSize = 10;
  queryParams.name = "";
  queryParams.address = "";
  queryParams.structureType = undefined;
  handleQuery();
}

function handleAdd() {
  dialogTitle.value = "新增建筑";
  resetForm();
  dialogVisible.value = true;
}

function handleView(row: BuildingResponse) {
  router.push(`/building/detail?id=${row.id}`);
}

function handleEdit(row: BuildingResponse) {
  dialogTitle.value = "编辑建筑";
  form.id = row.id;
  form.name = row.name;
  form.address = row.address;
  form.structureType = row.structureType;
  form.buildYear = row.buildYear;
  form.floorCount = row.floorCount;
  form.area = row.area || 0;
  form.ownerName = row.ownerName || "";
  form.ownerPhone = row.ownerPhone || "";
  form.longitude = row.longitude || 0;
  form.latitude = row.latitude || 0;
  form.description = row.description || "";
  dialogVisible.value = true;
}

async function handleDelete(id?: number) {
  const deleteIds = id ? [id] : ids.value;
  if (deleteIds.length === 0) {
    ElMessage.warning("请选择要删除的建筑");
    return;
  }

  try {
    await ElMessageBox.confirm("确定删除选中的建筑记录吗？", "删除确认", {
      type: "warning",
      confirmButtonText: "确定",
      cancelButtonText: "取消",
    });

    for (const buildingId of deleteIds) {
      await deleteBuildingApi(buildingId);
    }

    ids.value = [];
    ElMessage.success("删除成功");
    await handleQuery();
  } catch {
    return;
  }
}

function submitForm() {
  formRef.value?.validate(async (valid: boolean) => {
    if (!valid) return;

    const payload: BuildingRequest = {
      name: form.name,
      address: form.address,
      structureType: form.structureType,
      buildYear: form.buildYear,
      floorCount: form.floorCount,
      area: form.area,
      ownerName: form.ownerName,
      ownerPhone: form.ownerPhone,
      longitude: form.longitude,
      latitude: form.latitude,
      description: form.description,
    };

    try {
      if (form.id) {
        await updateBuildingApi(form.id, payload);
        ElMessage.success("建筑信息更新成功");
      } else {
        await createBuildingApi(payload);
        ElMessage.success("建筑信息创建成功");
      }

      dialogVisible.value = false;
      await handleQuery();
    } catch {
      ElMessage.error(form.id ? "建筑更新失败" : "建筑创建失败");
    }
  });
}

function closeDialog() {
  dialogVisible.value = false;
  formRef.value?.clearValidate();
}

function resetForm() {
  form.id = undefined;
  form.name = "";
  form.address = "";
  form.structureType = "";
  form.buildYear = new Date().getFullYear();
  form.floorCount = 1;
  form.area = 0;
  form.ownerName = "";
  form.ownerPhone = "";
  form.longitude = 0;
  form.latitude = 0;
  form.description = "";
}

function getBuildingAge(buildYear?: number) {
  if (!buildYear) return "年限未知";
  const age = new Date().getFullYear() - buildYear;
  return age > 0 ? `房龄 ${age} 年` : "新建建筑";
}

onMounted(() => {
  handleQuery();
});
</script>

<style lang="scss" scoped>
.building-page {
  min-height: 100%;
  padding: 24px;
  background: transparent;
}

.search-card,
.building-list-section {
  margin-bottom: 18px;
  background: rgb(255 255 255 / 94%);
  backdrop-filter: blur(14px);
  border: 1px solid rgb(15 23 42 / 8%);
  border-radius: 20px;
  box-shadow: 0 14px 35px rgb(15 23 42 / 5%);
}

.search-card {
  padding: 4px 4px 0;
}

.building-list-section {
  padding: 22px;
}

.list-header {
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

.building-cards {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(320px, 1fr));
  gap: 18px;
}

.building-card {
  overflow: hidden;
  background: rgb(255 255 255 / 98%);
  border: 1px solid rgb(148 163 184 / 18%);
  border-radius: 18px;
  box-shadow: 0 10px 24px rgb(15 23 42 / 4%);
  transition:
    transform 0.24s ease,
    box-shadow 0.24s ease;

  &:hover {
    box-shadow: 0 16px 32px rgb(15 23 42 / 8%);
    transform: translateY(-4px);
  }
}

.card-image {
  height: 196px;
  overflow: hidden;
  background: #e2e8f0;

  img {
    width: 100%;
    height: 100%;
    object-fit: cover;
  }
}

.card-content {
  padding: 18px;
}

.card-header {
  display: flex;
  gap: 12px;
  align-items: flex-start;
  justify-content: space-between;
  margin-bottom: 14px;

  h3 {
    margin: 0 0 6px;
    font-size: 18px;
    color: #0f172a;
  }

  p {
    margin: 0;
    font-size: 13px;
    color: #64748b;
  }
}

.info-list {
  display: grid;
  gap: 10px;
  margin-bottom: 18px;
}

.info-item {
  display: grid;
  grid-template-columns: 72px 1fr;
  gap: 10px;

  .label {
    font-size: 13px;
    color: #64748b;
  }

  .value {
    font-size: 14px;
    font-weight: 500;
    color: #111827;
    word-break: break-all;
  }
}

.card-actions {
  display: flex;
  gap: 10px;
}

.pagination-wrap {
  display: flex;
  justify-content: center;
  margin-top: 22px;
}

@media (width <= 768px) {
  .building-page {
    padding: 16px;
  }

  .list-header {
    flex-direction: column;
    align-items: flex-start;
  }

  .header-actions {
    justify-content: space-between;
    width: 100%;
  }

  .building-cards {
    grid-template-columns: 1fr;
  }
}
</style>
