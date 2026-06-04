package com.dz.dangerhouse.common;

import lombok.Getter;

/**
 * 风险等级定义
 */
@Getter
public enum RiskLevel {

    A("A", "LOW", "低风险", "低风险", "#28A745", 0.0, 5.0),
    B("B", "MEDIUM", "中风险", "中风险", "#FFC107", 5.0, 15.0),
    C("C", "HIGH", "高风险", "高风险", "#FD7E14", 15.0, 30.0),
    D("D", "CRITICAL", "严重", "严重风险", "#DC3545", 30.0, 100.0);

    private final String code;
    private final String legacyCode;
    private final String name;
    private final String description;
    private final String color;
    private final Double minDamageRatio;
    private final Double maxDamageRatio;

    RiskLevel(String code, String legacyCode, String name, String description, String color, Double minDamageRatio, Double maxDamageRatio) {
        this.code = code;
        this.legacyCode = legacyCode;
        this.name = name;
        this.description = description;
        this.color = color;
        this.minDamageRatio = minDamageRatio;
        this.maxDamageRatio = maxDamageRatio;
    }

    /**
     * 根据损坏率获取风险等级
     */
    public static RiskLevel fromDamageRatio(Double damageRatio) {
        if (damageRatio == null) {
            return A;
        }
        if (damageRatio < 5.0) {
            return A;
        } else if (damageRatio < 15.0) {
            return B;
        } else if (damageRatio < 30.0) {
            return C;
        } else {
            return D;
        }
    }

    /**
     * 根据代码获取风险等级
     */
    public static RiskLevel fromCode(String code) {
        if (code == null) {
            return null;
        }
        for (RiskLevel level : values()) {
            if (level.code.equalsIgnoreCase(code)) {
                return level;
            }
        }
        return null;
    }

    /**
     * 根据遗留代码获取风险等级
     */
    public static RiskLevel fromLegacyCode(String legacyCode) {
        if (legacyCode == null) {
            return null;
        }
        for (RiskLevel level : values()) {
            if (level.legacyCode.equalsIgnoreCase(legacyCode)) {
                return level;
            }
        }
        return null;
    }

    /**
     * 获取等级顺序
     */
    public int getOrder() {
        return ordinal() + 1;
    }

    /**
     * 比较两个风险等级
     */
    public static int compare(String level1, String level2) {
        RiskLevel r1 = fromCode(level1);
        RiskLevel r2 = fromCode(level2);
        if (r1 == null && r2 == null) return 0;
        if (r1 == null) return -1;
        if (r2 == null) return 1;
        return r1.getOrder() - r2.getOrder();
    }

    /**
     * 获取所有等级代码
     */
    public static String[] getAllCodes() {
        return new String[]{"A", "B", "C", "D"};
    }
}
