<template>
  <div :class="{ hidden: hidden }" class="pagination">
    <el-pagination
      v-model:current-page="currentPage"
      v-model:page-size="pageSize"
      :background="background"
      :layout="layout"
      :page-sizes="pageSizes"
      :total="total"
      @size-change="handleSizeChange"
      @current-change="handleCurrentChange"
    />
  </div>
</template>

<script setup lang="ts">
import { useVModel } from "@vueuse/core";
import type { PropType } from "vue";

const props = defineProps({
  total: {
    required: true,
    type: Number as PropType<number>,
    default: 0,
  },
  currentPage: {
    type: Number,
    default: 1,
  },
  pageSize: {
    type: Number,
    default: 20,
  },
  pageSizes: {
    type: Array as PropType<number[]>,
    default() {
      return [10, 20, 30, 50];
    },
  },
  layout: {
    type: String,
    default: "prev, pager, next",
  },
  background: {
    type: Boolean,
    default: true,
  },
  autoScroll: {
    type: Boolean,
    default: true,
  },
  hidden: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits([
  "pagination-change",
  "update:currentPage",
  "update:pageSize",
]);

const currentPage = useVModel(props, "currentPage", emit);

const pageSize = useVModel(props, "pageSize", emit);

function handleSizeChange(val: number) {
  pageSize.value = val;
  emit("pagination-change", currentPage.value, val);
}

function handleCurrentChange(val: number) {
  currentPage.value = val;
  emit("pagination-change", val, pageSize.value);
}
</script>

<style lang="scss" scoped>
.pagination {
  padding: 12px;
  display: flex;
  justify-content: center;
  align-items: center;

  &.hidden {
    display: none;
  }

  :deep(.el-pagination) {
    display: flex;
    align-items: center;

    .el-pagination__prev,
    .el-pagination__next {
      background-color: white;
      border: 1px solid #e5e7eb;
      border-radius: 6px;
      margin: 0 4px;
      width: 40px;
      height: 40px;
      display: flex;
      align-items: center;
      justify-content: center;
      color: #6b7280;
      transition: all 0.3s ease;

      &:hover {
        border-color: #1e3a8a;
        color: #1e3a8a;
      }
    }

    .el-pagination__sizes,
    .el-pagination__total,
    .el-pagination__jump {
      display: none;
    }

    .el-pager {
      display: flex;
      align-items: center;

      li {
        margin: 0 4px;
        width: 40px;
        height: 40px;
        display: flex;
        align-items: center;
        justify-content: center;
        border-radius: 6px;
        cursor: pointer;
        transition: all 0.3s ease;
        font-size: 14px;
        font-weight: 500;

        &.active {
          background-color: #1e3a8a;
          color: white;
          font-weight: 600;
        }

        &:hover:not(.active) {
          background-color: #f3f4f6;
          color: #1e3a8a;
        }
      }
    }
  }
}
</style>
