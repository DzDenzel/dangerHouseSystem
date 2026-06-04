package com.dz.dangerhouse.mapper;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.dz.dangerhouse.entity.Image;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;

import java.util.List;

/**
 * 检测图片表 Mapper
 */
@Mapper
public interface ImageMapper extends BaseMapper<Image> {

    /**
     * 根据检测记录ID查询所有图片
     */
    @Select("SELECT * FROM image WHERE detection_id = #{detectionId} ORDER BY id ASC")
    List<Image> findByDetectionId(@Param("detectionId") Long detectionId);

    /**
     * 根据检测记录ID删除所有图片
     */
    default int deleteByDetectionId(Long detectionId) {
        return delete(new LambdaQueryWrapper<Image>().eq(Image::getDetectionId, detectionId));
    }
}
