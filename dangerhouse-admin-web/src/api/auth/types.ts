/**
 * 登录请求参数
 */
export interface LoginData {
  /**
   * 账号（用户名/手机号/邮箱）
   */
  account: string;
  /**
   * 密码
   */
  password: string;
  rememberMe?: boolean;
  clientType?: "WEB" | "APP";
}

/**
 * 登录响应
 */
export interface LoginResult {
  /**
   * 用户ID
   */
  id: number;
  /**
   * 访问token
   */
  token: string;
  /**
   * 角色列表
   */
  roles: string[];
  /**
   * 用户名
   */
  username: string;
  /**
   * 昵称
   */
  nickname?: string;
  /**
   * 头像
   */
  avatar?: string;
  /**
   * 手机号
   */
  phone?: string;
  /**
   * 邮箱
   */
  email?: string;
  /**
   * 最后登录时间
   */
  lastLoginTime?: string;
  /**
   * 创建时间
   */
  createdAt?: string;
  /**
   * 更新时间
   */
  updatedAt?: string;
  /**
   * 状态
   */
  status?: number;
}
export interface RegisterData {
  username?: string;
  password?: string;
  phone?: string;
  role?: string;
}

export interface RegisterResult {
  id: number;
  username: string;
  phone?: string;
  role?: string;
  message?: string;
  createTime?: string;
}
