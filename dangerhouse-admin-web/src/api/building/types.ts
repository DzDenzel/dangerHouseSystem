export interface BuildingRequest {
  name: string;
  address: string;
  structureType: string;
  buildYear: number;
  floorCount: number;
  area?: number;
  ownerName?: string;
  ownerPhone?: string;
  longitude?: number;
  latitude?: number;
  description?: string;
  imagePath?: string;
}

export interface BuildingResponse {
  id: number;
  name: string;
  address: string;
  structureType: string;
  buildYear: number;
  floorCount: number;
  area?: number;
  ownerName?: string;
  ownerPhone?: string;
  longitude?: number;
  latitude?: number;
  description?: string;
  imagePath?: string;
  ownerUserId?: number;
  createdBy?: number;
  createdByRole?: number;
  createdByRoleName?: string;
  assignedInspectorId?: number;
  createdAt?: string;
  updatedAt?: string;
}

export interface BuildingListQueryRequest {
  page?: number;
  size?: number;
  name?: string;
  address?: string;
  structureType?: string;
  riskLevels?: string;
}
