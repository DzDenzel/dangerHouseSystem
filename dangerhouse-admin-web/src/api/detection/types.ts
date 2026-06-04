export interface DetectionRequest {
  buildingId: number;
  inspectorName?: string;
  inspectorPhone?: string;
  description?: string;
  images?: File[];
}

export interface DetectionImageResponse {
  id: number;
  imagePath: string;
  resultImagePath?: string;
  imageType?: string;
  uploadTime?: string;
}

export interface DetectionResultMap {
  analysis?: string;
  severityLevel?: string;
  suggestions?: string;
  crackCount?: number;
  damageRatio?: number;
  confidence?: number;
  [key: string]: any;
}

export interface DetectionResponse {
  id: number;
  buildingId: number;
  buildingName?: string;
  buildingAddress?: string;
  userId?: number;
  username?: string;
  status: string;
  crackCount?: number;
  damageRatio?: number;
  riskLevel?: string;
  confidence?: number;
  detectResult?: DetectionResultMap | null;
  detectTime?: string;
  description?: string;
  createdAt?: string;
  updatedAt?: string;
  errorMessage?: string;
  report?: {
    id: number;
    reportNo: string;
    filePath: string;
    generatedAt: string;
  } | null;
}

export interface DetectionDetailResponse extends DetectionResponse {
  images?: DetectionImageResponse[];
}

export interface DetectionListQueryRequest {
  page?: number;
  size?: number;
  buildingId?: number;
  status?: string;
  riskLevel?: string;
  startDate?: string;
  endDate?: string;
}
