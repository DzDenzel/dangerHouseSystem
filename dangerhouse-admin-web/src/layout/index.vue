<template>
  <div class="wh-full" :class="classObj">
    <!-- Mobile overlay -->
    <div
      v-if="isMobile && isOpenSidebar"
      class="wh-full fixed-lt z-999 bg-black bg-opacity-30"
      @click="handleOutsideClick"
    ></div>

    <!-- Shared sidebar -->
    <Sidebar class="sidebar-container" />

    <!-- Mixed layout -->
    <div v-if="layout === LayoutEnum.MIX" class="mix-container">
      <div class="mix-container__left">
        <SidebarMenu :menu-list="mixLeftMenus" :base-path="activeTopMenuPath" />
        <div class="sidebar-toggle">
          <hamburger
            :is-active="appStore.sidebar.opened"
            @toggle-click="toggleSidebar"
          />
        </div>
      </div>

      <div :class="{ hasTagsView: showTagsView }" class="main-container">
        <div :class="{ 'fixed-header': fixedHeader }">
          <TagsView v-if="showTagsView" />
        </div>
        <AppMain />
        <Settings v-if="defaultSettings.showSettings" />
      </div>
    </div>

    <!-- Left or top layout -->
    <div v-else :class="{ hasTagsView: showTagsView }" class="main-container">
      <div :class="{ 'fixed-header': fixedHeader }">
        <NavBar v-if="layout === 'left'" />
        <TagsView v-if="showTagsView" />
      </div>
      <AppMain />
      <Settings v-if="defaultSettings.showSettings" />
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed, watch, watchEffect } from "vue";
import { useWindowSize } from "@vueuse/core";
import { useRoute } from "vue-router";
import { useAppStore, useSettingsStore, usePermissionStore } from "@/store";
import defaultSettings from "@/settings";
import { DeviceEnum } from "@/enums/DeviceEnum";
import { LayoutEnum } from "@/enums/LayoutEnum";

const appStore = useAppStore();
const settingsStore = useSettingsStore();
const permissionStore = usePermissionStore();
const { width } = useWindowSize();

const WIDTH_DESKTOP = 992;
const isMobile = computed(() => appStore.device === DeviceEnum.MOBILE);
const isOpenSidebar = computed(() => appStore.sidebar.opened);
const fixedHeader = computed(() => settingsStore.fixedHeader);
const showTagsView = computed(() => settingsStore.tagsView);
const layout = computed(() => settingsStore.layout);
const activeTopMenuPath = computed(() => appStore.activeTopMenuPath);
const mixLeftMenus = computed(() => permissionStore.mixLeftMenus);

watch(
  () => activeTopMenuPath.value,
  (newVal) => {
    permissionStore.setMixLeftMenus(newVal);
  },
  {
    deep: true,
    immediate: true,
  }
);

const classObj = computed(() => ({
  hideSidebar: !appStore.sidebar.opened,
  openSidebar: appStore.sidebar.opened,
  mobile: appStore.device === DeviceEnum.MOBILE,
  [`layout-${settingsStore.layout}`]: true,
}));

watchEffect(() => {
  appStore.toggleDevice(
    width.value < WIDTH_DESKTOP ? DeviceEnum.MOBILE : DeviceEnum.DESKTOP
  );
  if (width.value >= WIDTH_DESKTOP) {
    appStore.openSideBar();
  } else {
    appStore.closeSideBar();
  }
});

function handleOutsideClick() {
  appStore.closeSideBar();
}

function toggleSidebar() {
  appStore.toggleSidebar();
}

const route = useRoute();
watch(route, () => {
  if (isMobile.value && isOpenSidebar.value) {
    appStore.closeSideBar();
  }
});
</script>

<style lang="scss" scoped>
.fixed-header {
  position: fixed;
  top: 0;
  right: 0;
  z-index: 9;
  width: calc(100% - $sidebar-width);
  transition: width 0.28s;
}

.sidebar-container {
  position: fixed;
  top: 0;
  bottom: 0;
  left: 0;
  z-index: 999;
  width: $sidebar-width;
  height: 100%;
  overflow: hidden;
  background: linear-gradient(
    180deg,
    rgb(248 251 255 / 98%),
    rgb(240 245 251 / 96%)
  );
  border-right: 1px solid rgb(148 163 184 / 16%);
  box-shadow: 10px 0 30px rgb(15 23 42 / 4%);
  transition: width 0.28s;

  :deep(.el-menu) {
    border: none;
  }
}

.main-container {
  position: relative;
  min-height: 100%;
  margin-left: $sidebar-width;
  background: transparent;
  transition: margin-left 0.28s;
}

.layout-top {
  .fixed-header {
    top: $navbar-height;
    width: 100%;
  }

  .sidebar-container {
    z-index: 999;
    display: flex;
    width: 100% !important;
    height: $navbar-height;

    :deep(.el-scrollbar) {
      flex: 1;
      height: $navbar-height;
    }

    :deep(.el-menu-item),
    :deep(.el-sub-menu__title),
    :deep(.el-menu--horizontal) {
      height: $navbar-height;
      line-height: $navbar-height;
    }

    :deep(.el-menu--collapse) {
      width: 100%;
    }
  }

  .main-container {
    min-height: calc(100vh - $navbar-height);
    padding-top: $navbar-height;
    margin-left: 0;
  }
}

.layout-mix {
  .sidebar-container {
    width: 100% !important;
    height: $navbar-height;

    :deep(.el-scrollbar) {
      flex: 1;
      height: $navbar-height;
    }

    :deep(.el-menu-item),
    :deep(.el-sub-menu__title),
    :deep(.el-menu--horizontal) {
      height: $navbar-height;
      line-height: $navbar-height;
    }

    :deep(.el-menu--horizontal.el-menu) {
      border: none;
    }
  }

  .mix-container {
    display: flex;
    height: 100%;
    padding-top: $navbar-height;

    .mix-container__left {
      position: relative;
      width: $sidebar-width;
      height: 100%;

      :deep(.el-menu) {
        height: 100%;
        border: none;
      }

      .sidebar-toggle {
        position: absolute;
        bottom: 0;
        display: flex;
        align-items: center;
        justify-content: center;
        width: 100%;
        height: 50px;
        line-height: 50px;
        box-shadow: 0 0 6px -2px var(--el-color-primary);

        div:hover {
          background-color: var(--menu-background);
        }

        :deep(svg) {
          color: var(--el-color-primary) !important;
        }
      }
    }

    .main-container {
      flex: 1;
      min-width: 0;
      margin-left: 0;

      .fixed-header {
        top: $navbar-height;
      }
    }
  }
}

.hideSidebar {
  .fixed-header {
    left: $sidebar-width-collapsed;
    width: calc(100% - $sidebar-width-collapsed);
  }

  .main-container {
    margin-left: $sidebar-width-collapsed;
  }

  &.layout-top {
    .fixed-header {
      left: 0;
      width: 100%;
    }

    .main-container {
      margin-left: 0;
    }
  }

  &.layout-mix {
    .fixed-header {
      left: $sidebar-width-collapsed;
      width: calc(100% - $sidebar-width-collapsed);
    }

    .sidebar-container {
      width: 100% !important;
    }

    .mix-container {
      .mix-container__left {
        width: $sidebar-width-collapsed;
      }
    }
  }
}

.layout-left.hideSidebar {
  .sidebar-container {
    width: $sidebar-width-collapsed !important;
  }

  .main-container {
    margin-left: $sidebar-width-collapsed;
  }

  &.mobile {
    .sidebar-container {
      pointer-events: none;
      transition-duration: 0.3s;
      transform: translate3d(-210px, 0, 0);
    }

    .main-container {
      margin-left: 0;
    }
  }
}

.mobile {
  .fixed-header {
    left: 0;
    width: 100%;
  }

  .main-container {
    margin-left: 0;
  }

  &.layout-top {
    .sidebar-container {
      z-index: 999;
      display: flex;
      width: 100% !important;
      height: $navbar-height;

      :deep(.el-scrollbar) {
        flex: 1;
        min-width: 0;
        height: $navbar-height;
      }
    }

    .main-container {
      padding-top: $navbar-height;
      margin-left: 0;
      overflow: hidden;
    }

    // 移动端覆盖顶部布局中的菜单项高度
    --el-menu-item-height: #{$navbar-height};
  }
}
</style>
