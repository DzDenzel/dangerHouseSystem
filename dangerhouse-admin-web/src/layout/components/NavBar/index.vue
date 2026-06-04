<template>
  <!-- 顶部导航栏 -->
  <div class="navbar-container">
    <!-- 导航栏左侧 -->
    <NavbarLeft />
    <!-- 导航栏右侧 -->
    <NavbarRight />
  </div>
</template>

<style lang="scss" scoped>
.navbar-container {
  display: flex;
  align-items: center;
  justify-content: space-between;
  height: $navbar-height;
  padding: 0 12px 0 4px;
  background: linear-gradient(
    180deg,
    rgb(255 255 255 / 95%),
    rgb(248 250 252 / 92%)
  );
  backdrop-filter: blur(10px);
  border-bottom: 1px solid rgb(148 163 184 / 14%);
  box-shadow: 0 6px 16px rgb(15 23 42 / 4%);

  :global(.layout-top) &,
  :global(.layout-mix) & {
    background: transparent;
    border-bottom: none;
    box-shadow: none;
  }
}
</style>
