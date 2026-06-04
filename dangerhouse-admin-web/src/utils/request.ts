import axios, {
  type AxiosResponse,
  type InternalAxiosRequestConfig,
} from "axios";
import { ElMessage, ElMessageBox } from "element-plus";

import { useUserStoreHook } from "@/store/modules/user";

const service = axios.create({
  baseURL: import.meta.env.VITE_APP_BASE_API,
  timeout: 50000,
  headers: { "Content-Type": "application/json;charset=utf-8" },
});

let reloginPromptVisible = false;

function getDisplayMessage(
  message?: string,
  fallback = "请求处理失败，请稍后重试"
) {
  return message && message.trim().length > 0 ? message : fallback;
}

service.interceptors.request.use(
  (config: InternalAxiosRequestConfig) => {
    const requestUrl = config.url || "";
    const isAuthRequest = requestUrl.includes("/auth/");
    const token = localStorage.getItem("token");

    if (token && !isAuthRequest) {
      config.headers.Authorization = `Bearer ${token}`;
    }

    return config;
  },
  (error: any) => Promise.reject(error)
);

service.interceptors.response.use(
  (response: AxiosResponse) => {
    const { code, message } = response.data || {};
    const successCodes = new Set([200, 0, "200", "0", "00000"]);

    if (successCodes.has(code)) {
      return response.data;
    }

    if (response.data instanceof ArrayBuffer) {
      return response;
    }

    const silent =
      (response.config as any)?.headers?.["X-Silent-Error"] === "true";
    const displayMessage = getDisplayMessage(message);

    if (!silent) {
      ElMessage.error(displayMessage);
    }

    return Promise.reject(new Error(displayMessage));
  },
  (error: any) => {
    const requestUrl = error.config?.url || "";
    const isAuthRequest = requestUrl.includes("/auth/");
    const isCaptchaRequest = requestUrl.includes("/auth/captcha");
    const silent =
      (error.config as any)?.headers?.["X-Silent-Error"] === "true";

    if (error.response && error.response.data) {
      const { code, message } = error.response.data;
      const displayMessage = getDisplayMessage(message);

      if (code === 401 && !isAuthRequest) {
        if (!reloginPromptVisible) {
          reloginPromptVisible = true;
          ElMessageBox.confirm("当前登录状态已失效，请重新登录", "提示", {
            confirmButtonText: "确定",
            cancelButtonText: "取消",
            type: "warning",
          })
            .then(() => {
              const userStore = useUserStoreHook();
              localStorage.removeItem("token");
              userStore.resetToken().then(() => {
                location.reload();
              });
            })
            .finally(() => {
              reloginPromptVisible = false;
            });
        }
      } else if (!isCaptchaRequest && !silent) {
        ElMessage.error(displayMessage);
      }

      return Promise.reject(new Error(displayMessage));
    }

    if (!isCaptchaRequest && !silent) {
      ElMessage.error(error.message || "网络连接失败，请检查服务是否正常");
    }

    return Promise.reject(
      new Error(error.message || "网络连接失败，请检查服务是否正常")
    );
  }
);

export default service;
