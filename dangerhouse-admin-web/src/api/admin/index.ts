import request from "@/utils/request";
import { AxiosPromise } from "axios";
import {
  AiModelResponse,
  DashboardStatsResponse,
  OperationLogQueryRequest,
  OperationLogResponse,
} from "./types";

export function getDashboardStatsApi(): AxiosPromise<DashboardStatsResponse> {
  return request({
    url: "/admin/dashboard",
    method: "get",
  });
}

export function getOperationLogsApi(
  queryParams?: OperationLogQueryRequest
): AxiosPromise<PageResponse<OperationLogResponse[]>> {
  return request({
    url: "/admin/operation-logs",
    method: "get",
    params: queryParams,
  });
}

export function getAiModelsApi(): AxiosPromise<AiModelResponse[]> {
  return request({
    url: "/admin/models",
    method: "get",
  });
}
