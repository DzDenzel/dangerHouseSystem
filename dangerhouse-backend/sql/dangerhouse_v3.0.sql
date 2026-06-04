-- ==============================================
-- dangerhouse 数据库完整脚本 V3.0
-- 生成时间：2026-04-12
-- 说明：
-- 1. 基于当前导出的数据库结构 script.sql 整理
-- 2. 已合并角色权限分级相关字段
-- 3. building.created_by_role 已调整为角色ID(BIGINT)
-- ==============================================

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

DROP TABLE IF EXISTS `operation_log`;
DROP TABLE IF EXISTS `report`;
DROP TABLE IF EXISTS `image`;
DROP TABLE IF EXISTS `detection`;
DROP TABLE IF EXISTS `user_role`;
DROP TABLE IF EXISTS `building`;
DROP TABLE IF EXISTS `role`;
DROP TABLE IF EXISTS `user`;

CREATE TABLE `building`
(
    `id`                    BIGINT AUTO_INCREMENT COMMENT '建筑ID'
        PRIMARY KEY,
    `name`                  VARCHAR(100)                       NOT NULL COMMENT '建筑名称',
    `address`               VARCHAR(255)                       NOT NULL COMMENT '地址',
    `structure_type`        VARCHAR(50)                        NULL COMMENT '结构类型(BRICK_MIX/CONCRETE/STEEL/BRICK_WOOD/OTHER)',
    `build_year`            INT                                NULL COMMENT '建造年份',
    `floor_count`           INT                                NULL COMMENT '楼层数',
    `area`                  DECIMAL(10, 2)                     NULL COMMENT '建筑面积(平方米)',
    `owner_name`            VARCHAR(50)                        NULL COMMENT '户主姓名',
    `owner_phone`           VARCHAR(20)                        NULL COMMENT '户主电话',
    `owner_user_id`         BIGINT                             NULL COMMENT '绑定的普通用户账号ID',
    `created_by`            BIGINT                             NULL COMMENT '房屋创建人ID',
    `created_by_role`       BIGINT                             NULL COMMENT '创建人角色ID',
    `assigned_inspector_id` BIGINT                             NULL COMMENT '当前主要跟进检测员ID',
    `longitude`             DECIMAL(10, 6)                     NULL COMMENT '经度',
    `latitude`              DECIMAL(10, 6)                     NULL COMMENT '纬度',
    `description`           TEXT                               NULL COMMENT '建筑描述',
    `image_path`            VARCHAR(255)                       NULL COMMENT '建筑图片路径',
    `created_at`            DATETIME DEFAULT CURRENT_TIMESTAMP NULL COMMENT '创建时间',
    `updated_at`            DATETIME DEFAULT CURRENT_TIMESTAMP NULL ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间'
)
    COMMENT '建筑档案表';

CREATE INDEX `idx_address`
    ON `building` (`address`);

CREATE INDEX `idx_created_at`
    ON `building` (`created_at`);

CREATE INDEX `idx_name`
    ON `building` (`name`);

CREATE INDEX `idx_owner_user_id`
    ON `building` (`owner_user_id`);

CREATE TABLE `role`
(
    `id`          BIGINT AUTO_INCREMENT COMMENT '角色ID'
        PRIMARY KEY,
    `role_name`   VARCHAR(50)                        NOT NULL COMMENT '角色名称',
    `role_code`   VARCHAR(50)                        NOT NULL COMMENT '角色编码',
    `description` VARCHAR(255)                       NULL COMMENT '角色描述',
    `created_at`  DATETIME DEFAULT CURRENT_TIMESTAMP NULL COMMENT '创建时间',
    `updated_at`  DATETIME DEFAULT CURRENT_TIMESTAMP NULL ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    CONSTRAINT `uk_role_code`
        UNIQUE (`role_code`)
)
    COMMENT '角色表';

CREATE TABLE `user`
(
    `id`              BIGINT AUTO_INCREMENT COMMENT '用户ID'
        PRIMARY KEY,
    `username`        VARCHAR(50)                        NOT NULL COMMENT '用户名',
    `password`        VARCHAR(255)                       NOT NULL COMMENT '密码(Bcrypt加密)',
    `phone`           VARCHAR(20)                        NULL COMMENT '手机号',
    `email`           VARCHAR(100)                       NULL COMMENT '邮箱',
    `nickname`        VARCHAR(50)                        NULL COMMENT '昵称',
    `avatar`          VARCHAR(255)                       NULL COMMENT '头像URL',
    `status`          TINYINT  DEFAULT 1                 NULL COMMENT '状态(1正常 0禁用)',
    `last_login_time` DATETIME                           NULL COMMENT '最后登录时间',
    `last_login_ip`   VARCHAR(45)                        NULL COMMENT '最后登录IP',
    `created_at`      DATETIME DEFAULT CURRENT_TIMESTAMP NULL COMMENT '创建时间',
    `updated_at`      DATETIME DEFAULT CURRENT_TIMESTAMP NULL ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    CONSTRAINT `uk_email`
        UNIQUE (`email`),
    CONSTRAINT `uk_username`
        UNIQUE (`username`)
)
    COMMENT '用户表';

CREATE INDEX `idx_created_at`
    ON `user` (`created_at`);

CREATE INDEX `idx_status`
    ON `user` (`status`);

CREATE TABLE `detection`
(
    `id`            BIGINT AUTO_INCREMENT COMMENT '检测记录ID'
        PRIMARY KEY,
    `building_id`   BIGINT                                NOT NULL COMMENT '建筑ID',
    `user_id`       BIGINT                                NULL COMMENT '检测人用户ID',
    `status`        VARCHAR(20) DEFAULT 'CREATED'         NULL COMMENT '检测状态(CREATED/READY/PROCESSING/COMPLETED/FAILED/CANCELLED)',
    `crack_count`   INT         DEFAULT 0                 NULL COMMENT '裂缝数量',
    `damage_ratio`  DECIMAL(10, 4)                        NULL COMMENT '损伤比例(0-100)',
    `risk_level`    VARCHAR(20)                           NULL COMMENT '风险等级(A/B/C/D)',
    `confidence`    DECIMAL(5, 2)                         NULL COMMENT '检测置信度(0-100)',
    `detect_result` JSON                                  NULL COMMENT '检测结果JSON',
    `detect_time`   DATETIME    DEFAULT CURRENT_TIMESTAMP NULL COMMENT '检测时间',
    `description`   VARCHAR(500)                          NULL COMMENT '检测备注',
    `error_message` VARCHAR(500)                          NULL COMMENT '错误信息(检测失败时)',
    `created_at`    DATETIME    DEFAULT CURRENT_TIMESTAMP NULL COMMENT '创建时间',
    `updated_at`    DATETIME    DEFAULT CURRENT_TIMESTAMP NULL ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    CONSTRAINT `fk_detection_building_id`
        FOREIGN KEY (`building_id`) REFERENCES `building` (`id`)
            ON DELETE CASCADE,
    CONSTRAINT `fk_detection_user_id`
        FOREIGN KEY (`user_id`) REFERENCES `user` (`id`)
            ON DELETE SET NULL
)
    COMMENT 'AI检测记录表';

CREATE INDEX `idx_building_id`
    ON `detection` (`building_id`);

CREATE INDEX `idx_detect_time`
    ON `detection` (`detect_time`);

CREATE INDEX `idx_risk_level`
    ON `detection` (`risk_level`);

CREATE INDEX `idx_status`
    ON `detection` (`status`);

CREATE INDEX `idx_user_id`
    ON `detection` (`user_id`);

CREATE TABLE `image`
(
    `id`                BIGINT AUTO_INCREMENT COMMENT '图片ID'
        PRIMARY KEY,
    `detection_id`      BIGINT                             NOT NULL COMMENT '检测记录ID',
    `image_path`        VARCHAR(255)                       NOT NULL COMMENT '原始图片路径',
    `result_image_path` VARCHAR(255)                       NULL COMMENT '检测结果图片路径',
    `image_type`        VARCHAR(20)                        NULL COMMENT '图片类型(墙体/屋顶/整体)',
    `upload_time`       DATETIME DEFAULT CURRENT_TIMESTAMP NULL COMMENT '上传时间',
    CONSTRAINT `fk_image_detection_id`
        FOREIGN KEY (`detection_id`) REFERENCES `detection` (`id`)
            ON DELETE CASCADE
)
    COMMENT '检测图片表';

CREATE INDEX `idx_detection_id`
    ON `image` (`detection_id`);

CREATE INDEX `idx_image_type`
    ON `image` (`image_type`);

CREATE TABLE `operation_log`
(
    `id`          BIGINT AUTO_INCREMENT COMMENT '日志ID'
        PRIMARY KEY,
    `user_id`     BIGINT                             NULL COMMENT '操作用户ID',
    `operation`   VARCHAR(100)                       NULL COMMENT '操作类型',
    `method`      VARCHAR(200)                       NULL COMMENT '接口方法',
    `params`      TEXT                               NULL COMMENT '请求参数(JSON)',
    `result`      TEXT                               NULL COMMENT '响应结果(JSON)',
    `ip`          VARCHAR(45)                        NULL COMMENT '操作IP',
    `status`      TINYINT  DEFAULT 1                 NULL COMMENT '操作状态(1成功 0失败)',
    `error_msg`   VARCHAR(500)                       NULL COMMENT '错误信息',
    `create_time` DATETIME DEFAULT CURRENT_TIMESTAMP NULL COMMENT '创建时间',
    CONSTRAINT `fk_log_user_id`
        FOREIGN KEY (`user_id`) REFERENCES `user` (`id`)
            ON DELETE SET NULL
)
    COMMENT '操作日志表';

CREATE INDEX `idx_create_time`
    ON `operation_log` (`create_time`);

CREATE INDEX `idx_operation`
    ON `operation_log` (`operation`);

CREATE INDEX `idx_status`
    ON `operation_log` (`status`);

CREATE INDEX `idx_user_id`
    ON `operation_log` (`user_id`);

CREATE TABLE `report`
(
    `id`           BIGINT AUTO_INCREMENT COMMENT '报告ID'
        PRIMARY KEY,
    `detection_id` BIGINT                                NOT NULL COMMENT '检测记录ID',
    `building_id`  BIGINT                                NOT NULL COMMENT '建筑ID',
    `report_no`    VARCHAR(50)                           NOT NULL COMMENT '报告编号',
    `file_path`    VARCHAR(255)                          NULL COMMENT '报告文件路径',
    `file_type`    VARCHAR(20) DEFAULT 'PDF'             NULL COMMENT '文件类型(PDF/WORD)',
    `generated_at` DATETIME    DEFAULT CURRENT_TIMESTAMP NULL COMMENT '生成时间',
    CONSTRAINT `uk_report_no`
        UNIQUE (`report_no`),
    CONSTRAINT `fk_report_building_id`
        FOREIGN KEY (`building_id`) REFERENCES `building` (`id`)
            ON DELETE CASCADE,
    CONSTRAINT `fk_report_detection_id`
        FOREIGN KEY (`detection_id`) REFERENCES `detection` (`id`)
            ON DELETE CASCADE
)
    COMMENT '检测报告表';

CREATE INDEX `idx_building_id`
    ON `report` (`building_id`);

CREATE INDEX `idx_detection_id`
    ON `report` (`detection_id`);

CREATE INDEX `idx_generated_at`
    ON `report` (`generated_at`);

CREATE TABLE `user_role`
(
    `id`         BIGINT AUTO_INCREMENT COMMENT '主键ID'
        PRIMARY KEY,
    `user_id`    BIGINT                             NOT NULL COMMENT '用户ID',
    `role_id`    BIGINT                             NOT NULL COMMENT '角色ID',
    `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP NULL COMMENT '创建时间',
    CONSTRAINT `uk_user_role`
        UNIQUE (`user_id`, `role_id`),
    CONSTRAINT `fk_ur_role_id`
        FOREIGN KEY (`role_id`) REFERENCES `role` (`id`)
            ON DELETE CASCADE,
    CONSTRAINT `fk_ur_user_id`
        FOREIGN KEY (`user_id`) REFERENCES `user` (`id`)
            ON DELETE CASCADE
)
    COMMENT '用户角色关联表';

CREATE INDEX `idx_role_id`
    ON `user_role` (`role_id`);

CREATE INDEX `idx_user_id`
    ON `user_role` (`user_id`);

-- ==============================================
-- 初始化数据
-- ==============================================

INSERT INTO `role` (`id`, `role_name`, `role_code`, `description`, `created_at`, `updated_at`)
VALUES (1, '管理员', 'ADMIN', '系统最高权限，管理所有功能', NOW(), NOW()),
       (2, '检测员', 'INSPECTOR', '在移动端执行建筑采集与检测业务', NOW(), NOW()),
       (3, '普通用户', 'USER', '在移动端进行快速检测、查看个人建筑和个人信息', NOW(), NOW());

INSERT INTO `user` (`id`, `username`, `password`, `phone`, `email`, `nickname`, `avatar`, `status`, `last_login_time`,
                    `last_login_ip`, `created_at`, `updated_at`)
VALUES (1, 'admin', '$2a$10$ILxANQDjX5qTAjy1dJKC7uLnt/dKJZ5cqQ.1w6jHtnVreywOtysx6', NULL, 'admin@dangerhouse.com',
        '系统管理员', NULL, 1, NULL, NULL, NOW(), NOW());

INSERT INTO `user_role` (`id`, `user_id`, `role_id`, `created_at`)
VALUES (1, 1, 1, NOW());

ALTER TABLE `role`
    AUTO_INCREMENT = 4;

ALTER TABLE `user`
    AUTO_INCREMENT = 2;

ALTER TABLE `user_role`
    AUTO_INCREMENT = 2;

SET FOREIGN_KEY_CHECKS = 1;
