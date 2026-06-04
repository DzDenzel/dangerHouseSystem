import request from "@/utils/request";
import { AxiosPromise } from "axios";
import {
  BuildingListQueryRequest,
  BuildingRequest,
  BuildingResponse,
} from "./types";

export function createBuildingApi(
  data: BuildingRequest
): AxiosPromise<BuildingResponse> {
  return request({
    url: "/buildings",
    method: "post",
    data,
  });
}

export function updateBuildingApi(
  id: number,
  data: BuildingRequest
): AxiosPromise<BuildingResponse> {
  return request({
    url: `/buildings/${id}`,
    method: "put",
    data,
  });
}

export function deleteBuildingApi(id: number): AxiosPromise<void> {
  return request({
    url: `/buildings/${id}`,
    method: "delete",
  });
}

export function getBuildingDetailApi(
  id: number
): AxiosPromise<BuildingResponse> {
  return request({
    url: `/buildings/${id}`,
    method: "get",
  });
}

export function getBuildingListApi(
  queryParams?: BuildingListQueryRequest
): AxiosPromise<PageResponse<BuildingResponse[]>> {
  return request({
    url: "/buildings",
    method: "get",
    params: queryParams,
  });
}

export function searchBuildingsByOwnerApi(
  ownerName: string
): AxiosPromise<BuildingResponse[]> {
  return request({
    url: "/buildings/by-owner",
    method: "get",
    params: { ownerName },
  });
}

export function searchBuildingsByAddressApi(
  address: string
): AxiosPromise<BuildingResponse[]> {
  return request({
    url: "/buildings/by-address",
    method: "get",
    params: { address },
  });
}

export function uploadBuildingImageApi(
  id: number,
  file: File
): AxiosPromise<string> {
  const formData = new FormData();
  formData.append("file", file);
  return request({
    url: `/buildings/${id}/image`,
    method: "post",
    data: formData,
    headers: {
      "Content-Type": "multipart/form-data",
    },
  });
}
