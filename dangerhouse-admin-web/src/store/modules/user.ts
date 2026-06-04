import { ref } from "vue";
import { defineStore } from "pinia";

import { loginApi, logoutApi } from "@/api/auth";
import { getUserInfoApi } from "@/api/user";
import { resetRouter } from "@/router";
import { store } from "@/store";

import { LoginData } from "@/api/auth/types";
import { UserInfo } from "@/api/user/types";

function hasAdminRole(roles?: string[]) {
  return (
    Array.isArray(roles) &&
    roles.some((role) => role?.toUpperCase() === "ADMIN")
  );
}

function createEmptyUser(): UserInfo {
  return {
    id: 0,
    username: "",
    roles: [],
    perms: [],
  };
}

export const useUserStore = defineStore("user", () => {
  const user = ref<UserInfo>(createEmptyUser());

  function resetUserState() {
    user.value = createEmptyUser();
  }

  function login(loginData: LoginData) {
    return new Promise<void>((resolve, reject) => {
      loginApi(loginData)
        .then((response) => {
          const token = response?.data?.token;
          if (!token) {
            reject(new Error("登录成功但未获取到有效令牌"));
            return;
          }
          localStorage.setItem("token", token);
          resolve();
        })
        .catch((error) => {
          reject(error);
        });
    });
  }

  function getUserInfo() {
    return new Promise<UserInfo>((resolve, reject) => {
      getUserInfoApi()
        .then(({ data }) => {
          if (!data) {
            reject(new Error("获取用户信息失败，请重新登录"));
            return;
          }
          if (!data.roles || data.roles.length <= 0) {
            reject(new Error("当前账号未配置角色，无法登录后台"));
            return;
          }
          if (!hasAdminRole(data.roles)) {
            localStorage.removeItem("token");
            resetUserState();
            resetRouter();
            reject(new Error("当前账号无权登录后台，请使用管理员账号"));
            return;
          }

          const normalizedUser = {
            ...data,
            roles: data.roles || [],
            perms: (data as any).perms || [],
          } as UserInfo;
          Object.assign(user.value, normalizedUser);
          resolve(normalizedUser);
        })
        .catch((error) => {
          reject(error);
        });
    });
  }

  async function logout() {
    try {
      if (localStorage.getItem("token")) {
        await logoutApi();
      }
    } catch {
      // Ignore logout request failures and continue with local cleanup.
    } finally {
      localStorage.removeItem("token");
      resetUserState();
      resetRouter();
    }
  }

  function resetToken() {
    return new Promise<void>((resolve) => {
      localStorage.removeItem("token");
      resetUserState();
      resetRouter();
      resolve();
    });
  }

  return {
    user,
    login,
    getUserInfo,
    logout,
    resetToken,
  };
});

export function useUserStoreHook() {
  return useUserStore(store);
}
