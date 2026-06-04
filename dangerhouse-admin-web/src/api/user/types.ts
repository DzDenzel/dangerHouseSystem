export interface UserInfo {
  id: number;
  username: string;
  phone?: string;
  email?: string;
  nickname?: string;
  avatar?: string;
  roles: string[];
  status?: number;
  lastLoginTime?: string;
  lastLoginIp?: string;
  createdAt?: string;
  updatedAt?: string;
  perms?: string[];
}

export interface UserUpdateRequest {
  phone?: string;
  email?: string;
  nickname?: string;
  avatar?: string;
}

export interface PasswordUpdateRequest {
  oldPassword: string;
  newPassword: string;
}

export interface UserListQueryRequest {
  page?: number;
  size?: number;
  username?: string;
  status?: number;
}

export interface UserListResponse {
  id: number;
  username: string;
  nickname?: string;
  email?: string;
  phone?: string;
  avatar?: string;
  status?: number;
  roles?: string[];
  createdAt?: string;
}

export interface UserQuery extends PageQuery {
  keywords?: string;
  status?: number;
}
