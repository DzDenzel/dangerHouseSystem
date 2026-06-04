<template>
  <div class="logo-container">
    <transition enter-active-class="animate__animated animate__fadeInLeft">
      <router-link v-if="collapse" class="wh-full flex-center" to="/">
        <img :src="appLogo" class="logo-image" alt="系统Logo" />
      </router-link>

      <router-link v-else class="wh-full flex-center" to="/">
        <img :src="appLogo" class="logo-image logo-image-lg" alt="系统Logo" />
        <span class="logo-title">{{ defaultSettings.title }}</span>
      </router-link>
    </transition>
  </div>
</template>

<script lang="ts" setup>
import defaultSettings from "@/settings";
import appLogo from "@/assets/images/logo.png";

defineProps({
  collapse: {
    type: Boolean,
    required: true,
  },
});
</script>

<style lang="scss" scoped>
.logo-container {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 100%;
  height: $navbar-height;
  background: linear-gradient(
    180deg,
    rgb(255 255 255 / 92%),
    rgb(245 249 255 / 96%)
  );
  border-bottom: 1px solid rgb(148 163 184 / 16%);

  .logo-image {
    width: 28px;
    height: 28px;
    object-fit: cover;
    border-radius: 50%;
    box-shadow: 0 8px 18px rgb(15 23 42 / 10%);
  }

  .logo-image-lg {
    width: 30px;
    height: 30px;
  }

  .logo-title {
    flex-shrink: 0;
    margin-left: 12px;
    overflow: hidden;
    font-size: 14px;
    font-weight: 800;
    color: #2563eb;
    text-overflow: ellipsis;
    white-space: nowrap;
  }
}

.layout-top,
.layout-mix {
  .logo-container {
    width: $sidebar-width;
  }

  &.hideSidebar {
    .logo-container {
      width: $sidebar-width-collapsed;
    }
  }
}
</style>
