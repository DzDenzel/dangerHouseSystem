export function isExternal(path: string) {
  return /^(https?:|mailto:|tel:)/.test(path);
}

export function setStyleProperty(name: string, value: string) {
  document.documentElement.style.setProperty(name, value);
}
