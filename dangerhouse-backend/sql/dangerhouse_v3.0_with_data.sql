-- ==============================================
-- dangerhouse 数据库完整脚本 V3.0（含业务数据）
-- 生成时间：2026-04-12
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
-- 基础数据
-- ==============================================

INSERT INTO `role` (`id`, `role_name`, `role_code`, `description`, `created_at`, `updated_at`)
VALUES (1, '管理员', 'ADMIN', '系统最高权限，管理所有功能', '2026-03-30 15:59:42', '2026-03-30 15:59:42'),
       (2, '检测员', 'INSPECTOR', '进行危房检测的专业人员', '2026-03-30 15:59:42', '2026-03-30 15:59:42'),
       (3, '普通用户', 'USER', '普通系统用户', '2026-03-30 15:59:42', '2026-03-30 15:59:42');

INSERT INTO `user` (`id`, `username`, `password`, `phone`, `email`, `nickname`, `avatar`, `status`, `last_login_time`,
                    `last_login_ip`, `created_at`, `updated_at`)
VALUES (1, 'admin', '$2a$10$ILxANQDjX5qTAjy1dJKC7uLnt/dKJZ5cqQ.1w6jHtnVreywOtysx6', '13456789001',
        'admin@dangerhouse.com', '系统管理员',
        'users/avatars/1/2026/03/30/e2f564e51c244adcb0f392e5b34fc2a2.jpg',
        1, '2026-04-12 18:08:54', '127.0.0.1', '2026-03-30 15:59:42', '2026-04-12 18:08:54'),
       (2, 'zhangsan', '$2a$10$ryE43T2SkuDn.pSZhGoSautIZEfFh6yn6W.7Cslc4310/seTaMTU6', '13456789002',
        'zhangsan@user.com', '张三', NULL,
        1, '2026-04-12 18:08:49', '127.0.0.1', '2026-04-11 23:19:20', '2026-04-12 18:08:48'),
       (3, 'inspector01', '$2a$10$ILxANQDjX5qTAjy1dJKC7uLnt/dKJZ5cqQ.1w6jHtnVreywOtysx6', '13456789003',
        'inspector01@dangerhouse.com', '检测员01', NULL,
        1, NULL, NULL, NOW(), NOW());

INSERT INTO `user_role` (`id`, `user_id`, `role_id`, `created_at`)
VALUES (1, 1, 1, '2026-03-30 15:59:42'),
       (2, 2, 3, '2026-04-11 23:19:20'),
       (3, 3, 2, NOW());

-- ==============================================
-- 建筑数据
-- created_by_role 已转换为角色ID
-- ==============================================

INSERT INTO `building` (`id`, `name`, `address`, `structure_type`, `build_year`, `floor_count`, `area`, `owner_name`,
                        `owner_phone`, `owner_user_id`, `created_by`, `created_by_role`, `assigned_inspector_id`,
                        `longitude`, `latitude`, `description`, `image_path`, `created_at`, `updated_at`)
VALUES (1, '花园小区1号楼', '朝阳路1号', 'STEEL', 1995, 6, 120.00, '张三', '0734111111', NULL, NULL, NULL, NULL, NULL,
        NULL,
        NULL,
        'buildings/1/images/2026/03/30/274b9342200f471285078b015169969b.jpg',
        '2026-03-30 16:09:08', '2026-03-30 16:12:42'),
       (2, '花园小区2号楼', '朝阳路2号', 'BRICK_WOOD', 1996, 5, 130.00, '李四', '0734222222', NULL, NULL, NULL, NULL,
        NULL, NULL,
        NULL,
        'buildings/2/images/2026/03/30/f1dd4c692cc2474a86c9f29a16bcf9fd.jpg',
        '2026-03-30 16:09:57', '2026-03-30 16:12:55'),
       (3, '花园小区3号楼', '朝阳路3号', 'BRICK_MIX', 1997, 6, 140.00, '王五', '0734333333', NULL, NULL, NULL, NULL,
        NULL, NULL,
        NULL, 'buildings/3/images/2026/03/30/192b51c7f46445cd868820b6c4795421.jpg',
        '2026-03-30 16:10:42', '2026-03-30 16:10:42'),
       (4, '花园小区4号楼', '朝阳路4号', 'CONCRETE', 1998, 8, 180.00, '赵六', '0734555555', NULL, NULL, NULL, NULL,
        NULL, NULL,
        NULL, 'buildings/4/images/2026/03/30/7e7b555659b64091a4512ff19c214711.jpg',
        '2026-03-30 16:12:31', '2026-03-30 16:12:31'),
       (5, '花园小区5号楼', '朝阳路5号', 'OTHER', 1999, 8, 150.00, '周七', '0734888888', NULL, NULL, NULL, NULL, NULL,
        NULL,
        NULL, 'buildings/5/images/2026/03/30/80d08dc6c088429c8e95c68d922ba157.jpg',
        '2026-03-30 17:49:34', '2026-03-30 17:49:34'),
       (6, '花园小区6号楼', '朝阳路6号', 'STEEL', 1998, 4, 120.00, '朱八', '0734666666', 2, 2, 3, NULL, NULL, NULL,
        NULL, 'buildings/6/images/2026/04/12/f62a2fc0ab044e918c2ca62d146841f8.jpg',
        '2026-04-12 00:02:56', '2026-04-12 00:02:56');

-- ==============================================
-- 检测数据
-- ==============================================

INSERT INTO `detection` (`id`, `building_id`, `user_id`, `status`, `crack_count`, `damage_ratio`, `risk_level`,
                         `confidence`, `detect_result`, `detect_time`, `description`, `error_message`, `created_at`,
                         `updated_at`)
VALUES (1, 1, 1, 'COMPLETED', 4, 103.6900, 'D', 89.46, '{
  "cracks": [
    {
      "id": 1,
      "area": 88245,
      "bbox": [
        887,
        6,
        1072,
        483
      ],
      "type": "crack",
      "width": 185,
      "center": [
        979,
        244
      ],
      "height": 477,
      "typeName": "裂缝",
      "confidence": 0.98675936460495
    },
    {
      "id": 2,
      "area": 576400,
      "bbox": [
        0,
        170,
        1048,
        720
      ],
      "type": "crack",
      "width": 1048,
      "center": [
        524,
        445
      ],
      "height": 550,
      "typeName": "裂缝",
      "confidence": 0.9713177680969238
    },
    {
      "id": 3,
      "area": 141616,
      "bbox": [
        35,
        2,
        703,
        214
      ],
      "type": "crack",
      "width": 668,
      "center": [
        369,
        108
      ],
      "height": 212,
      "typeName": "裂缝",
      "confidence": 0.4678124487400055
    },
    {
      "id": 4,
      "area": 760058,
      "bbox": [
        14,
        0,
        1080,
        713
      ],
      "type": "crack",
      "width": 1066,
      "center": [
        547,
        356
      ],
      "height": 713,
      "typeName": "裂缝",
      "confidence": 0.9805333614349364
    }
  ],
  "analysis": "整幢危房，建议立即停止使用并由专业机构鉴定",
  "maxWidth": 1066,
  "crackCount": 4,
  "damageRatio": 103.69,
  "totalCracks": 4,
  "severityLevel": "D",
  "confidenceScore": 89.46
}', '2026-03-30 16:14:23', '3月第一次检测', NULL, '2026-03-30 16:14:15', '2026-03-30 16:14:23'),
       (2, 2, 1, 'COMPLETED', 6, 10.9000, 'C', 66.53, '{
         "cracks": [
           {
             "id": 1,
             "area": 30500,
             "bbox": [
               502,
               108,
               552,
               718
             ],
             "type": "crack",
             "width": 50,
             "center": [
               527,
               413
             ],
             "height": 610,
             "typeName": "裂缝",
             "confidence": 0.9926695823669434
           },
           {
             "id": 2,
             "area": 112,
             "bbox": [
               905,
               370,
               913,
               384
             ],
             "type": "crack",
             "width": 8,
             "center": [
               909,
               377
             ],
             "height": 14,
             "typeName": "裂缝",
             "confidence": 0.4126077890396118
           },
           {
             "id": 3,
             "area": 667,
             "bbox": [
               275,
               137,
               298,
               166
             ],
             "type": "crack",
             "width": 23,
             "center": [
               286,
               151
             ],
             "height": 29,
             "typeName": "裂缝",
             "confidence": 0.3725509345531464
           },
           {
             "id": 4,
             "area": 82302,
             "bbox": [
               380,
               109,
               638,
               428
             ],
             "type": "crack",
             "width": 258,
             "center": [
               509,
               268
             ],
             "height": 319,
             "typeName": "裂缝",
             "confidence": 0.99546080827713
           },
           {
             "id": 5,
             "area": 608,
             "bbox": [
               639,
               589,
               671,
               608
             ],
             "type": "crack",
             "width": 32,
             "center": [
               655,
               598
             ],
             "height": 19,
             "typeName": "裂缝",
             "confidence": 0.8608840107917786
           },
           {
             "id": 6,
             "area": 1820,
             "bbox": [
               943,
               27,
               1073,
               41
             ],
             "type": "crack",
             "width": 130,
             "center": [
               1008,
               34
             ],
             "height": 14,
             "typeName": "裂缝",
             "confidence": 0.3573013246059418
           }
         ],
         "analysis": "局部危房，建议修缮加固",
         "maxWidth": 258,
         "crackCount": 6,
         "damageRatio": 10.9,
         "totalCracks": 6,
         "severityLevel": "C",
         "confidenceScore": 66.53
       }', '2026-03-30 16:16:17', '3月第一次检测', NULL, '2026-03-30 16:16:13', '2026-03-30 16:59:06'),
       (3, 3, 1, 'COMPLETED', 4, 8.2500, 'B', 79.42, '{
         "cracks": [
           {
             "id": 1,
             "area": 64170,
             "bbox": [
               494,
               145,
               632,
               610
             ],
             "type": "crack",
             "width": 138,
             "center": [
               563,
               377
             ],
             "height": 465,
             "typeName": "裂缝",
             "confidence": 0.995890974998474
           },
           {
             "id": 2,
             "area": 30500,
             "bbox": [
               502,
               108,
               552,
               718
             ],
             "type": "crack",
             "width": 50,
             "center": [
               527,
               413
             ],
             "height": 610,
             "typeName": "裂缝",
             "confidence": 0.9926695823669434
           },
           {
             "id": 3,
             "area": 112,
             "bbox": [
               905,
               370,
               913,
               384
             ],
             "type": "crack",
             "width": 8,
             "center": [
               909,
               377
             ],
             "height": 14,
             "typeName": "裂缝",
             "confidence": 0.4126077890396118
           },
           {
             "id": 4,
             "area": 667,
             "bbox": [
               275,
               137,
               298,
               166
             ],
             "type": "crack",
             "width": 23,
             "center": [
               286,
               151
             ],
             "height": 29,
             "typeName": "裂缝",
             "confidence": 0.3725509345531464
           }
         ],
         "analysis": "存在轻微损伤，建议定期观察",
         "maxWidth": 138,
         "crackCount": 4,
         "damageRatio": 8.25,
         "totalCracks": 4,
         "severityLevel": "B",
         "confidenceScore": 79.42
       }', '2026-03-30 16:17:58', '3月份第一次检测', NULL, '2026-03-30 16:17:54', '2026-03-30 16:17:58'),
       (4, 4, 1, 'COMPLETED', 15, 19.0200, 'D', 30.63, '{
         "cracks": [
           {
             "id": 1,
             "area": 5607,
             "bbox": [
               1014,
               1508,
               1077,
               1597
             ],
             "type": "crack",
             "width": 63,
             "center": [
               1045,
               1552
             ],
             "height": 89,
             "typeName": "裂缝",
             "confidence": 0.8980890512466431
           },
           {
             "id": 2,
             "area": 14514,
             "bbox": [
               82,
               1,
               200,
               124
             ],
             "type": "crack",
             "width": 118,
             "center": [
               141,
               62
             ],
             "height": 123,
             "typeName": "裂缝",
             "confidence": 0.895412266254425
           },
           {
             "id": 3,
             "area": 7533,
             "bbox": [
               868,
               609,
               949,
               702
             ],
             "type": "crack",
             "width": 81,
             "center": [
               908,
               655
             ],
             "height": 93,
             "typeName": "裂缝",
             "confidence": 0.8583745956420898
           },
           {
             "id": 4,
             "area": 42262,
             "bbox": [
               62,
               349,
               288,
               536
             ],
             "type": "crack",
             "width": 226,
             "center": [
               175,
               442
             ],
             "height": 187,
             "typeName": "裂缝",
             "confidence": 0.7610817551612854
           },
           {
             "id": 5,
             "area": 2596,
             "bbox": [
               751,
               804,
               810,
               848
             ],
             "type": "crack",
             "width": 59,
             "center": [
               780,
               826
             ],
             "height": 44,
             "typeName": "裂缝",
             "confidence": 0.7129454612731934
           },
           {
             "id": 6,
             "area": 1140,
             "bbox": [
               431,
               1067,
               491,
               1086
             ],
             "type": "crack",
             "width": 60,
             "center": [
               461,
               1076
             ],
             "height": 19,
             "typeName": "裂缝",
             "confidence": 0.7090466618537903
           },
           {
             "id": 7,
             "area": 59670,
             "bbox": [
               950,
               1,
               1080,
               460
             ],
             "type": "crack",
             "width": 130,
             "center": [
               1015,
               230
             ],
             "height": 459,
             "typeName": "裂缝",
             "confidence": 0.6205520629882812
           },
           {
             "id": 8,
             "area": 151600,
             "bbox": [
               3,
               1517,
               403,
               1896
             ],
             "type": "crack",
             "width": 400,
             "center": [
               203,
               1706
             ],
             "height": 379,
             "typeName": "裂缝",
             "confidence": 0.6155219674110413
           },
           {
             "id": 9,
             "area": 4218,
             "bbox": [
               778,
               940,
               835,
               1014
             ],
             "type": "crack",
             "width": 57,
             "center": [
               806,
               977
             ],
             "height": 74,
             "typeName": "裂缝",
             "confidence": 0.6027624607086182
           },
           {
             "id": 10,
             "area": 3477,
             "bbox": [
               202,
               466,
               259,
               527
             ],
             "type": "crack",
             "width": 57,
             "center": [
               230,
               496
             ],
             "height": 61,
             "typeName": "裂缝",
             "confidence": 0.5689234733581543
           },
           {
             "id": 11,
             "area": 3268,
             "bbox": [
               0,
               661,
               43,
               737
             ],
             "type": "crack",
             "width": 43,
             "center": [
               21,
               699
             ],
             "height": 76,
             "typeName": "裂缝",
             "confidence": 0.4573565423488617
           },
           {
             "id": 12,
             "area": 2304,
             "bbox": [
               1029,
               896,
               1077,
               944
             ],
             "type": "crack",
             "width": 48,
             "center": [
               1053,
               920
             ],
             "height": 48,
             "typeName": "裂缝",
             "confidence": 0.3994199931621551
           },
           {
             "id": 13,
             "area": 8664,
             "bbox": [
               704,
               368,
               818,
               444
             ],
             "type": "crack",
             "width": 114,
             "center": [
               761,
               406
             ],
             "height": 76,
             "typeName": "裂缝",
             "confidence": 0.37481993436813354
           },
           {
             "id": 14,
             "area": 24396,
             "bbox": [
               683,
               148,
               897,
               262
             ],
             "type": "crack",
             "width": 214,
             "center": [
               790,
               205
             ],
             "height": 114,
             "typeName": "裂缝",
             "confidence": 0.37287816405296326
           },
           {
             "id": 15,
             "area": 63250,
             "bbox": [
               6,
               1,
               236,
               276
             ],
             "type": "crack",
             "width": 230,
             "center": [
               121,
               138
             ],
             "height": 275,
             "typeName": "裂缝",
             "confidence": 0.3419056236743927
           }
         ],
         "analysis": "整幢危房，建议立即停止使用并由专业机构鉴定",
         "maxWidth": 400,
         "crackCount": 15,
         "damageRatio": 19.02,
         "totalCracks": 15,
         "severityLevel": "D",
         "confidenceScore": 30.63
       }', '2026-03-30 16:19:05', '3月份第一次检测', NULL, '2026-03-30 16:19:01', '2026-03-30 16:19:05'),
       (5, 5, 1, 'COMPLETED', 6, 10.9000, 'C', 66.53, '{
         "cracks": [
           {
             "id": 1,
             "area": 30500,
             "bbox": [
               502,
               108,
               552,
               718
             ],
             "type": "crack",
             "width": 50,
             "center": [
               527,
               413
             ],
             "height": 610,
             "typeName": "裂缝",
             "confidence": 0.9926695823669434
           },
           {
             "id": 2,
             "area": 112,
             "bbox": [
               905,
               370,
               913,
               384
             ],
             "type": "crack",
             "width": 8,
             "center": [
               909,
               377
             ],
             "height": 14,
             "typeName": "裂缝",
             "confidence": 0.4126077890396118
           },
           {
             "id": 3,
             "area": 667,
             "bbox": [
               275,
               137,
               298,
               166
             ],
             "type": "crack",
             "width": 23,
             "center": [
               286,
               151
             ],
             "height": 29,
             "typeName": "裂缝",
             "confidence": 0.3725509345531464
           },
           {
             "id": 4,
             "area": 82302,
             "bbox": [
               380,
               109,
               638,
               428
             ],
             "type": "crack",
             "width": 258,
             "center": [
               509,
               268
             ],
             "height": 319,
             "typeName": "裂缝",
             "confidence": 0.99546080827713
           },
           {
             "id": 5,
             "area": 608,
             "bbox": [
               639,
               589,
               671,
               608
             ],
             "type": "crack",
             "width": 32,
             "center": [
               655,
               598
             ],
             "height": 19,
             "typeName": "裂缝",
             "confidence": 0.8608840107917786
           },
           {
             "id": 6,
             "area": 1820,
             "bbox": [
               943,
               27,
               1073,
               41
             ],
             "type": "crack",
             "width": 130,
             "center": [
               1008,
               34
             ],
             "height": 14,
             "typeName": "裂缝",
             "confidence": 0.3573013246059418
           }
         ],
         "analysis": "局部危房，建议修缮加固",
         "maxWidth": 258,
         "crackCount": 6,
         "damageRatio": 10.9,
         "totalCracks": 6,
         "severityLevel": "C",
         "confidenceScore": 66.53
       }', '2026-03-30 17:50:29', '3月份第一次检测', NULL, '2026-03-30 17:50:23', '2026-03-30 17:50:29'),
       (7, 6, 2, 'COMPLETED', 4, 74.1100, 'D', 89.80, '{
         "cracks": [
           {
             "id": 1,
             "area": 576288,
             "bbox": [
               0,
               0,
               864,
               667
             ],
             "type": "crack",
             "width": 864,
             "center": [
               432,
               333
             ],
             "height": 667,
             "typeName": "裂缝",
             "confidence": 0.9965606331825256
           },
           {
             "id": 2,
             "area": 143208,
             "bbox": [
               873,
               0,
               1077,
               702
             ],
             "type": "crack",
             "width": 204,
             "center": [
               975,
               351
             ],
             "height": 702,
             "typeName": "裂缝",
             "confidence": 0.9841758608818054
           },
           {
             "id": 3,
             "area": 665,
             "bbox": [
               957,
               142,
               976,
               177
             ],
             "type": "crack",
             "width": 19,
             "center": [
               966,
               159
             ],
             "height": 35,
             "typeName": "裂缝",
             "confidence": 0.8048736453056335
           },
           {
             "id": 4,
             "area": 36660,
             "bbox": [
               792,
               550,
               1027,
               706
             ],
             "type": "crack",
             "width": 235,
             "center": [
               909,
               628
             ],
             "height": 156,
             "typeName": "裂缝",
             "confidence": 0.6089444756507874
           }
         ],
         "analysis": "整幢危房，建议立即停止使用并由专业机构鉴定",
         "maxWidth": 864,
         "crackCount": 4,
         "damageRatio": 74.11,
         "totalCracks": 4,
         "severityLevel": "D",
         "confidenceScore": 89.8
       }', '2026-04-12 16:47:39', '4月第一次检测', NULL, '2026-04-12 00:05:55', '2026-04-12 16:47:39');

-- ==============================================
-- 图片数据
-- ==============================================

INSERT INTO `image` (`id`, `detection_id`, `image_path`, `result_image_path`, `image_type`, `upload_time`)
VALUES (1, 1, 'detections/1/original/2026/03/30/53a4307081bd41afb1301ed5400e13b7.jpg',
        'detections/1/result/2026/03/30/aa1d06b546394310bf528b271226386d.jpg', 'ORIGINAL', '2026-03-30 16:14:16'),
       (2, 1, 'detections/1/original/2026/03/30/edaa63eae5cd422c83c1c3e3cae24370.jpg',
        'detections/1/result/2026/03/30/51066eadba9240ba8508fd95929db53c.jpg', 'ORIGINAL', '2026-03-30 16:14:16'),
       (3, 2, 'detections/2/original/2026/03/30/3081d7cb0dbb42faa674f507bbdd8f49.jpg',
        'detections/2/result/2026/03/30/7bd127e3cb7b4643b883811fa8f1f4fd.jpg', 'ORIGINAL', '2026-03-30 16:16:14'),
       (4, 2, 'detections/2/original/2026/03/30/4d0713cd93d543fc901b83ba262030f7.jpg',
        'detections/2/result/2026/03/30/2ee58de821d54dffa4be2729a294176b.jpg', 'ORIGINAL', '2026-03-30 16:16:14'),
       (5, 3, 'detections/3/original/2026/03/30/9133b0e23b1e46f0ae84860510a983f6.jpg',
        'detections/3/result/2026/03/30/5c2da527e59a4439a112daacaaa2b3dd.jpg', 'ORIGINAL', '2026-03-30 16:17:55'),
       (6, 3, 'detections/3/original/2026/03/30/d8b43defedbb46de8cc46409e690ae93.jpg',
        'detections/3/result/2026/03/30/394cc00300e54b6582b441cb9e28fa1e.jpg', 'ORIGINAL', '2026-03-30 16:17:55'),
       (7, 4, 'detections/4/original/2026/03/30/8c03303d3f2640d1bfbb62bd5a6fd149.jpg',
        'detections/4/result/2026/03/30/825eb95e2ed8494492be2371e68bfeb5.jpg', 'ORIGINAL', '2026-03-30 16:19:02'),
       (8, 4, 'detections/4/original/2026/03/30/1836a94b3c1c436ea55b194a903f318d.jpg',
        'detections/4/result/2026/03/30/b141477ea7dd4e588f3e22753994dd45.jpg', 'ORIGINAL', '2026-03-30 16:19:02'),
       (9, 5, 'detections/5/original/2026/03/30/562b80f9941d43e3a7c8cc4e36d6b452.jpg',
        'detections/5/result/2026/03/30/b530fc11faf04fdba3c1093b10f8cfcf.jpg', 'ORIGINAL', '2026-03-30 17:50:24'),
       (10, 5, 'detections/5/original/2026/03/30/db1ffc263717435a8b19969993acb727.jpg',
        'detections/5/result/2026/03/30/58f9542e7178454181b16e3de229fe84.jpg', 'ORIGINAL', '2026-03-30 17:50:24'),
       (11, 7, 'detections/7/original/2026/04/12/8a5629975d414512a4fdc4b96d756a48.jpg',
        'detections/7/result/2026/04/12/83e0a983d0f8496a831cf7c1dc831376.jpg', 'ORIGINAL', '2026-04-12 00:05:56'),
       (12, 7, 'detections/7/original/2026/04/12/1ccddcf66512447688f4946791a5143e.jpg',
        'detections/7/result/2026/04/12/8def3079b81445c8b73aac3952cb71e3.jpg', 'ORIGINAL', '2026-04-12 00:05:56');

-- ==============================================
-- 报告数据
-- ==============================================

INSERT INTO `report` (`id`, `detection_id`, `building_id`, `report_no`, `file_path`, `file_type`, `generated_at`)
VALUES (1, 5, 5, 'RPT20260330175050000005', 'detections/5/reports/2026/03/30/RPT20260330175050000005.pdf', 'PDF',
        '2026-03-30 17:50:50'),
       (2, 4, 4, 'RPT20260331125404000004', 'detections/4/reports/2026/03/31/RPT20260331125404000004.pdf', 'PDF',
        '2026-03-31 12:54:05'),
       (3, 7, 6, 'RPT20260412173204000007', 'detections/7/reports/2026/04/12/RPT20260412173204000007.pdf', 'PDF',
        '2026-04-12 17:32:05');

ALTER TABLE `role`
    AUTO_INCREMENT = 4;

ALTER TABLE `user`
    AUTO_INCREMENT = 4;

ALTER TABLE `building`
    AUTO_INCREMENT = 7;

ALTER TABLE `detection`
    AUTO_INCREMENT = 8;

ALTER TABLE `image`
    AUTO_INCREMENT = 13;

ALTER TABLE `report`
    AUTO_INCREMENT = 4;

ALTER TABLE `user_role`
    AUTO_INCREMENT = 4;

SET FOREIGN_KEY_CHECKS = 1;
