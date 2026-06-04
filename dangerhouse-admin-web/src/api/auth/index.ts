import request from "@/utils/request";
import { AxiosPromise } from "axios";
import { LoginData, LoginResult, RegisterData, RegisterResult } from "./types";

/**
 * 登录API
 *
 * @param data {LoginData}
 * @returns
 */
export function loginApi(data: LoginData): AxiosPromise<LoginResult> {
  return request({
    url: "/auth/login",
    method: "post",
    headers: {
      "X-Silent-Error": "true",
    },
    data: {
      account: data.account,
      password: data.password,
      rememberMe: data.rememberMe ?? false,
      clientType: data.clientType ?? "WEB",
    },
  });
}

/**
 * 注册API
 */
export function registerApi(data: RegisterData): AxiosPromise<RegisterResult> {
  return request({
    url: "/auth/register",
    method: "post",
    data: data,
  });
}

export function logoutApi(): AxiosPromise<void> {
  return request({
    url: "/auth/logout",
    method: "post",
    headers: {
      "X-Silent-Error": "true",
    },
  });
}

/**
 * 检查用户名
 */
export function checkUsernameApi(username: string): AxiosPromise<boolean> {
  return request({
    url: `/auth/check-username/${username}`,
    method: "get",
  });
}
