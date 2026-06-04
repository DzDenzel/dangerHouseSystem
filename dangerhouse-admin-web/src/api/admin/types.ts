export interface DashboardStatsResponse {
  userCount: number;
  buildingCount: number;
  detectionCount: number;
  highRiskCount: number;
}

export interface OperationLogQueryRequest {
  page?: number;
  size?: number;
  operation?: string;
  username?: string;
  startDate?: string;
  endDate?: string;
  status?: number;
}

export interface OperationLogResponse {
  id: number;
  userId: number;
  operation: string;
  method: string;
  params: string;
  result: string;
  ip: string;
  status: number;
  errorMsg?: string;
  createTime: string;
}

export interface AiModelResponse {
  id: number;
  name: string;
  version: string;
  description?: string;
  status?: number;
  createTime?: string;
  updateTime?: string;
}
