package com.dz.dangerhouse.dto.response;

import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.Collections;
import java.util.List;

/**
 * 分页响应 DTO
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class PageResponse<T> {

    /**
     * 当前页记录列表
     */
    private List<T> records;

    /**
     * 总记录数
     */
    private long total;

    /**
     * 当前页码
     */
    private long current;

    /**
     * 每页数量
     */
    private long size;

    /**
     * 总页数
     */
    private long pages;

    /**
     * 从MyBatis-Plus的Page对象转换为PageResponse
     *
     * @param page MyBatis-Plus分页对象
     * @return 分页响应对象
     */
    public static <T> PageResponse<T> from(Page<T> page) {
        if (page == null) {
            return PageResponse.<T>builder()
                    .records(Collections.emptyList())
                    .total(0)
                    .current(1)
                    .size(0)
                    .pages(0)
                    .build();
        }
        List<T> records = page.getRecords() == null ? Collections.emptyList() : page.getRecords();
        return PageResponse.<T>builder()
                .records(records)
                .total(page.getTotal())
                .current(page.getCurrent())
                .size(page.getSize())
                .pages(page.getPages())
                .build();
    }
}