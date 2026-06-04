package com.dz.dangerhouse.controller;

import com.dz.dangerhouse.annotation.Log;
import com.dz.dangerhouse.common.Result;
import com.dz.dangerhouse.dto.request.PasswordUpdateRequest;
import com.dz.dangerhouse.dto.request.UserListQueryRequest;
import com.dz.dangerhouse.dto.request.UserUpdateRequest;
import com.dz.dangerhouse.dto.response.PageResponse;
import com.dz.dangerhouse.dto.response.UserInfoResponse;
import com.dz.dangerhouse.dto.response.UserListResponse;
import com.dz.dangerhouse.service.CurrentUserService;
import com.dz.dangerhouse.service.UserService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.ModelAttribute;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

/**
 * 用户管理控制器
 */
@Slf4j
@RestController
@RequestMapping("/api")
@Tag(name = "用户管理", description = "用户管理接口")
public class UserController {

    @Autowired
    private UserService userService;

    @Autowired
    private CurrentUserService currentUserService;

    /**
     * 获取当前用户信息
     */
    @GetMapping("/user/profile")
    @PreAuthorize("hasAnyRole('USER','INSPECTOR','ADMIN')")
    @Operation(summary = "获取当前用户", description = "获取当前登录用户信息")
    @Log(operation = "获取当前用户", method = "GET /api/user/profile", recordParams = false)
    public Result<UserInfoResponse> getCurrentUserProfile() {
        Long userId = currentUserService.getCurrentUserId();
        return Result.success(userService.getUserById(userId));
    }

    /**
     * 更新当前用户信息
     */
    @PutMapping("/user/profile")
    @PreAuthorize("hasAnyRole('USER','INSPECTOR','ADMIN')")
    @Operation(summary = "更新当前用户", description = "更新当前登录用户信息")
    @Log(operation = "更新当前用户", method = "PUT /api/user/profile")
    public Result<UserInfoResponse> updateCurrentUserProfile(@RequestBody UserUpdateRequest request) {
        Long userId = currentUserService.getCurrentUserId();
        return Result.success("更新成功", userService.updateUser(userId, request));
    }

    /**
     * 修改密码
     */
    @PutMapping("/user/password")
    @PreAuthorize("hasAnyRole('USER','INSPECTOR','ADMIN')")
    @Operation(summary = "修改密码", description = "修改当前登录用户密码")
    @Log(operation = "修改密码", method = "PUT /api/user/password", recordParams = false)
    public Result<Void> updatePassword(@Valid @RequestBody PasswordUpdateRequest request) {
        Long userId = currentUserService.getCurrentUserId();
        userService.updatePassword(userId, request.getOldPassword(), request.getNewPassword());
        return Result.success("密码修改成功", null);
    }

    /**
     * 上传头像
     */
    @PostMapping("/user/avatar")
    @PreAuthorize("hasAnyRole('USER','INSPECTOR','ADMIN')")
    @Operation(summary = "上传头像", description = "上传并更新当前用户头像")
    @Log(operation = "上传头像", method = "POST /api/user/avatar", recordParams = false)
    public Result<String> uploadAvatar(@RequestParam("file") MultipartFile file) {
        Long userId = currentUserService.getCurrentUserId();
        return Result.success("头像上传成功", userService.uploadAvatar(userId, file));
    }

    /**
     * 获取用户列表（仅管理员）
     */
    @GetMapping("/users")
    @PreAuthorize("hasRole('ADMIN')")
    @Operation(summary = "获取用户列表", description = "获取用户列表，仅管理员可访问")
    @Log(operation = "获取用户列表", method = "GET /api/users", recordParams = false)
    public Result<PageResponse<UserListResponse>> getUserList(@ModelAttribute UserListQueryRequest query) {
        Integer page = query.getPage() == null ? 1 : query.getPage();
        Integer size = query.getSize() == null ? 10 : query.getSize();
        return Result.success(PageResponse.from(userService.getUserList(page, size, query.getUsername(), query.getStatus())));
    }

    /**
     * 根据 ID 获取用户信息（仅管理员）
     */
    @GetMapping("/users/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    @Operation(summary = "获取用户", description = "根据 ID 获取用户信息")
    @Log(operation = "获取用户", method = "GET /api/users/{id}", recordParams = false)
    public Result<UserInfoResponse> getUserById(@PathVariable Long id) {
        return Result.success(userService.getUserById(id));
    }

    @PutMapping("/users/{userId}/inspector")
    @PreAuthorize("hasRole('ADMIN')")
    @Operation(summary = "设置检测员", description = "管理员设置或取消用户的检测员角色")
    @Log(operation = "设置检测员", method = "PUT /api/users/{userId}/inspector")
    public Result<Void> updateInspectorRole(@PathVariable Long userId, @RequestBody InspectorRoleUpdateRequest request) {
        boolean inspector = Boolean.TRUE.equals(request.getInspector());
        userService.updateInspectorRole(userId, inspector);
        return Result.success(inspector ? "宸茶缃负妫€娴嬪憳" : "宸插彇娑堟娴嬪憳韬唤", null);
    }

    /**
     * 更新用户状态（仅管理员）
     */
    @PutMapping("/users/{userId}/status")
    @PreAuthorize("hasRole('ADMIN')")
    @Operation(summary = "更新状态", description = "启用或禁用用户，仅管理员可访问")
    @Log(operation = "更新状态", method = "PUT /api/users/{userId}/status")
    public Result<Void> updateUserStatus(@PathVariable Long userId, @RequestBody StatusUpdateRequest request) {
        userService.updateUserStatus(userId, request.getStatus());
        return Result.success("更新成功", null);
    }

    @lombok.Data
    public static class StatusUpdateRequest {
        private Integer status;
    }

    @lombok.Data
    public static class InspectorRoleUpdateRequest {
        private Boolean inspector;
    }
}
