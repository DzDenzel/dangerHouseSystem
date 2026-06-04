package com.dz.dangerhouse.controller;

import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.dz.dangerhouse.annotation.Log;
import com.dz.dangerhouse.common.Result;
import com.dz.dangerhouse.dto.request.BuildingQueryRequest;
import com.dz.dangerhouse.dto.request.BuildingRequest;
import com.dz.dangerhouse.dto.response.BuildingResponse;
import com.dz.dangerhouse.dto.response.PageResponse;
import com.dz.dangerhouse.entity.Building;
import com.dz.dangerhouse.entity.Role;
import com.dz.dangerhouse.exception.BusinessException;
import com.dz.dangerhouse.mapper.RoleMapper;
import com.dz.dangerhouse.service.BuildingService;
import com.dz.dangerhouse.service.CurrentUserService;
import com.dz.dangerhouse.service.DetectionService;
import com.dz.dangerhouse.util.FileUploadUtil;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;
import java.util.stream.Collectors;

/**
 * 建筑档案控制器
 */
@Slf4j
@RestController
@RequestMapping("/api/buildings")
@Tag(name = "建筑档案管理", description = "建筑档案相关接口")
public class BuildingController {

    @Autowired
    private BuildingService buildingService;

    @Autowired
    private DetectionService detectionService;

    @Autowired
    private FileUploadUtil fileUploadUtil;

    @Autowired
    private CurrentUserService currentUserService;

    @Autowired
    private RoleMapper roleMapper;

    /**
     * 获取建筑列表
     */
    @GetMapping
    @PreAuthorize("hasAnyRole('USER','INSPECTOR','ADMIN')")
    @Operation(summary = "获取建筑列表", description = "获取建筑档案列表，普通用户仅返回本人房屋")
    @Log(operation = "获取建筑列表", method = "GET /api/buildings", recordParams = false)
    public Result<PageResponse<BuildingResponse>> getBuildingList(@ModelAttribute BuildingQueryRequest query) {
        Integer page = query.getPage() == null ? 1 : query.getPage();
        Integer size = query.getSize() == null ? 10 : query.getSize();
        Integer pageNo = query.getPageNo();
        int pageNum = pageNo != null ? pageNo : page;

        Page<Building> result = buildingService.pageBuildings(
                pageNum,
                size,
                query.getName(),
                query.getAddress(),
                query.getStructureType(),
                null,
                query.getRiskLevels()
        );

        List<BuildingResponse> records = result.getRecords().stream()
                .map(this::toBuildingResponse)
                .collect(Collectors.toList());

        PageResponse<BuildingResponse> response = PageResponse.<BuildingResponse>builder()
                .records(records)
                .total(result.getTotal())
                .current(result.getCurrent())
                .size(result.getSize())
                .pages(result.getPages())
                .build();
        return Result.success(response);
    }

    /**
     * 创建建筑档案
     */
    @PostMapping
    @PreAuthorize("hasAnyRole('USER','INSPECTOR','ADMIN')")
    @Operation(summary = "创建建筑档案", description = "普通用户自动绑定本人，检测员可创建共享建筑档案")
    @Log(operation = "创建建筑档案", method = "POST /api/buildings")
    public Result<BuildingResponse> createBuilding(@RequestBody BuildingRequest request) {
        Building building = toBuildingEntity(request);
        Long currentUserId = currentUserService.getCurrentUserId();

        if (currentUserService.hasRole("USER")) building.setOwnerUserId(currentUserId);
        building.setCreatedBy(currentUserId);
        building.setCreatedByRole(resolveCurrentRoleId());

        buildingService.save(building);
        log.info("创建建筑档案成功: id={}, name={}", building.getId(), building.getName());
        return Result.success("创建成功", toBuildingResponse(building));
    }

    /**
     * 获取建筑详情
     */
    @GetMapping("/{id}")
    @PreAuthorize("hasAnyRole('USER','INSPECTOR','ADMIN')")
    @Operation(summary = "获取建筑详情", description = "根据 ID 获取建筑详情")
    @Log(operation = "获取建筑详情", method = "GET /api/buildings/{id}", recordParams = false)
    public Result<BuildingResponse> getBuildingById(@PathVariable Long id) {
        Building building = buildingService.getById(id);
        if (building == null) throw new BusinessException("建筑不存在");
        validateBuildingAccess(building);
        return Result.success(toBuildingResponse(building));
    }

    /**
     * 更新建筑信息
     */
    @PutMapping("/{id}")
    @PreAuthorize("hasAnyRole('USER','INSPECTOR','ADMIN')")
    @Operation(summary = "更新建筑信息", description = "更新建筑档案信息")
    @Log(operation = "更新建筑信息", method = "PUT /api/buildings/{id}")
    public Result<BuildingResponse> updateBuilding(@PathVariable Long id, @RequestBody BuildingRequest request) {
        Building existing = buildingService.getById(id);
        if (existing == null) throw new BusinessException("建筑不存在");
        validateBuildingAccess(existing);

        Building building = toBuildingEntity(request);
        building.setId(id);
        building.setOwnerUserId(existing.getOwnerUserId());
        building.setCreatedBy(existing.getCreatedBy());
        building.setCreatedByRole(existing.getCreatedByRole());
        building.setAssignedInspectorId(existing.getAssignedInspectorId());
        buildingService.updateById(building);

        Building updated = buildingService.getById(id);
        log.info("更新建筑档案成功: id={}", id);
        return Result.success("更新成功", toBuildingResponse(updated));
    }

    /**
     * 删除建筑档案
     */
    @DeleteMapping("/{id}")
    @PreAuthorize("hasAnyRole('INSPECTOR','ADMIN')")
    @Operation(summary = "删除建筑档案", description = "删除建筑档案及其关联检测记录")
    @Log(operation = "删除建筑档案", method = "DELETE /api/buildings/{id}")
    public Result<Void> deleteBuilding(@PathVariable Long id) {
        Building existing = buildingService.getById(id);
        if (existing == null) throw new BusinessException(404, "建筑不存在");
        if (currentUserService.hasRole("USER")) throw new BusinessException(403, "普通用户无权删除建筑档案");
        validateBuildingAccess(existing);

        detectionService.deleteByBuildingId(id);
        buildingService.removeById(id);
        log.info("删除建筑档案成功: id={}", id);
        return Result.success("删除成功", null);
    }

    /**
     * 按业主姓名查询建筑
     */
    @GetMapping("/by-owner")
    @PreAuthorize("hasAnyRole('USER','INSPECTOR','ADMIN')")
    @Operation(summary = "按业主查询建筑", description = "根据业主姓名查询建筑列表")
    @Log(operation = "按业主查询建筑", method = "GET /api/buildings/by-owner", recordParams = false)
    public Result<List<BuildingResponse>> getByOwnerName(@RequestParam String ownerName) {
        List<BuildingResponse> result = buildingService.findByOwnerName(ownerName).stream()
                .filter(this::canAccessBuilding)
                .map(this::toBuildingResponse)
                .collect(Collectors.toList());
        return Result.success(result);
    }

    /**
     * 按地址查询建筑
     */
    @GetMapping("/by-address")
    @PreAuthorize("hasAnyRole('USER','INSPECTOR','ADMIN')")
    @Operation(summary = "按地址查询建筑", description = "根据地址查询建筑列表")
    @Log(operation = "按地址查询建筑", method = "GET /api/buildings/by-address", recordParams = false)
    public Result<List<BuildingResponse>> getByAddress(@RequestParam String address) {
        List<BuildingResponse> result = buildingService.findByAddress(address).stream()
                .filter(this::canAccessBuilding)
                .map(this::toBuildingResponse)
                .collect(Collectors.toList());
        return Result.success(result);
    }

    /**
     * 上传建筑图片
     */
    @PostMapping("/{id}/image")
    @PreAuthorize("hasAnyRole('USER','INSPECTOR','ADMIN')")
    @Operation(summary = "上传建筑图片", description = "上传建筑档案图片")
    @Log(operation = "上传建筑图片", method = "POST /api/buildings/{id}/image", recordParams = false)
    public Result<String> uploadBuildingImage(@PathVariable Long id, @RequestParam("file") MultipartFile file) {
        Building building = buildingService.getById(id);
        if (building == null) throw new BusinessException("建筑不存在");
        validateBuildingAccess(building);

        String imagePath = fileUploadUtil.uploadBuildingImage(file, id);
        building.setImagePath(imagePath);
        buildingService.updateById(building);
        log.info("建筑图片上传成功: buildingId={}, path={}", id, imagePath);
        return Result.success("上传成功", fileUploadUtil.getFileUrl(imagePath));
    }

    /**
     * 转换为响应对象
     */
    private BuildingResponse toBuildingResponse(Building building) {
        if (building == null) return null;
        return BuildingResponse.builder()
                .id(building.getId())
                .name(building.getName())
                .address(building.getAddress())
                .structureType(building.getStructureType())
                .buildYear(building.getBuildYear())
                .floorCount(building.getFloorCount())
                .area(building.getArea())
                .ownerName(building.getOwnerName())
                .ownerPhone(building.getOwnerPhone())
                .ownerUserId(building.getOwnerUserId())
                .createdBy(building.getCreatedBy())
                .createdByRole(building.getCreatedByRole())
                .createdByRoleName(resolveRoleName(building.getCreatedByRole()))
                .assignedInspectorId(building.getAssignedInspectorId())
                .longitude(building.getLongitude())
                .latitude(building.getLatitude())
                .description(building.getDescription())
                .imagePath(fileUploadUtil.getFileUrl(building.getImagePath()))
                .createdAt(building.getCreatedAt())
                .updatedAt(building.getUpdatedAt())
                .build();
    }

    /**
     * 转换为实体对象
     */
    private Building toBuildingEntity(BuildingRequest request) {
        if (request == null) return null;
        Building building = new Building();
        building.setName(request.getName());
        building.setAddress(request.getAddress());
        building.setStructureType(request.getStructureType());
        building.setBuildYear(request.getBuildYear());
        building.setFloorCount(request.getFloorCount());
        building.setArea(request.getArea());
        building.setOwnerName(request.getOwnerName());
        building.setOwnerPhone(request.getOwnerPhone());
        building.setLongitude(request.getLongitude());
        building.setLatitude(request.getLatitude());
        building.setDescription(request.getDescription());
        building.setImagePath(request.getImagePath());
        return building;
    }

    /**
     * 验证建筑访问权限
     */
    private void validateBuildingAccess(Building building) {
        if (!currentUserService.hasRole("USER")) return;
        Long currentUserId = currentUserService.getCurrentUserId();
        if (building.getOwnerUserId() == null || !building.getOwnerUserId().equals(currentUserId))
            throw new BusinessException(403, "没有权限访问该建筑档案");
    }

    /**
     * 检查是否可访问建筑
     */
    private boolean canAccessBuilding(Building building) {
        if (!currentUserService.hasRole("USER")) return true;
        Long currentUserId = currentUserService.getCurrentUserId();
        return building.getOwnerUserId() != null && building.getOwnerUserId().equals(currentUserId);
    }

    /**
     * 解析当前用户角色 ID
     */
    private Long resolveCurrentRoleId() {
        String roleCode = "USER";
        if (currentUserService.hasRole("INSPECTOR")) roleCode = "INSPECTOR";
        else if (currentUserService.hasRole("ADMIN")) roleCode = "ADMIN";

        Role role = roleMapper.findByRoleCode(roleCode);
        return role != null ? role.getId() : null;
    }

    /**
     * 解析角色名称
     */
    private String resolveRoleName(Long roleId) {
        if (roleId == null) {
            return null;
        }

        Role role = roleMapper.selectById(roleId);
        if (role == null) {
            return null;
        }

        if (role.getRoleName() != null && !role.getRoleName().isBlank()) {
            return role.getRoleName();
        }

        String roleCode = role.getRoleCode();
        if ("ADMIN".equalsIgnoreCase(roleCode)) {
            return "管理员";
        }
        if ("INSPECTOR".equalsIgnoreCase(roleCode)) {
            return "检测员";
        }
        if ("USER".equalsIgnoreCase(roleCode)) {
            return "普通用户";
        }
        return roleCode;
    }
}
