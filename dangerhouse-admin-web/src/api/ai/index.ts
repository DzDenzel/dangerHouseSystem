import request from "@/utils/request";
import { AxiosPromise } from "axios";
import { AiDetectionResponse } from "./types";

export function aiDetectApi(images: File[]): AxiosPromise<AiDetectionResponse> {
  const formData = new FormData();
  images.forEach((file) => formData.append("images", file));
  return request({
    url: "/ai/detect",
    method: "post",
    data: formData,
    headers: {
      "Content-Type": "multipart/form-data",
    },
  });
}
