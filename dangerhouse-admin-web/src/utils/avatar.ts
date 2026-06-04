const DEFAULT_AVATAR =
  "data:image/svg+xml;utf8," +
  encodeURIComponent(`
    <svg xmlns="http://www.w3.org/2000/svg" width="96" height="96" viewBox="0 0 96 96">
      <rect width="96" height="96" rx="48" fill="#dbeafe"/>
      <circle cx="48" cy="36" r="18" fill="#60a5fa"/>
      <path d="M18 84c6-16 20-24 30-24s24 8 30 24" fill="#60a5fa"/>
    </svg>
  `);

export function resolveAvatarUrl(avatar?: string, size = 80) {
  if (!avatar) return DEFAULT_AVATAR;

  const trimmed = avatar.trim();
  if (!trimmed) return DEFAULT_AVATAR;

  if (trimmed.startsWith("data:")) return trimmed;

  const hasQuery = trimmed.includes("?");
  const isHttp = /^https?:\/\//i.test(trimmed);
  const isImageFile = /\.(png|jpg|jpeg|gif|webp|bmp|svg)(\?.*)?$/i.test(
    trimmed
  );

  if (isHttp && !hasQuery && !isImageFile) {
    return `${trimmed}?imageView2/1/w/${size}/h/${size}`;
  }

  return trimmed;
}

export function getAvatarFallbackText(name?: string) {
  return name?.trim()?.slice(0, 1)?.toUpperCase() || "U";
}
