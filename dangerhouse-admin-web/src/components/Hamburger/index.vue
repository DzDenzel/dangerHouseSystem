<template>
  <div
    class="hamburger-trigger px-[15px] flex items-center justify-center color-[var(--el-text-color-regular)]"
    @click="toggleClick"
  >
    <el-icon class="hamburger" :class="{ 'is-active': isActive }">
      <Fold v-if="isActive" />
      <Expand v-else />
    </el-icon>
  </div>
</template>
<script setup lang="ts">
import { Expand, Fold } from "@element-plus/icons-vue";

defineProps({
  isActive: {
    required: true,
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(["toggleClick"]);

function toggleClick() {
  emit("toggleClick");
}
</script>

<style scoped lang="scss">
.hamburger-trigger {
  width: 44px;
  height: 44px;
  cursor: pointer;
  border-radius: 12px;
  transition: background-color 0.2s ease;

  &:hover {
    background: rgb(15 23 42 / 7%);
  }
}

.hamburger {
  font-size: 20px;
  vertical-align: middle;
  transition: transform 0.2s ease;
}

.hamburger.is-active {
  transform: rotate(0deg);
}
</style>
