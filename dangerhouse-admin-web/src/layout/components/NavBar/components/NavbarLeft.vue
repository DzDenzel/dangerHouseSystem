<template>
  <div class="navbar-left">
    <div class="nav-toggle">
      <hamburger
        :is-active="appStore.sidebar.opened"
        @toggle-click="toggleSideBar"
      />
    </div>
    <div class="nav-context">
      <div class="system-title">危房智诊管理系统</div>
      <breadcrumb />
    </div>
  </div>
</template>

<script setup lang="ts">
import { useAppStore } from "@/store";

const appStore = useAppStore();

function toggleSideBar() {
  appStore.toggleSidebar();
}
</script>

<style scoped lang="scss">
.navbar-left {
  display: flex;
  align-items: center;
  min-width: 0;
}

.nav-toggle {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 52px;
  height: $navbar-height;
}

.nav-context {
  display: flex;
  flex-direction: column;
  justify-content: center;
  min-width: 0;
}

.system-title {
  margin-bottom: 2px;
  overflow: hidden;
  font-size: 14px;
  font-weight: 700;
  color: #0f172a;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.layout-top .system-title,
.layout-mix .system-title {
  color: #fff;
}
</style>
