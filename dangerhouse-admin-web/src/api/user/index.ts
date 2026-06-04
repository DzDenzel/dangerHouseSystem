import request from "@/utils/request";
import type { AxiosPromise } from "axios";
import type {
  PasswordUpdateRequest,
  UserInfo,
  UserListQueryRequest,
  UserListResponse,
  UserUpdateRequest,
} from "./types";

export function getUserInfoApi(): AxiosPromise<UserInfo> {
  return request({
    url: "/user/profile",
    method: "get",
  });
}

export function updateUserProfileApi(
  data: UserUpdateRequest
): AxiosPromise<UserInfo> {
  return request({
    url: "/user/profile",
    method: "put",
    data,
  });
}

export function updatePasswordApi(
  data: PasswordUpdateRequest
): AxiosPromise<void> {
  return request({
    url: "/user/password",
    method: "put",
    data,
  });
}

export function uploadAvatarApi(file: File): AxiosPromise<string> {
  const formData = new FormData();
  formData.append("file", file);

  return request({
    url: "/user/avatar",
    method: "post",
    data: formData,
    headers: {
      "Content-Type": "multipart/form-data",
    },
  });
}

export function getUserListApi(
  queryParams?: UserListQueryRequest
): AxiosPromise<PageResponse<UserListResponse[]>> {
  return request({
    url: "/users",
    method: "get",
    params: queryParams,
  });
}

export function getUserDetailApi(
  userId: number,
  silent = false
): AxiosPromise<UserInfo> {
  return request({
    url: `/users/${userId}`,
    method: "get",
    headers: silent ? { "X-Silent-Error": "true" } : undefined,
  });
}

export function updateUserStatusApi(
  userId: number,
  status: number
): AxiosPromise<void> {
  return request({
    url: `/users/${userId}/status`,
    method: "put",
    data: { status },
  });
}

export function updateInspectorRoleApi(
  userId: number,
  inspector: boolean
): AxiosPromise<void> {
  return request({
    url: `/users/${userId}/inspector`,
    method: "put",
    data: { inspector },
  });
}
