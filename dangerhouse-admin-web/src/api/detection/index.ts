import request from "@/utils/request";
import { AxiosPromise } from "axios";
import {
  DetectionDetailResponse,
  DetectionImageResponse,
  DetectionListQueryRequest,
  DetectionRequest,
  DetectionResponse,
} from "./types";

export function createDetectionApi(
  data: DetectionRequest
): AxiosPromise<DetectionResponse> {
  const formData = new FormData();
  formData.append("buildingId", String(data.buildingId));
  if (data.description) {
    formData.append("description", data.description);
  }
  return request({
    url: "/detections",
    method: "post",
    data: formData,
    headers: {
      "Content-Type": "multipart/form-data",
    },
  });
}

export function getDetectionDetailApi(
  id: number
): AxiosPromise<DetectionDetailResponse> {
  return request({
    url: `/detections/${id}`,
    method: "get",
  });
}

export function getDetectionListApi(
  queryParams?: DetectionListQueryRequest
): AxiosPromise<PageResponse<DetectionResponse[]>> {
  return request({
    url: "/detections",
    method: "get",
    params: queryParams,
  });
}

export function cancelDetectionApi(id: number): AxiosPromise<void> {
  return request({
    url: `/detections/${id}/cancel`,
    method: "put",
  });
}

export function deleteDetectionApi(id: number): AxiosPromise<void> {
  return request({
    url: `/detections/${id}`,
    method: "delete",
  });
}

export function startDetectionApi(
  id: number
): AxiosPromise<DetectionDetailResponse> {
  return request({
    url: `/detections/${id}/start`,
    method: "post",
  });
}

export function uploadDetectionImagesApi(
  id: number,
  images: File[]
): AxiosPromise<DetectionImageResponse[]> {
  const formData = new FormData();
  images.forEach((file) => formData.append("images", file));
  return request({
    url: `/detections/${id}/images`,
    method: "post",
    data: formData,
    headers: {
      "Content-Type": "multipart/form-data",
    },
  });
}

export function getDetectionImagesApi(
  id: number
): AxiosPromise<DetectionImageResponse[]> {
  return request({
    url: `/detections/${id}/images`,
    method: "get",
  });
}
