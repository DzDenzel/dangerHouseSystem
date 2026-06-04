<template>
  <div class="dashboard-container">
    <div class="welcome-section">
      <el-card class="welcome-card">
        <div
          class="flex flex-col md:flex-row items-start md:items-center justify-between"
        >
          <div class="flex items-center mb-4 md:mb-0">
            <img
              class="w-16 h-16 mr-4 rounded-full border-4 border-white shadow-lg"
              :src="avatarSrc"
              alt="用户头像"
            />
            <div>
              <h2 class="text-xl font-bold text-white">{{ greetings }}</h2>
              <p class="text-sm text-white/80 mt-1">欢迎使用危房智诊管理系统</p>
            </div>
          </div>

          <div class="flex space-x-4">
            <div
              v-for="item in statisticData"
              :key="item.key"
              class="statistic-item"
            >
              <div class="text-center">
                <div class="text-lg font-bold text-white">
                  {{ item.value }}
                </div>
                <div class="text-xs text-white/70">{{ item.title }}</div>
              </div>
            </div>
          </div>
        </div>
      </el-card>
    </div>

    <el-row :gutter="20" class="mt-6">
      <el-col
        v-for="(item, index) in cardData"
        :key="index"
        :xs="24"
        :sm="12"
        :lg="6"
      >
        <el-card :class="'data-card data-card-' + item.tagType" shadow="hover">
          <div class="flex flex-col h-full">
            <div class="flex items-center justify-between mb-4">
              <span class="text-sm font-medium">{{ item.title }}</span>
              <el-tag :type="item.tagType" size="small">{{
                item.tagText
              }}</el-tag>
            </div>

            <div class="flex items-center justify-between flex-grow mb-4">
              <div class="text-2xl font-bold">{{ Math.round(item.count) }}</div>
              <div :class="'icon-wrapper icon-' + item.tagType">
                <el-icon :size="28">
                  <component :is="item.iconComponent" />
                </el-icon>
              </div>
            </div>

            <div
              class="flex items-center justify-between text-sm text-gray-500"
            >
              <span>{{ item.dataDesc }}</span>
              <span class="font-medium">{{ item.extra }}</span>
            </div>
          </div>
        </el-card>
      </el-col>
    </el-row>

    <div class="mt-6 space-y-6">
      <div>
        <el-card class="chart-card" shadow="hover">
          <template #header>
            <div class="flex justify-between items-center w-full">
              <div>
                <span class="main-title">{{ getMainTitle(chartData[0]) }}</span>
                <span class="sub-title">{{ getSubTitle(chartData[0]) }}</span>
              </div>
            </div>
          </template>
          <component
            :is="chartComponent(chartData[0])"
            :id="chartData[0]"
            height="400px"
            width="100%"
          />
        </el-card>
      </div>

      <el-row :gutter="20">
        <el-col
          v-for="item in chartData.slice(1)"
          :key="item"
          :xs="24"
          :sm="24"
          :md="12"
        >
          <el-card class="chart-card" shadow="hover">
            <template #header>
              <div>
                <span class="main-title">{{ getMainTitle(item) }}</span>
                <span class="sub-title">{{ getSubTitle(item) }}</span>
              </div>
            </template>
            <component
              :is="chartComponent(item)"
              :id="item"
              height="400px"
              width="100%"
            />
          </el-card>
        </el-col>
      </el-row>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed, defineAsyncComponent, onMounted, reactive } from "vue";
import { ElMessage } from "element-plus";
import {
  Document,
  OfficeBuilding,
  UserFilled,
  WarningFilled,
} from "@element-plus/icons-vue";
import type { EpPropMergeType } from "element-plus/es/utils/vue/props/types";

import { getDashboardStatsApi } from "@/api/admin";
import { useUserStore } from "@/store/modules/user";
import { resolveAvatarUrl } from "@/utils/avatar";

defineOptions({
  name: "Dashboard",
  inheritAttrs: false,
});

const userStore = useUserStore();
const date = new Date();

const stats = reactive({
  userCount: 0,
  buildingCount: 0,
  detectionCount: 0,
  highRiskCount: 0,
});

const greetings = computed(() => {
  const hours = date.getHours();
  const username =
    userStore.user.username || userStore.user.nickname || "管理员";
  if (hours >= 6 && hours < 12) {
    return `上午好，${username}！`;
  }
  if (hours >= 12 && hours < 18) {
    return `下午好，${username}！`;
  }
  if (hours >= 18 && hours < 24) {
    return `晚上好，${username}！`;
  }
  return "夜深了，注意休息。";
});

const avatarSrc = computed(() => resolveAvatarUrl(userStore.user.avatar, 80));

const highRiskRate = computed(() => {
  if (!stats.buildingCount) return "0%";
  return `${Math.round((stats.highRiskCount / stats.buildingCount) * 100)}%`;
});

const avgDetections = computed(() => {
  if (!stats.buildingCount) return "0";
  return (stats.detectionCount / stats.buildingCount).toFixed(1);
});

const statisticData = computed(() => [
  {
    value: stats.detectionCount,
    title: "检测总数",
    key: "detectionCount",
  },
  {
    value: stats.buildingCount,
    title: "建筑总数",
    key: "buildingCount",
  },
  {
    value: stats.highRiskCount,
    title: "高风险",
    key: "highRiskCount",
  },
]);

interface CardProp {
  title: string;
  tagType: EpPropMergeType<
    StringConstructor,
    "primary" | "success" | "info" | "warning" | "danger",
    unknown
  >;
  tagText: string;
  count: number;
  dataDesc: string;
  iconComponent: object;
  extra: string;
}

const cardData = computed<CardProp[]>(() => [
  {
    title: "检测记录",
    tagType: "success",
    tagText: "总",
    count: stats.detectionCount,
    dataDesc: "总检测记录",
    iconComponent: Document,
    extra: `户均 ${avgDetections.value}`,
  },
  {
    title: "建筑档案",
    tagType: "primary",
    tagText: "总",
    count: stats.buildingCount,
    dataDesc: "总建筑数量",
    iconComponent: OfficeBuilding,
    extra: `用户 ${stats.userCount}`,
  },
  {
    title: "高风险建筑",
    tagType: "danger",
    tagText: "总",
    count: stats.highRiskCount,
    dataDesc: "需重点关注",
    iconComponent: WarningFilled,
    extra: `占比 ${highRiskRate.value}`,
  },
  {
    title: "系统用户",
    tagType: "info",
    tagText: "总",
    count: stats.userCount,
    dataDesc: "后台用户数量",
    iconComponent: UserFilled,
    extra: `建筑 ${stats.buildingCount}`,
  },
]);

const chartData = ["BarChart", "PieChart", "RadarChart"];

const chartComponent = (item: string) => {
  return defineAsyncComponent(() => import(`./components/${item}.vue`));
};

const getMainTitle = (chartName: string) => {
  const titles: Record<string, string> = {
    BarChart: "近7日检测趋势",
    PieChart: "风险等级分布",
    RadarChart: "建筑结构分布",
  };
  return titles[chartName] || chartName;
};

const getSubTitle = (chartName: string) => {
  const subTitles: Record<string, string> = {
    BarChart: "新增、完成与中高风险检测",
    PieChart: "A/B/C/D 等级聚合",
    RadarChart: "按建筑结构类型聚合",
  };
  return subTitles[chartName] || "";
};

async function loadDashboardStats() {
  try {
    const res = await getDashboardStatsApi();
    Object.assign(stats, res.data);
  } catch {
    ElMessage.error("获取首页统计数据失败");
  }
}

onMounted(() => {
  loadDashboardStats();
});
</script>

<style lang="scss" scoped>
.dashboard-container {
  position: relative;
  min-height: 100%;
  padding: 24px;
  background: transparent;

  .welcome-section {
    margin-bottom: 24px;
  }

  .welcome-card {
    padding: 32px;
    overflow: hidden;
    background:
      radial-gradient(
        circle at right top,
        rgb(255 255 255 / 18%),
        transparent 28%
      ),
      linear-gradient(135deg, #2563eb 0%, #1d4ed8 42%, #4338ca 100%);
    border: 1px solid rgb(255 255 255 / 14%);
    border-radius: 24px;
    box-shadow: 0 20px 44px rgb(37 99 235 / 18%);
    transition: all 0.3s ease;

    &:hover {
      box-shadow: 0 24px 48px rgb(37 99 235 / 24%);
      transform: translateY(-2px);
    }
  }

  .statistic-item {
    min-width: 80px;
    padding: 0 12px;
  }

  .data-card {
    overflow: hidden;
    background: rgb(255 255 255 / 94%);
    border: 1px solid rgb(15 23 42 / 8%);
    border-radius: 20px;
    box-shadow: 0 16px 36px rgb(15 23 42 / 6%);
    transition: all 0.3s ease;

    &:hover {
      box-shadow: 0 22px 44px rgb(15 23 42 / 10%);
      transform: translateY(-4px);
    }

    &-success {
      border-top: 4px solid #4ade80;
    }

    &-primary {
      border-top: 4px solid #3b82f6;
    }

    &-danger {
      border-top: 4px solid #ef4444;
    }

    &-info {
      border-top: 4px solid #64748b;
    }
  }

  .chart-card {
    background: rgb(255 255 255 / 94%);
    border: 1px solid rgb(15 23 42 / 8%);
    border-radius: 22px;
    box-shadow: 0 16px 36px rgb(15 23 42 / 6%);
    transition: all 0.3s ease;

    &:hover {
      box-shadow: 0 22px 44px rgb(15 23 42 / 10%);
      transform: translateY(-4px);
    }
  }

  .chart-card .el-card__header {
    display: flex;
    align-items: center;
    padding: 16px 20px;
    border-bottom: 1px solid rgb(226 232 240 / 90%);

    .main-title {
      margin-right: 8px;
      font-size: 16px;
      font-weight: 600;
      color: #333;
    }

    .sub-title {
      font-size: 14px;
      font-weight: 400;
      color: #999;
    }
  }

  .icon-wrapper {
    display: flex;
    align-items: center;
    justify-content: center;
    width: 52px;
    height: 52px;
    border-radius: 10px;

    &.icon-success {
      color: #4ade80;
      background: rgb(74 222 128 / 10%);
    }

    &.icon-primary {
      color: #3b82f6;
      background: rgb(59 130 246 / 10%);
    }

    &.icon-danger {
      color: #ef4444;
      background: rgb(239 68 68 / 10%);
    }

    &.icon-info {
      color: #64748b;
      background: rgb(100 116 139 / 10%);
    }
  }

  .el-icon {
    color: currentcolor;
  }

  @media (width <= 768px) {
    padding: 16px;

    .welcome-card {
      padding: 24px;
    }

    .statistic-item {
      min-width: 60px;
      padding: 0 8px;
    }
  }
}
</style>
