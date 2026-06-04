package com.dz.dangerhouse.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.dz.dangerhouse.entity.UserRole;
import org.apache.ibatis.annotations.*;

import java.util.List;

/**
 * 用户角色关系表 Mapper
 */
@Mapper
public interface UserRoleMapper extends BaseMapper<UserRole> {

    /**
     * 根据用户ID查询所有角色ID
     */
    @Select("SELECT role_id FROM user_role WHERE user_id = #{userId}")
    List<Long> findRoleIdsByUserId(Long userId);

    /**
     * 根据用户ID删除所有角色关联
     */
    @Delete("DELETE FROM user_role WHERE user_id = #{userId}")
    int deleteByUserId(Long userId);

    /**
     * 批量插入用户角色关联
     */
    int batchInsert(@Param("list") List<UserRole> list);

    /**
     * 根据用户ID和角色ID删除关联
     */
    @Delete("DELETE FROM user_role WHERE user_id = #{userId} AND role_id = #{roleId}")
    int deleteByUserIdAndRoleId(@Param("userId") Long userId, @Param("roleId") Long roleId);

    /**
     * 查询用户是否拥有某个角色
     */
    @Select("SELECT COUNT(*) FROM user_role WHERE user_id = #{userId} AND role_id = #{roleId}")
    int countByUserIdAndRoleId(@Param("userId") Long userId, @Param("roleId") Long roleId);
}