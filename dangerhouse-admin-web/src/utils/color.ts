function clamp(value: number) {
  return Math.max(0, Math.min(255, Math.round(value)));
}

function hexToRgb(hex: string) {
  const normalized = hex.replace("#", "");
  const full =
    normalized.length === 3
      ? normalized
          .split("")
          .map((char) => char + char)
          .join("")
      : normalized;

  const num = Number.parseInt(full, 16);
  return {
    r: (num >> 16) & 255,
    g: (num >> 8) & 255,
    b: num & 255,
  };
}

function rgbToHex(r: number, g: number, b: number) {
  return `#${[r, g, b]
    .map((item) => clamp(item).toString(16).padStart(2, "0"))
    .join("")}`;
}

function mix(hex: string, amount: number, target: number) {
  const { r, g, b } = hexToRgb(hex);
  return rgbToHex(
    r + (target - r) * amount,
    g + (target - g) * amount,
    b + (target - b) * amount
  );
}

export function genMixColor(color: string) {
  const light: Record<number, string> = {};
  const dark: Record<number, string> = {};

  for (let i = 1; i <= 9; i += 1) {
    light[i] = mix(color, i / 10, 255);
    dark[i] = mix(color, i / 10, 0);
  }

  return {
    DEFAULT: color,
    light,
    dark,
  };
}
