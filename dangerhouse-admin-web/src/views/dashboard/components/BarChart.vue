<template>
  <div class="chart-content">
    <div :id="id" :class="className" :style="{ height, width }"></div>
  </div>
</template>

<script setup lang="ts">
import * as echarts from "echarts";
import { getDetectionListApi } from "@/api/detection";
import type { DetectionResponse } from "@/api/detection/types";

const props = defineProps({
  id: {
    type: String,
    default: "barChart",
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

function getRecentDays() {
  const days: string[] = [];
  for (let i = 6; i >= 0; i--) {
    const date = new Date();
    date.setDate(date.getDate() - i);
    days.push(
      `${date.getMonth() + 1}/${date.getDate().toString().padStart(2, "0")}`
    );
  }
  return days;
}

function getDayKey(value?: string) {
  if (!value) return "";
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return "";
  return `${date.getMonth() + 1}/${date.getDate().toString().padStart(2, "0")}`;
}

function buildOptions(records: DetectionResponse[]) {
  const labels = getRecentDays();
  const totalMap = new Map(labels.map((item) => [item, 0]));
  const completedMap = new Map(labels.map((item) => [item, 0]));
  const riskMap = new Map(labels.map((item) => [item, 0]));

  records.forEach((item) => {
    const dayKey = getDayKey(item.createdAt || item.detectTime);
    if (!totalMap.has(dayKey)) return;

    totalMap.set(dayKey, (totalMap.get(dayKey) || 0) + 1);
    if (item.status === "COMPLETED") {
      completedMap.set(dayKey, (completedMap.get(dayKey) || 0) + 1);
    }
    if (item.riskLevel === "C" || item.riskLevel === "D") {
      riskMap.set(dayKey, (riskMap.get(dayKey) || 0) + 1);
    }
  });

  return {
    grid: {
      left: "3%",
      right: "4%",
      bottom: "3%",
      containLabel: true,
    },
    tooltip: {
      trigger: "axis",
      axisPointer: {
        type: "cross",
        crossStyle: {
          color: "#999",
        },
      },
    },
    legend: {
      x: "center",
      y: "bottom",
      data: ["新增检测", "已完成", "中高风险"],
      textStyle: {
        color: "#666",
      },
    },
    xAxis: [
      {
        type: "category",
        data: labels,
        axisPointer: {
          type: "shadow",
        },
        axisLine: {
          lineStyle: {
            color: "#f0f0f0",
          },
        },
        axisLabel: {
          color: "#666",
        },
      },
    ],
    yAxis: [
      {
        type: "value",
        minInterval: 1,
        axisLabel: {
          color: "#666",
        },
        axisLine: {
          show: false,
        },
        splitLine: {
          lineStyle: {
            color: "#f0f0f0",
          },
        },
      },
    ],
    series: [
      {
        name: "新增检测",
        type: "bar",
        data: labels.map((item) => totalMap.get(item) || 0),
        barWidth: 16,
        itemStyle: {
          color: new echarts.graphic.LinearGradient(0, 0, 0, 1, [
            { offset: 0, color: "#6366f1" },
            { offset: 1, color: "#8b5cf6" },
          ]),
          borderRadius: [4, 4, 0, 0],
        },
      },
      {
        name: "已完成",
        type: "bar",
        data: labels.map((item) => completedMap.get(item) || 0),
        barWidth: 16,
        itemStyle: {
          color: new echarts.graphic.LinearGradient(0, 0, 0, 1, [
            { offset: 0, color: "#10b981" },
            { offset: 1, color: "#34d399" },
          ]),
          borderRadius: [4, 4, 0, 0],
        },
      },
      {
        name: "中高风险",
        type: "line",
        data: labels.map((item) => riskMap.get(item) || 0),
        smooth: true,
        lineStyle: {
          width: 3,
          color: "#ef4444",
        },
        itemStyle: {
          color: "#ef4444",
          borderWidth: 3,
        },
        symbol: "circle",
        symbolSize: 8,
      },
    ],
  };
}

async function loadChartData() {
  try {
    const res = await getDetectionListApi({ page: 1, size: 1000 });
    chart.value.setOption(buildOptions(res.data.records));
  } catch {
    chart.value.setOption(buildOptions([]));
  }
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
