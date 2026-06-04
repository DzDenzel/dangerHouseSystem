export function formatDateTime(value?: string | Date | null) {
  if (!value) return "-";

  if (value instanceof Date) {
    return `${value.getFullYear()}-${`${value.getMonth() + 1}`.padStart(2, "0")}-${`${value.getDate()}`.padStart(2, "0")} ${`${value.getHours()}`.padStart(2, "0")}:${`${value.getMinutes()}`.padStart(2, "0")}:${`${value.getSeconds()}`.padStart(2, "0")}`;
  }

  const normalized = value.replace("T", " ").replace(/\.\d+$/, "");
  return normalized.slice(0, 19);
}

export function formatDate(value?: string | Date | null) {
  if (!value) return "-";

  if (value instanceof Date) {
    return `${value.getFullYear()}-${`${value.getMonth() + 1}`.padStart(2, "0")}-${`${value.getDate()}`.padStart(2, "0")}`;
  }

  return value.replace("T", " ").slice(0, 10);
}
