<template>
  <div
    class="login-page"
    :class="{ 'is-stage-two': isStageTwo, 'is-dark-theme': isDarkTheme }"
  >
    <div class="background-layer"></div>
    <div class="ambient ambient-a"></div>
    <div class="ambient ambient-b"></div>

    <div class="login-shell">
      <section class="welcome-panel">
        <div class="welcome-content">
          <img class="system-logo" :src="logo" alt="危房智诊管理系统" />
          <div class="welcome-copy">
            <p v-if="!isStageTwo" class="welcome-lead">欢迎来到</p>
            <h1 class="welcome-title">
              <span>{{ typedWelcomeText }}</span>
              <i class="cursor"></i>
            </h1>
          </div>
        </div>
      </section>

      <transition name="login-panel-transition">
        <section v-if="isStageTwo" class="login-panel">
          <div class="login-card">
            <div class="card-header">
              <div>
                <h2>登录系统</h2>
                <p>请输入账号和密码进入管理平台</p>
              </div>
              <span class="card-badge">管理端</span>
            </div>

            <el-form
              ref="loginFormRef"
              :model="loginForm"
              :rules="loginRules"
              class="login-form"
              @keyup.enter="handleLogin"
            >
              <el-form-item prop="account">
                <el-input
                  v-model="loginForm.account"
                  size="large"
                  placeholder="请输入账号"
                  autocomplete="username"
                />
              </el-form-item>

              <el-tooltip
                :visible="capsLockVisible"
                content="大写锁定已开启"
                placement="right"
              >
                <el-form-item prop="password">
                  <el-input
                    v-model="loginForm.password"
                    :type="passwordVisible ? 'text' : 'password'"
                    size="large"
                    placeholder="请输入密码"
                    autocomplete="current-password"
                    @keyup="checkCapsLock"
                  >
                    <template #suffix>
                      <el-button
                        class="password-toggle"
                        link
                        @click="passwordVisible = !passwordVisible"
                      >
                        {{ passwordVisible ? "隐藏" : "显示" }}
                      </el-button>
                    </template>
                  </el-input>
                </el-form-item>
              </el-tooltip>

              <el-form-item>
                <div class="login-options">
                  <el-checkbox v-model="rememberMe">记住我</el-checkbox>
                </div>
              </el-form-item>

              <el-form-item>
                <el-button
                  class="login-button"
                  type="primary"
                  size="large"
                  :loading="loading"
                  @click="handleLogin"
                >
                  立即登录
                </el-button>
              </el-form-item>
            </el-form>
          </div>
        </section>
      </transition>

      <el-button class="theme-switch" circle @click="toggleTheme">
        {{ isDarkTheme ? "浅" : "深" }}
      </el-button>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed, onBeforeUnmount, onMounted, reactive, ref } from "vue";
import { useRouter } from "vue-router";
import type { FormInstance, FormRules } from "element-plus";
import { ElMessage } from "element-plus";

import logo from "@/assets/images/logo.png";
import type { LoginData } from "@/api/auth/types";
import { ThemeEnum } from "@/enums/ThemeEnum";
import { useSettingsStore } from "@/store/modules/settings";
import { useUserStore } from "@/store/modules/user";

const router = useRouter();
const settingsStore = useSettingsStore();
const userStore = useUserStore();

const loginFormRef = ref<FormInstance>();
const loading = ref(false);
const passwordVisible = ref(false);
const capsLockVisible = ref(false);
const typedWelcomeText = ref("");
const isStageTwo = ref(false);
const rememberMe = ref(false);

const loginForm = reactive<LoginData>({
  account: "",
  password: "",
});

const firstStageText = "欢迎来到危房智诊管理系统";
const secondStageText = "危房智诊管理系统";
const rememberKey = "dangerhouse_login_remember";
const loginRedirectKey = "dangerhouse_login_redirect";

let typingTimer: ReturnType<typeof setInterval> | undefined;
let stageTimer: ReturnType<typeof setTimeout> | undefined;
let leadTimer: ReturnType<typeof setTimeout> | undefined;

const redirectPath = computed(() => {
  const redirect = sessionStorage.getItem(loginRedirectKey);
  return redirect && redirect.length > 0 ? redirect : "/dashboard";
});

const isDarkTheme = computed(() => settingsStore.theme === ThemeEnum.DARK);

const loginRules = reactive<FormRules<LoginData>>({
  account: [{ required: true, message: "请输入账号", trigger: "blur" }],
  password: [
    { required: true, message: "请输入密码", trigger: "blur" },
    { min: 6, message: "密码不能少于6位", trigger: "blur" },
  ],
});

function typeText(text: string, speed = 80) {
  if (typingTimer) {
    clearInterval(typingTimer);
  }

  let index = 0;
  typedWelcomeText.value = "";

  typingTimer = setInterval(() => {
    if (index >= text.length) {
      if (typingTimer) {
        clearInterval(typingTimer);
      }
      return;
    }

    typedWelcomeText.value += text[index];
    index += 1;
  }, speed);
}

function checkCapsLock(event: KeyboardEvent) {
  if (event.getModifierState) {
    capsLockVisible.value = event.getModifierState("CapsLock");
  }
}

function toggleTheme() {
  settingsStore.changeTheme(
    isDarkTheme.value ? ThemeEnum.LIGHT : ThemeEnum.DARK
  );
}

function loadRememberedLogin() {
  const cache = localStorage.getItem(rememberKey);
  if (!cache) return;

  try {
    const parsed = JSON.parse(cache) as {
      account?: string;
      expiresAt?: number;
    };

    if (!parsed.expiresAt || parsed.expiresAt < Date.now()) {
      localStorage.removeItem(rememberKey);
      return;
    }

    loginForm.account = parsed.account || "";
    rememberMe.value = Boolean(parsed.account);
  } catch {
    localStorage.removeItem(rememberKey);
  }
}

function syncRememberedLogin() {
  if (!rememberMe.value) {
    localStorage.removeItem(rememberKey);
    return;
  }

  localStorage.setItem(
    rememberKey,
    JSON.stringify({
      account: loginForm.account,
      expiresAt: Date.now() + 3 * 24 * 60 * 60 * 1000,
    })
  );
}

async function handleLogin() {
  if (!loginFormRef.value || loading.value) return;

  try {
    const valid = await loginFormRef.value.validate();
    if (!valid) return;

    loading.value = true;
    await userStore.login({
      ...loginForm,
      rememberMe: rememberMe.value,
      clientType: "WEB",
    });
    syncRememberedLogin();
    await userStore.getUserInfo();
    sessionStorage.removeItem(loginRedirectKey);
    router.replace(redirectPath.value);
  } catch (error: any) {
    if (error) {
      ElMessage.error(error?.message || "登录失败，请检查账号和密码");
    }
  } finally {
    loading.value = false;
  }
}

onMounted(() => {
  loadRememberedLogin();
  typeText(firstStageText, 72);

  leadTimer = setTimeout(() => {
    isStageTwo.value = true;
    typeText(secondStageText, 56);
  }, 1700);

  stageTimer = setTimeout(() => {
    isStageTwo.value = true;
  }, 1700);
});

onBeforeUnmount(() => {
  if (typingTimer) {
    clearInterval(typingTimer);
  }
  if (leadTimer) {
    clearTimeout(leadTimer);
  }
  if (stageTimer) {
    clearTimeout(stageTimer);
  }
});
</script>

<style scoped lang="scss">
.login-page {
  position: fixed;
  inset: 0;
  width: 100vw;
  min-height: 100vh;
  overflow: auto;
  background: #f6f8fb;
}

.background-layer {
  position: absolute;
  inset: 0;
  background:
    radial-gradient(circle at 20% 18%, rgb(35 198 188 / 10%), transparent 24%),
    radial-gradient(circle at 82% 68%, rgb(35 198 188 / 7%), transparent 26%),
    linear-gradient(135deg, #fff 0%, #f4f8fa 52%, #eff5f7 100%);
}

.ambient {
  position: absolute;
  filter: blur(28px);
  border-radius: 999px;
  opacity: 0.55;
}

.ambient-a {
  top: 14%;
  left: 11%;
  width: 240px;
  height: 240px;
  background: rgb(54 212 203 / 12%);
}

.ambient-b {
  right: 13%;
  bottom: 16%;
  width: 280px;
  height: 280px;
  background: rgb(31 170 191 / 10%);
}

.login-shell {
  position: relative;
  z-index: 1;
  display: grid;
  grid-template-columns: 1fr;
  align-items: center;
  width: min(1380px, 100%);
  min-height: 100vh;
  margin: 0 auto;
  transition: grid-template-columns 0.85s ease;
}

.welcome-panel {
  display: flex;
  align-items: center;
  justify-content: center;
  min-height: 100vh;
  padding: 52px;
  transition: padding 0.85s ease;
}

.welcome-content {
  display: flex;
  flex-direction: column;
  gap: 26px;
  align-items: center;
  color: #102630;
  text-align: center;
  transition:
    transform 0.9s cubic-bezier(0.22, 1, 0.36, 1),
    align-items 0.9s cubic-bezier(0.22, 1, 0.36, 1),
    text-align 0.9s cubic-bezier(0.22, 1, 0.36, 1);
  transform: translateX(0) scale(1);
  transform-origin: center center;
}

.system-logo {
  width: 188px;
  height: 188px;
  object-fit: cover;
  border-radius: 50%;
  box-shadow: 0 28px 70px rgb(14 49 57 / 14%);
  transition:
    width 0.9s cubic-bezier(0.22, 1, 0.36, 1),
    height 0.9s cubic-bezier(0.22, 1, 0.36, 1),
    box-shadow 0.9s cubic-bezier(0.22, 1, 0.36, 1);
}

.welcome-copy {
  display: flex;
  flex-direction: column;
  gap: 10px;
  align-items: center;
}

.welcome-lead {
  margin: 0;
  font-size: clamp(28px, 2.2vw, 34px);
  font-weight: 600;
  color: #3a5660;
  letter-spacing: 0.06em;
  animation: fade-in 0.35s ease;
}

.welcome-title {
  display: flex;
  gap: 6px;
  align-items: center;
  justify-content: center;
  min-height: 88px;
  margin: 0;
  font-size: clamp(42px, 4.9vw, 74px);
  font-weight: 700;
  line-height: 1.18;
  color: #102630;
  letter-spacing: 0.01em;
  transition:
    font-size 0.9s cubic-bezier(0.22, 1, 0.36, 1),
    justify-content 0.9s cubic-bezier(0.22, 1, 0.36, 1);
}

.cursor {
  width: 2px;
  height: 0.95em;
  background: #18c4c0;
  animation: blink 1s step-end infinite;
}

.login-panel {
  display: flex;
  justify-content: center;
  padding: 48px 92px 48px 36px;
}

.login-card {
  width: min(482px, 100%);
  padding: 44px 38px 34px;
  background: rgb(255 255 255 / 86%);
  backdrop-filter: blur(16px);
  border: 1px solid rgb(14 37 47 / 8%);
  border-radius: 30px;
  box-shadow:
    0 28px 90px rgb(13 35 45 / 12%),
    inset 0 1px 0 rgb(255 255 255 / 58%);
}

.card-header {
  display: flex;
  gap: 16px;
  align-items: flex-start;
  justify-content: space-between;
  margin-bottom: 30px;

  h2 {
    margin: 0 0 8px;
    font-size: 32px;
    line-height: 1.2;
    color: #10232d;
  }

  p {
    margin: 0;
    font-size: 14px;
    line-height: 1.6;
    color: rgb(16 35 45 / 62%);
  }
}

.card-badge {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  min-width: 72px;
  height: 32px;
  padding: 0 12px;
  font-size: 13px;
  font-weight: 600;
  color: #109f9f;
  background: rgb(24 196 192 / 8%);
  border: 1px solid rgb(24 196 192 / 20%);
  border-radius: 999px;
}

.login-form :deep(.el-form-item) {
  margin-bottom: 20px;
}

.login-form :deep(.el-input__wrapper) {
  min-height: 56px;
  background: rgb(16 35 45 / 4%);
  border-radius: 18px;
  box-shadow: inset 0 0 0 1px rgb(16 35 45 / 8%);
}

.login-form :deep(.el-input__inner) {
  color: #10232d;
}

.login-form :deep(.el-input__inner::placeholder) {
  color: rgb(16 35 45 / 40%);
}

.password-toggle {
  padding: 0;
  color: #18c4c0;
}

.login-options {
  display: flex;
  align-items: center;
  justify-content: flex-start;
  width: 100%;
}

.login-options :deep(.el-checkbox__label) {
  color: #10232d;
}

.login-button {
  width: 100%;
  height: 56px;
  font-size: 17px;
  font-weight: 600;
  background: linear-gradient(135deg, #26d8cf 0%, #16bfbe 100%);
  border: none;
  border-radius: 18px;
  box-shadow: 0 18px 34px rgb(22 191 190 / 24%);
}

.theme-switch {
  position: absolute;
  top: 28px;
  right: 28px;
  z-index: 2;
  width: 42px;
  height: 42px;
  color: #10232d;
  background: rgb(255 255 255 / 88%);
  border: 1px solid rgb(16 35 45 / 12%);
  box-shadow: 0 14px 36px rgb(16 35 45 / 10%);
}

.login-panel-transition-enter-active {
  transition: all 0.78s cubic-bezier(0.22, 1, 0.36, 1);
  transition-delay: 0.08s;
}

.login-panel-transition-enter-from {
  opacity: 0;
  transform: translateY(96px);
}

.login-panel-transition-enter-to {
  opacity: 1;
  transform: translateY(0);
}

.is-stage-two {
  .login-shell {
    grid-template-columns: minmax(560px, 1fr) 520px;
  }

  .welcome-panel {
    justify-content: flex-start;
    padding-right: 36px;
    padding-left: clamp(96px, 10vw, 176px);
  }

  .welcome-content {
    align-items: flex-start;
    text-align: left;
    transform: translateX(0) scale(0.8);
    transform-origin: left center;
  }

  .welcome-copy {
    align-items: flex-start;
  }

  .welcome-title {
    justify-content: flex-start;
    max-width: 760px;
    min-height: auto;
    font-size: clamp(34px, 3vw, 50px);
  }

  .system-logo {
    width: 128px;
    height: 128px;
    box-shadow: 0 18px 42px rgb(14 49 57 / 10%);
  }
}

.login-page.is-dark-theme {
  background: #07181f;
}

.login-page.is-dark-theme .background-layer {
  background:
    radial-gradient(circle at 20% 18%, rgb(63 230 220 / 10%), transparent 24%),
    radial-gradient(circle at 82% 68%, rgb(63 230 220 / 8%), transparent 26%),
    linear-gradient(135deg, #081f27 0%, #0b2730 52%, #0b222a 100%);
}

.login-page.is-dark-theme .ambient-a {
  background: rgb(62 239 227 / 12%);
}

.login-page.is-dark-theme .ambient-b {
  background: rgb(42 161 196 / 12%);
}

.login-page.is-dark-theme .welcome-content,
.login-page.is-dark-theme .welcome-title {
  color: #eff8f8;
}

.login-page.is-dark-theme .welcome-lead {
  color: rgb(232 247 248 / 72%);
}

.login-page.is-dark-theme .cursor {
  background: #56efe1;
}

.login-page.is-dark-theme .system-logo {
  box-shadow: 0 28px 70px rgb(0 0 0 / 24%);
}

.login-page.is-dark-theme .login-card {
  background: rgb(7 20 25 / 82%);
  border-color: rgb(255 255 255 / 8%);
  box-shadow:
    0 28px 90px rgb(0 0 0 / 24%),
    inset 0 1px 0 rgb(255 255 255 / 5%);
}

.login-page.is-dark-theme .card-header h2 {
  color: #f3fbfb;
}

.login-page.is-dark-theme .card-header p {
  color: rgb(230 244 245 / 68%);
}

.login-page.is-dark-theme .card-badge {
  color: #56efe1;
  background: rgb(86 239 225 / 8%);
  border-color: rgb(86 239 225 / 18%);
}

.login-page.is-dark-theme .login-form :deep(.el-input__wrapper) {
  background: rgb(255 255 255 / 6%);
  box-shadow: inset 0 0 0 1px rgb(255 255 255 / 8%);
}

.login-page.is-dark-theme .login-form :deep(.el-input__inner) {
  color: #f4fbfb;
}

.login-page.is-dark-theme .login-form :deep(.el-input__inner::placeholder) {
  color: rgb(228 242 244 / 40%);
}

.login-page.is-dark-theme .password-toggle {
  color: #56efe1;
}

.login-page.is-dark-theme .login-options :deep(.el-checkbox__label) {
  color: #eff8f8;
}

.login-page.is-dark-theme .login-button {
  box-shadow: 0 18px 34px rgb(22 191 190 / 18%);
}

.login-page.is-dark-theme .theme-switch {
  color: #eff8f8;
  background: rgb(10 24 31 / 88%);
  border-color: rgb(255 255 255 / 10%);
  box-shadow: 0 14px 36px rgb(0 0 0 / 22%);
}

@keyframes blink {
  50% {
    opacity: 0;
  }
}

@keyframes fade-in {
  from {
    opacity: 0;
    transform: translateY(8px);
  }

  to {
    opacity: 1;
    transform: translateY(0);
  }
}

@media (width <= 980px) {
  .is-stage-two {
    .login-shell {
      grid-template-columns: 1fr;
    }

    .welcome-panel {
      justify-content: center;
      min-height: auto;
      padding: 76px 24px 24px;
    }

    .welcome-content {
      align-items: center;
      text-align: center;
      transform: none;
    }

    .welcome-copy {
      align-items: center;
    }

    .welcome-title {
      justify-content: center;
      max-width: none;
      font-size: clamp(30px, 8vw, 44px);
    }

    .system-logo {
      width: 126px;
      height: 126px;
    }
  }

  .welcome-panel {
    padding: 34px 24px;
  }

  .login-panel {
    padding: 0 24px 48px;
  }

  .login-card {
    width: 100%;
    max-width: 480px;
  }
}

@media (width <= 640px) {
  .ambient {
    display: none;
  }

  .welcome-panel {
    padding: 24px 16px;
  }

  .welcome-title {
    min-height: 68px;
    font-size: clamp(28px, 9vw, 40px);
  }

  .system-logo {
    width: 144px;
    height: 144px;
  }

  .login-panel {
    padding: 0 16px 32px;
  }

  .login-card {
    padding: 30px 22px 24px;
    border-radius: 24px;
  }

  .card-header {
    flex-direction: column;
    align-items: flex-start;
  }

  .theme-switch {
    top: 18px;
    right: 18px;
  }
}
</style>
