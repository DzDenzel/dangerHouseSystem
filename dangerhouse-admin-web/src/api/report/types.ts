export interface GenerateReportResponse {
  reportId: number;
  reportNo: string;
}

export interface ReportResponse {
  id: number;
  detectionId: number;
  buildingId: number;
  reportNo: string;
  filePath: string;
  fileType: string;
  generatedAt: string;
}

export interface ReportListQueryRequest {
  page?: number;
  size?: number;
  buildingId?: number;
  riskLevel?: string;
  startDate?: string;
  endDate?: string;
}
