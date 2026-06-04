<!-- 左侧边菜单：包括左侧布局(left)、顶部布局(all)、混合布局(left) -->
<template>
  <el-menu
    :default-active="currentRoute.path"
    :collapse="!appStore.sidebar.opened"
    :background-color="variables['menu-background']"
    :text-color="variables['menu-text']"
    :active-text-color="variables['menu-active-text']"
    :unique-opened="false"
    :collapse-transition="false"
    :mode="layout === 'top' ? 'horizontal' : 'vertical'"
    router
  >
    <SidebarMenuItem
      v-for="route in menuList"
      :key="route.path"
      :item="route"
      :base-path="resolvePath(route.path)"
      :is-collapse="!appStore.sidebar.opened"
    />
  </el-menu>
</template>

<script lang="ts" setup>
import { computed } from "vue";
import { useSettingsStore, useAppStore } from "@/store";
import { useRoute } from "vue-router";
import { isExternal } from "@/utils/index";
import path from "path-browserify";
import variables from "@/styles/variables.module.scss";

const settingsStore = useSettingsStore();
const appStore = useAppStore();
const currentRoute = useRoute();
const layout = computed(() => settingsStore.layout);
const props = defineProps({
  menuList: {
    required: true,
    default: () => {
      return [];
    },
    type: Array<any>,
  },
  basePath: {
    type: String,
    required: true,
  },
});

/**
 * 解析路径
 *
 * @param routePath 路由路径 /user
 */
function resolvePath(routePath: string) {
  if (isExternal(routePath)) {
    return routePath;
  }
  if (isExternal(props.basePath)) {
    return props.basePath;
  }

  // 完整绝对路径 = 父级路径(/system) + 路由路径(/user)
  const fullPath = path.resolve(props.basePath, routePath);
  return fullPath;
}
</script>

<style lang="scss" scoped>
:deep(.el-menu) {
  padding: 14px 10px 18px;
  background: transparent;
}

:deep(.el-menu-item),
:deep(.el-sub-menu__title) {
  height: 44px;
  margin-bottom: 8px;
  font-weight: 600;
  line-height: 44px;
  border-radius: 14px;
  transition: all 0.2s ease;
}

:deep(.el-menu-item:hover),
:deep(.el-sub-menu__title:hover) {
  color: #1d4ed8 !important;
  background: rgb(59 130 246 / 8%) !important;
}

:deep(.el-menu-item.is-active) {
  color: #1d4ed8 !important;
  background: linear-gradient(
    90deg,
    rgb(59 130 246 / 16%),
    rgb(59 130 246 / 8%)
  ) !important;
  box-shadow: inset 3px 0 0 #2563eb;
}

:deep(.el-sub-menu .el-menu-item) {
  min-width: auto;
  margin-left: 10px;
}

:deep(.el-menu--collapse) {
  padding-right: 8px;
  padding-left: 8px;
}
</style>
