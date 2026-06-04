export interface AiDetectionAnalysis {
  riskLevel: string;
  damageRatio: number;
  crackCount: number;
  confidence: number;
}

export interface AiDetectionBox {
  type: string;
  confidence: number;
  bbox: number[];
}

export interface AiImageResult {
  filename: string;
  detections: AiDetectionBox[];
  resultImage: string;
  analysis: Record<string, any>;
}

export interface AiDetectionData {
  analysis: AiDetectionAnalysis;
  detections: AiDetectionBox[];
  imageResults: AiImageResult[];
  resultImage: string;
}

export interface AiDetectionResponse {
  code: number;
  message: string;
  data: AiDetectionData;
}
