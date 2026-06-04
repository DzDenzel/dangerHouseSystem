<template>
  <div class="chart-content">
    <div :id="id" :class="className" :style="{ height, width }"></div>
  </div>
</template>

<script setup lang="ts">
import * as echarts from "echarts";
import { getDetectionListApi } from "@/api/detection";

const props = defineProps({
  id: {
    type: String,
    default: "pieChart",
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

const riskLevelLabels = [
  "A级(无风险)",
  "B级(低风险)",
  "C级(中风险)",
  "D级(高风险)",
];
const riskLevelColors = ["#28A745", "#FFC107", "#FD7E14", "#DC3545"];

function buildOptions(values: number[]) {
  return {
    grid: {
      left: "3%",
      right: "4%",
      bottom: "3%",
      containLabel: true,
    },
    tooltip: {
      trigger: "item",
    },
    legend: {
      top: "bottom",
      textStyle: {
        color: "#666",
      },
    },
    series: [
      {
        name: "检测等级",
        type: "pie",
        radius: [60, 100],
        center: ["50%", "50%"],
        roseType: "radius",
        itemStyle: {
          borderRadius: 8,
          borderColor: "#fff",
          borderWidth: 2,
          color: function (params: any) {
            return riskLevelColors[params.dataIndex];
          },
        },
        label: {
          show: false,
        },
        labelLine: {
          show: false,
        },
        data: riskLevelLabels.map((name, index) => ({
          value: values[index],
          name,
        })),
      },
    ],
  };
}

async function loadChartData() {
  const counts = { A: 0, B: 0, C: 0, D: 0 };

  try {
    const res = await getDetectionListApi({ page: 1, size: 1000 });
    res.data.records.forEach((item) => {
      if (item.riskLevel && item.riskLevel in counts) {
        counts[item.riskLevel as keyof typeof counts] += 1;
      }
    });
  } catch {
    // 忽略错误，回退到零值
  }

  chart.value.setOption(buildOptions([counts.A, counts.B, counts.C, counts.D]));
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
