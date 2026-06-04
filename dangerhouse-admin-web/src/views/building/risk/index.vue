<template>
  <div class="risk-page">
    <el-card shadow="never" class="overview-card">
      <div class="overview-grid">
        <article class="metric-card">
          <span class="metric-label">高危建筑总数</span>
          <strong>{{ dangerousBuildings.length }}</strong>
          <p>当前接口返回的 C/D 级建筑规模</p>
        </article>
        <article class="metric-card">
          <span class="metric-label">涉及区域</span>
          <strong>{{ regionStats.length }}</strong>
          <p>已识别出区域分布的行政片区</p>
        </article>
        <article class="metric-card">
          <span class="metric-label">重点区域</span>
          <strong>{{ regionStats[0]?.name || "-" }}</strong>
          <p>当前高危建筑数量最多的区域</p>
        </article>
      </div>
    </el-card>

    <el-card shadow="never" class="region-card">
      <template #header>
        <div class="card-header">
          <div>
            <h3>各区域高危建筑</h3>
            <p>点击区域卡片可筛选下方高危建筑明细。</p>
          </div>
          <div class="header-actions">
            <el-tag type="danger" effect="plain">C/D级</el-tag>
            <el-button
              v-if="selectedRegion"
              link
              type="primary"
              @click="selectedRegion = ''"
            >
              清空筛选
            </el-button>
          </div>
        </div>
      </template>

      <div v-if="regionStats.length > 0" class="region-grid">
        <button
          v-for="item in regionStats"
          :key="item.name"
          type="button"
          class="region-item"
          :class="{ 'is-active': selectedRegion === item.name }"
          @click="toggleRegionFilter(item.name)"
        >
          <div class="region-row">
            <span class="region-name">{{ item.name }}</span>
            <span class="region-count">{{ item.count }} 栋</span>
          </div>
          <el-progress
            :percentage="item.percentage"
            :show-text="false"
            :stroke-width="8"
            color="#dc2626"
          />
        </button>
      </div>
      <el-empty v-else description="暂无高危建筑区域数据" :image-size="80" />
    </el-card>

    <el-card shadow="never" class="table-card">
      <template #header>
        <div class="card-header">
          <div>
            <h3>高危建筑明细</h3>
            <p>
              {{
                selectedRegion
                  ? `当前仅展示 ${selectedRegion} 的高危建筑记录。`
                  : "仅展示后端当前可返回的高危建筑记录。"
              }}
            </p>
          </div>
        </div>
      </template>

      <el-table v-loading="loading" :data="filteredBuildings">
        <el-table-column label="建筑 ID" prop="id" width="100" />
        <el-table-column label="建筑名称" prop="name" min-width="180" />
        <el-table-column label="所属区域" min-width="160">
          <template #default="{ row }">
            {{ extractRegionName(row.address) }}
          </template>
        </el-table-column>
        <el-table-column label="建筑地址" prop="address" min-width="260" />
        <el-table-column label="结构类型" width="150">
          <template #default="{ row }">
            {{ getStructureTypeLabel(row.structureType) }}
          </template>
        </el-table-column>
        <el-table-column label="建造年份" prop="buildYear" width="120" />
        <el-table-column label="业主" prop="ownerName" width="120" />
        <el-table-column label="操作" width="120" fixed="right" align="center">
          <template #default="{ row }">
            <el-button link type="primary" @click="viewDetail(row.id)">
              查看详情
            </el-button>
          </template>
        </el-table-column>

        <template #empty>
          <el-empty description="暂无高危建筑明细" />
        </template>
      </el-table>
    </el-card>
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted, ref } from "vue";
import { ElMessage } from "element-plus";
import { useRouter } from "vue-router";
import { getBuildingListApi } from "@/api/building";
import type { BuildingResponse } from "@/api/building/types";
import { getStructureTypeLabel } from "@/utils/building";

const router = useRouter();
const loading = ref(false);
const dangerousBuildings = ref<BuildingResponse[]>([]);
const selectedRegion = ref("");

const regionStats = computed(() => {
  const total = dangerousBuildings.value.length;
  const counts = dangerousBuildings.value.reduce<Record<string, number>>(
    (acc, item) => {
      const region = extractRegionName(item.address);
      acc[region] = (acc[region] || 0) + 1;
      return acc;
    },
    {}
  );

  return Object.entries(counts)
    .map(([name, count]) => ({
      name,
      count,
      percentage: total ? Math.max(8, Math.round((count / total) * 100)) : 0,
    }))
    .sort((a, b) => b.count - a.count);
});

const filteredBuildings = computed(() => {
  if (!selectedRegion.value) return dangerousBuildings.value;
  return dangerousBuildings.value.filter(
    (item) => extractRegionName(item.address) === selectedRegion.value
  );
});

function extractRegionName(address?: string) {
  if (!address) return "未标注区域";

  const cleaned = address.replace(/\s+/g, "");
  const patterns = [
    /(.+?(?:省|自治区|特别行政区).+?(?:市|州|盟).+?(?:区|县|旗))/,
    /(.+?(?:市|州|盟).+?(?:区|县|旗))/,
    /(.+?(?:区|县|旗))/,
    /(.+?(?:镇|乡|街道))/,
  ];

  for (const pattern of patterns) {
    const match = cleaned.match(pattern);
    if (match?.[1]) return match[1];
  }

  return cleaned.slice(0, Math.min(cleaned.length, 8)) || "未标注区域";
}

function viewDetail(id: number) {
  router.push(`/building/detail?id=${id}`);
}

function toggleRegionFilter(regionName: string) {
  selectedRegion.value = selectedRegion.value === regionName ? "" : regionName;
}

async function loadDangerousBuildings() {
  loading.value = true;
  try {
    const { data } = await getBuildingListApi({
      page: 1,
      size: 1000,
      riskLevels: "C,D",
    });
    dangerousBuildings.value = data.records || [];
  } catch {
    ElMessage.error("获取高危建筑信息失败");
  } finally {
    loading.value = false;
  }
}

onMounted(() => {
  loadDangerousBuildings();
});
</script>

<style lang="scss" scoped>
.risk-page {
  min-height: 100%;
  padding: 24px;
  background: linear-gradient(180deg, #f8fafc 0%, #eef2f7 100%);
}

.overview-card,
.region-card,
.table-card {
  margin-bottom: 18px;
  border: 1px solid rgb(15 23 42 / 8%);
  border-radius: 20px;
  box-shadow: 0 14px 35px rgb(15 23 42 / 5%);
}

.overview-grid {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: 16px;
}

.metric-card {
  padding: 18px;
  background: linear-gradient(180deg, #fff 0%, #fff7f7 100%);
  border: 1px solid rgb(220 38 38 / 10%);
  border-radius: 16px;

  strong {
    display: block;
    margin: 10px 0 8px;
    font-size: 28px;
    color: #111827;
  }

  p {
    margin: 0;
    font-size: 13px;
    color: #64748b;
  }
}

.metric-label {
  font-size: 13px;
  font-weight: 600;
  color: #7f1d1d;
}

.card-header {
  display: flex;
  gap: 16px;
  align-items: center;
  justify-content: space-between;

  h3 {
    margin: 0 0 6px;
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
  align-items: center;
}

.region-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
  gap: 14px;
}

.region-item {
  width: 100%;
  padding: 14px 16px;
  text-align: left;
  appearance: none;
  cursor: pointer;
  background: rgb(255 255 255 / 90%);
  border: 1px solid rgb(248 113 113 / 16%);
  border-radius: 14px;
  transition:
    transform 0.2s ease,
    border-color 0.2s ease,
    box-shadow 0.2s ease;

  &:hover {
    border-color: rgb(220 38 38 / 30%);
    box-shadow: 0 10px 20px rgb(220 38 38 / 8%);
    transform: translateY(-2px);
  }

  &.is-active {
    background: linear-gradient(180deg, #fff5f5 0%, #fff 100%);
    border-color: #dc2626;
    box-shadow: 0 12px 24px rgb(220 38 38 / 12%);
  }
}

.region-row {
  display: flex;
  gap: 12px;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 10px;
}

.region-name {
  font-size: 14px;
  font-weight: 600;
  color: #111827;
}

.region-count {
  font-size: 13px;
  color: #dc2626;
}

@media (width <= 768px) {
  .risk-page {
    padding: 16px;
  }

  .overview-grid {
    grid-template-columns: 1fr;
  }
}
</style>
