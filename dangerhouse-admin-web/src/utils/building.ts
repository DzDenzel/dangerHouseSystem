const structureTypeMap: Record<string, string> = {
  BRICK_MIX: "砖混结构",
  CONCRETE: "钢筋混凝土",
  BRICK_WOOD: "砖木结构",
  STEEL: "钢结构",
  OTHER: "其他",
};

export function getStructureTypeLabel(value?: string) {
  if (!value) return "-";
  return structureTypeMap[value] || value;
}

export function getStructureTypeValue(label?: string) {
  if (!label) return "";
  const matched = Object.entries(structureTypeMap).find(
    ([, mappedLabel]) => mappedLabel === label
  );
  return matched?.[0] || label;
}

export function getStructureTypeOptions() {
  return Object.entries(structureTypeMap).map(([value, label]) => ({
    value,
    label,
  }));
}

const roleNameMap: Record<number, string> = {
  1: "管理员",
  2: "检测员",
  3: "普通用户",
};

export function getRoleLabel(roleId?: number | null, roleName?: string | null) {
  if (roleName && roleName.trim().length > 0) {
    return roleName;
  }
  if (roleId == null) {
    return "-";
  }
  return roleNameMap[roleId] || `角色#${roleId}`;
}
