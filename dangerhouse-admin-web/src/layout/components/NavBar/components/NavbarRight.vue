<template>
  <div class="navbar-right">
    <template v-if="!isMobile">
      <button
        type="button"
        class="action-icon"
        title="切换全屏"
        @click="toggle"
      >
        <el-icon>
          <FullScreen v-if="!isFullscreen" />
          <Aim v-else />
        </el-icon>
      </button>
    </template>

    <el-dropdown
      class="user-entry"
      trigger="click"
      :teleported="true"
      @command="handleUserCommand"
    >
      <button type="button" class="user-card">
        <img :src="avatarSrc" class="user-avatar" alt="用户头像" />
        <div class="user-meta">
          <span class="user-name">{{ displayName }}</span>
          <span class="user-role">{{ displayRole }}</span>
        </div>
      </button>

      <template #dropdown>
        <el-dropdown-menu class="user-menu">
          <el-dropdown-item disabled>{{ displayName }}</el-dropdown-item>
          <el-dropdown-item command="change-password">
            修改密码
          </el-dropdown-item>
          <el-dropdown-item divided command="logout">
            退出登录
          </el-dropdown-item>
        </el-dropdown-menu>
      </template>
    </el-dropdown>

    <template v-if="defaultSettings.showSettings">
      <button
        type="button"
        class="action-icon"
        title="系统设置"
        @click="settingStore.settingsVisible = true"
      >
        <el-icon><Setting /></el-icon>
      </button>
    </template>

    <el-dialog
      v-model="passwordDialogVisible"
      title="修改密码"
      width="460px"
      align-center
      destroy-on-close
      append-to-body
      :close-on-click-modal="false"
      :close-on-press-escape="!passwordSubmitting"
      modal-class="navbar-dialog-overlay"
      class="navbar-password-dialog"
      @closed="resetPasswordForm"
    >
      <el-form
        ref="passwordFormRef"
        :model="passwordForm"
        :rules="passwordRules"
        label-position="top"
        class="password-form"
      >
        <el-form-item label="原密码" prop="oldPassword">
          <el-input
            v-model="passwordForm.oldPassword"
            type="password"
            show-password
            autocomplete="current-password"
            placeholder="请输入当前密码"
          />
        </el-form-item>
        <el-form-item label="新密码" prop="newPassword">
          <el-input
            v-model="passwordForm.newPassword"
            type="password"
            show-password
            autocomplete="new-password"
            placeholder="请输入 6-32 位新密码"
          />
        </el-form-item>
        <el-form-item label="确认新密码" prop="confirmPassword">
          <el-input
            v-model="passwordForm.confirmPassword"
            type="password"
            show-password
            autocomplete="new-password"
            placeholder="请再次输入新密码"
          />
        </el-form-item>
      </el-form>

      <template #footer>
        <div class="dialog-footer">
          <el-button @click="passwordDialogVisible = false">取消</el-button>
          <el-button
            type="primary"
            :loading="passwordSubmitting"
            @click="submitPasswordChange"
          >
            确认修改
          </el-button>
        </div>
      </template>
    </el-dialog>

    <el-dialog
      v-model="logoutDialogVisible"
      title="退出登录"
      width="400px"
      align-center
      append-to-body
      :close-on-click-modal="false"
      class="navbar-logout-dialog"
    >
      <div class="logout-dialog-body">确定注销并退出系统吗？</div>

      <template #footer>
        <div class="dialog-footer">
          <el-button @click="logoutDialogVisible = false">取消</el-button>
          <el-button type="primary" @click="confirmLogout">确定退出</el-button>
        </div>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { computed, nextTick, reactive, ref } from "vue";
import { useRoute, useRouter } from "vue-router";
import { useFullscreen } from "@vueuse/core";
import { ElMessage, type FormInstance, type FormRules } from "element-plus";
import { Aim, FullScreen, Setting } from "@element-plus/icons-vue";

import { updatePasswordApi } from "@/api/user";
import type { PasswordUpdateRequest } from "@/api/user/types";
import { DeviceEnum } from "@/enums/DeviceEnum";
import defaultSettings from "@/settings";
import {
  useAppStore,
  useSettingsStore,
  useTagsViewStore,
  useUserStore,
} from "@/store";
import { resolveAvatarUrl } from "@/utils/avatar";

const appStore = useAppStore();
const tagsViewStore = useTagsViewStore();
const userStore = useUserStore();
const settingStore = useSettingsStore();

const route = useRoute();
const router = useRouter();

const isMobile = computed(() => appStore.device === DeviceEnum.MOBILE);
const avatarSrc = computed(() => resolveAvatarUrl(userStore.user.avatar, 80));
const displayName = computed(() => {
  return userStore.user.nickname || userStore.user.username || "系统用户";
});
const displayRole = computed(() => {
  if (userStore.user.roles?.includes("ADMIN")) return "系统管理员";
  if (userStore.user.roles?.includes("INSPECTOR")) return "检测员";
  return "平台用户";
});

const passwordDialogVisible = ref(false);
const logoutDialogVisible = ref(false);
const passwordSubmitting = ref(false);
const passwordFormRef = ref<FormInstance>();
const passwordForm = reactive({
  oldPassword: "",
  newPassword: "",
  confirmPassword: "",
});

const passwordRules: FormRules = {
  oldPassword: [{ required: true, message: "请输入原密码", trigger: "blur" }],
  newPassword: [
    { required: true, message: "请输入新密码", trigger: "blur" },
    { min: 6, max: 32, message: "新密码长度需在 6-32 位之间", trigger: "blur" },
  ],
  confirmPassword: [
    { required: true, message: "请再次输入新密码", trigger: "blur" },
    {
      validator: (_rule, value, callback) => {
        if (!value) {
          callback(new Error("请再次输入新密码"));
          return;
        }
        if (value !== passwordForm.newPassword) {
          callback(new Error("两次输入的新密码不一致"));
          return;
        }
        callback();
      },
      trigger: "blur",
    },
  ],
};

const { isFullscreen, toggle } = useFullscreen();

function resetPasswordForm() {
  passwordForm.oldPassword = "";
  passwordForm.newPassword = "";
  passwordForm.confirmPassword = "";
  passwordFormRef.value?.clearValidate();
}

async function openPasswordDialog() {
  passwordDialogVisible.value = true;
  await nextTick();
  passwordFormRef.value?.clearValidate();
}

async function submitPasswordChange() {
  if (!passwordFormRef.value || passwordSubmitting.value) return;

  const valid = await passwordFormRef.value.validate().catch(() => false);
  if (!valid) return;

  passwordSubmitting.value = true;
  try {
    const payload: PasswordUpdateRequest = {
      oldPassword: passwordForm.oldPassword,
      newPassword: passwordForm.newPassword,
    };
    await updatePasswordApi(payload);
    ElMessage.success("密码修改成功，请使用新密码继续登录");
    passwordDialogVisible.value = false;
  } catch (error: any) {
    ElMessage.error(error?.message || "密码修改失败");
  } finally {
    passwordSubmitting.value = false;
  }
}

function openLogoutDialog() {
  logoutDialogVisible.value = true;
}

async function confirmLogout() {
  logoutDialogVisible.value = false;
  await userStore.logout();
  tagsViewStore.delAllViews();
  router.push(`/login?redirect=${route.fullPath}`);
}

async function handleUserCommand(command: string | number | object) {
  if (command === "change-password") {
    await openPasswordDialog();
    return;
  }

  if (command === "logout") {
    openLogoutDialog();
  }
}
</script>

<style lang="scss" scoped>
.navbar-right {
  display: flex;
  gap: 8px;
  align-items: center;
  padding-right: 10px;
}

.action-icon,
.user-card {
  border: none;
  outline: none;
}

.action-icon {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 40px;
  height: 40px;
  color: var(--el-text-color);
  cursor: pointer;
  background: transparent;
  border-radius: 12px;
  transition: all 0.2s ease;

  &:hover {
    background: rgb(15 23 42 / 8%);
  }

  .el-icon {
    font-size: 18px;
  }
}

.user-entry {
  height: 100%;
}

.user-card {
  display: flex;
  gap: 10px;
  align-items: center;
  height: calc($navbar-height - 12px);
  padding: 0 12px;
  margin: 6px 0;
  cursor: pointer;
  background: rgb(255 255 255 / 72%);
  border: 1px solid rgb(148 163 184 / 16%);
  border-radius: 14px;
  transition: all 0.2s ease;

  &:hover {
    background: rgb(255 255 255 / 96%);
    box-shadow: 0 8px 18px rgb(15 23 42 / 8%);
  }
}

.user-avatar {
  width: 34px;
  height: 34px;
  object-fit: cover;
  border-radius: 999px;
}

.user-meta {
  display: flex;
  flex-direction: column;
  align-items: flex-start;
  line-height: 1.2;
}

.user-name {
  max-width: 110px;
  overflow: hidden;
  font-size: 13px;
  font-weight: 600;
  color: #0f172a;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.user-role {
  font-size: 11px;
  color: #64748b;
}

.dialog-footer {
  display: flex;
  gap: 12px;
  justify-content: flex-end;
}

.password-form {
  margin-top: 6px;
}

.logout-dialog-body {
  font-size: 14px;
  color: #334155;
}

.layout-top,
.layout-mix {
  .action-icon,
  .el-icon {
    color: var(--el-color-white);
  }

  .user-card {
    background: rgb(255 255 255 / 10%);
    border-color: rgb(255 255 255 / 14%);
  }

  .user-card:hover {
    background: rgb(255 255 255 / 18%);
  }

  .user-name {
    color: #fff;
  }

  .user-role {
    color: rgb(255 255 255 / 72%);
  }
}

.dark .action-icon:hover {
  background: rgb(255 255 255 / 20%);
}

:deep(.el-dialog__body) {
  padding-top: 16px;
}
</style>
