<template>
  <div class="chart-content">
    <div :id="id" :class="className" :style="{ height, width }"></div>
  </div>
</template>

<script setup lang="ts">
import * as echarts from "echarts";
import { getBuildingListApi } from "@/api/building";
import { getStructureTypeLabel } from "@/utils/building";

const props = defineProps({
  id: {
    type: String,
    default: "radarChart",
  },
  className: {
    type: String,
    default: "",
  },
  width: {
    type: String,
    default: "200px",
    required: true,
  },
  height: {
    type: String,
    default: "200px",
    required: true,
  },
});

const chart = ref<any>("");

const structureTypes = [
  "BRICK_MIX",
  "CONCRETE",
  "BRICK_WOOD",
  "STEEL",
  "OTHER",
];

function normalizeStructureType(value?: string) {
  if (!value) return "OTHER";
  return structureTypes.includes(value) ? value : "OTHER";
}

function buildOptions(values: number[]) {
  const maxValue = Math.max(5, ...values);

  return {
    grid: {
      left: "3%",
      right: "4%",
      bottom: "3%",
      containLabel: true,
    },
    legend: {
      x: "center",
      y: "bottom",
      data: ["建筑结构分布"],
      textStyle: {
        color: "#666",
      },
    },
    radar: {
      shape: "circle",
      radius: "65%",
      indicator: structureTypes.map((name) => ({
        name: getStructureTypeLabel(name),
        max: maxValue,
      })),
      splitArea: {
        areaStyle: {
          color: [
            "rgba(59, 130, 246, 0.05)",
            "rgba(59, 130, 246, 0.1)",
            "rgba(59, 130, 246, 0.15)",
            "rgba(59, 130, 246, 0.2)",
          ],
        },
      },
      axisLine: {
        lineStyle: {
          color: "rgba(59, 130, 246, 0.2)",
        },
      },
      splitLine: {
        lineStyle: {
          color: "rgba(59, 130, 246, 0.3)",
        },
      },
      axisName: {
        color: "#666",
      },
    },
    series: [
      {
        name: "建筑结构分布",
        type: "radar",
        areaStyle: {
          opacity: 0.3,
        },
        lineStyle: {
          width: 2,
        },
        itemStyle: {
          color: "#3b82f6",
        },
        data: [
          {
            value: values,
            name: "建筑结构分布",
          },
        ],
      },
    ],
  };
}

async function loadChartData() {
  const counts = new Map(structureTypes.map((item) => [item, 0]));

  try {
    const res = await getBuildingListApi({ page: 1, size: 1000 });
    res.data.records.forEach((item) => {
      const type = normalizeStructureType(item.structureType);
      counts.set(type, (counts.get(type) || 0) + 1);
    });
  } catch {
    // 忽略错误，回退到零值
  }

  chart.value.setOption(
    buildOptions(structureTypes.map((item) => counts.get(item) || 0))
  );
}

onMounted(() => {
  chart.value = markRaw(
    echarts.init(document.getElementById(props.id) as HTMLDivElement)
  );

  loadChartData();

  window.addEventListener("resize", () => {
    chart.value.resize();
  });
});

onActivated(() => {
  if (chart.value) {
    chart.value.resize();
  }
});
</script>

<style lang="scss" scoped>
.chart-content {
  width: 100%;
  height: 100%;
}
</style>
