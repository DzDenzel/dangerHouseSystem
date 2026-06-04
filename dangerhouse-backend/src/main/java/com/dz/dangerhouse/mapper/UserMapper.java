package com.dz.dangerhouse.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.dz.dangerhouse.entity.User;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;
import org.apache.ibatis.annotations.Update;

import java.time.LocalDateTime;
import java.util.List;

/**
 * 用户表 Mapper
 */
@Mapper
public interface UserMapper extends BaseMapper<User> {

    /**
     * 根据用户名查询用户
     */
    @Select("SELECT * FROM user WHERE username = #{username}")
    User findByUsername(String username);

    /**
     * 根据用户名检查用户是否存在
     */
    @Select("SELECT COUNT(*) FROM user WHERE username = #{username}")
    int existsUserByUsername(String username);

    /**
     * 根据手机号查询用户
     */
    @Select("SELECT * FROM user WHERE phone = #{phone}")
    User findByPhone(String phone);

    /**
     * 根据手机号检查用户是否存在
     */
    @Select("SELECT COUNT(*) FROM user WHERE phone = #{phone}")
    int existsUserByPhone(String phone);

    /**
     * 根据邮箱查询用户
     */
    @Select("SELECT * FROM user WHERE email = #{email}")
    User findByEmail(String email);

    /**
     * 更新用户最后登录信息
     */
    @Update("UPDATE user SET last_login_time = #{lastLoginTime}, last_login_ip = #{lastLoginIp} WHERE id = #{id}")
    int updateLastLoginInfo(@Param("id") Long id,
                            @Param("lastLoginTime") LocalDateTime lastLoginTime,
                            @Param("lastLoginIp") String lastLoginIp);

    /**
     * 根据用户 ID 查询用户的所有角色编码
     */
    @Select("SELECT r.role_code FROM role r " +
            "INNER JOIN user_role ur ON r.id = ur.role_id " +
            "WHERE ur.user_id = #{userId}")
    List<String> findRoleCodesByUserId(Long userId);
}
