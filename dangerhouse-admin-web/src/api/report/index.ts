import request from "@/utils/request";
import { AxiosPromise } from "axios";
import {
  GenerateReportResponse,
  ReportListQueryRequest,
  ReportResponse,
} from "./types";

export function createReportApi(
  detectionId: number
): AxiosPromise<GenerateReportResponse> {
  return request({
    url: `/reports/generate`,
    method: "post",
    data: { detectionId, format: "PDF" },
  });
}

export function getReportDetailApi(id: number): AxiosPromise<ReportResponse> {
  return request({
    url: `/reports/${id}`,
    method: "get",
  });
}

export function getReportListApi(
  queryParams?: ReportListQueryRequest
): AxiosPromise<PageResponse<ReportResponse[]>> {
  return request({
    url: "/reports",
    method: "get",
    params: queryParams,
  });
}

export function downloadReportApi(id: number) {
  return request({
    url: `/reports/${id}/download`,
    method: "get",
    responseType: "arraybuffer",
  } as any);
}
