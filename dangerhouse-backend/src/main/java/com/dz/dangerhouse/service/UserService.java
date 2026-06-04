package com.dz.dangerhouse.service;

import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.dz.dangerhouse.dto.response.UserInfoResponse;
import com.dz.dangerhouse.dto.response.UserListResponse;
import com.dz.dangerhouse.dto.request.UserUpdateRequest;
import com.dz.dangerhouse.entity.User;
import org.springframework.web.multipart.MultipartFile;

/**
 * 用户服务接口
 */
public interface UserService {

    /**
     * 根据用户ID获取用户信息
     *
     * @param id 用户ID
     * @return 用户信息
     */
    UserInfoResponse getUserById(Long id);

    /**
     * 更新用户信息
     *
     * @param id      用户ID
     * @param request 更新请求
     * @return 更新后的用户信息
     */
    UserInfoResponse updateUser(Long id, UserUpdateRequest request);

    /**
     * 更新用户信息（带权限校验）
     *
     * @param id              用户ID
     * @param request         更新请求
     * @param currentUsername 当前登录用户名
     * @return 更新后的用户信息
     */
    UserInfoResponse updateUser(Long id, UserUpdateRequest request, String currentUsername);

    /**
     * 根据用户名查找用户
     *
     * @param username 用户名
     * @return 用户实体
     */
    User findByUsername(String username);

    /**
     * 获取用户列表（分页）
     *
     * @param page     页码
     * @param size     每页数量
     * @param username 用户名（可选）
     * @param status   状态（可选）
     * @return 分页结果
     */
    Page<UserListResponse> getUserList(Integer page, Integer size, String username, Integer status);

    /**
     * 更新用户状态
     *
     * @param userId 用户ID
     * @param status 状态(0禁用 1正常)
     */
    void updateUserStatus(Long userId, Integer status);

    /**
     * 修改密码
     *
     * @param userId      用户ID
     * @param oldPassword 原密码
     * @param newPassword 新密码
     */
    void updatePassword(Long userId, String oldPassword, String newPassword);

    /**
     * 设置或取消检测员角色
     *
     * @param userId    用户ID
     * @param inspector true 表示设为检测员，false 表示取消检测员
     */
    void updateInspectorRole(Long userId, boolean inspector);

    /**
     * 上传用户头像
     *
     * @param userId 用户ID
     * @param file   图片文件
     * @return 图片访问路径
     */
    String uploadAvatar(Long userId, MultipartFile file);
}
