<template>
  <div class="tags-container">
    <el-scrollbar
      class="scroll-container"
      :vertical="false"
      @wheel.prevent="handleScroll"
    >
      <router-link
        ref="tagRef"
        v-for="tag in visitedViews"
        :key="tag.fullPath"
        :class="'tags-item ' + (isActive(tag) ? 'active' : '')"
        :to="{ path: tag.path, query: tag.query }"
        @click.middle="!isAffix(tag) ? closeSelectedTag(tag) : ''"
        @contextmenu.prevent="openContentMenu(tag, $event)"
      >
        {{ translateRouteTitle(tag.title) }}
        <i-ep-close
          v-if="!isAffix(tag)"
          class="close-icon"
          size="12px"
          @click.prevent.stop="closeSelectedTag(tag)"
        />
      </router-link>
    </el-scrollbar>

    <!-- Tag context menu -->
    <ul
      v-show="contentMenuVisible"
      class="contextmenu"
      :style="{ left: left + 'px', top: top + 'px' }"
    >
      <li @click="refreshSelectedTag(selectedTag)">
        <svg-icon icon-class="refresh" />
        刷新
      </li>
      <li v-if="!isAffix(selectedTag)" @click="closeSelectedTag(selectedTag)">
        <svg-icon icon-class="close" />
        关闭
      </li>
      <li @click="closeOtherTags">
        <svg-icon icon-class="close_other" />
        关闭其他
      </li>
      <li v-if="!isFirstView()" @click="closeLeftTags">
        <svg-icon icon-class="close_left" />
        关闭左侧
      </li>
      <li v-if="!isLastView()" @click="closeRightTags">
        <svg-icon icon-class="close_right" />
        关闭右侧
      </li>
      <li @click="closeAllTags(selectedTag)">
        <svg-icon icon-class="close_all" />
        关闭全部
      </li>
    </ul>
  </div>
</template>

<script setup lang="ts">
import {
  ref,
  computed,
  watch,
  nextTick,
  onMounted,
  getCurrentInstance,
} from "vue";
import { storeToRefs } from "pinia";
import { useRoute, useRouter, RouteRecordRaw } from "vue-router";
import { resolve } from "path-browserify";
import { translateRouteTitle } from "@/utils/i18n";
import {
  usePermissionStore,
  useTagsViewStore,
  useSettingsStore,
  useAppStore,
} from "@/store";

const { proxy } = getCurrentInstance()!;
const router = useRouter();
const route = useRoute();

const permissionStore = usePermissionStore();
const tagsViewStore = useTagsViewStore();
const appStore = useAppStore();

const { visitedViews } = storeToRefs(tagsViewStore);
const settingsStore = useSettingsStore();
const layout = computed(() => settingsStore.layout);

const selectedTag = ref<TagView>({
  path: "",
  fullPath: "",
  name: "",
  title: "",
  affix: false,
  keepAlive: false,
});

const affixTags = ref<TagView[]>([]);
const left = ref(0);
const top = ref(0);

watch(
  route,
  () => {
    addTags();
    moveToCurrentTag();
  },
  {
    immediate: true,
  }
);

const contentMenuVisible = ref(false);
watch(contentMenuVisible, (value) => {
  if (value) {
    document.body.addEventListener("click", closeContentMenu);
  } else {
    document.body.removeEventListener("click", closeContentMenu);
  }
});

/**
 * 从路由记录中收集固定标签
 */
function filterAffixTags(routes: RouteRecordRaw[], basePath = "/") {
  let tags: TagView[] = [];
  routes.forEach((route: RouteRecordRaw) => {
    const tagPath = resolve(basePath, route.path);
    if (route.meta?.affix) {
      tags.push({
        path: tagPath,
        fullPath: tagPath,
        name: String(route.name),
        title: route.meta?.title || "no-name",
        affix: !!route.meta?.affix,
        keepAlive: !!route.meta?.keepAlive,
      });
    }
    if (route.children) {
      const tempTags = filterAffixTags(route.children, basePath + route.path);
      if (tempTags.length >= 1) {
        tags = [...tags, ...tempTags];
      }
    }
  });
  return tags;
}

function initTags() {
  const tags: TagView[] = filterAffixTags(permissionStore.routes);
  affixTags.value = tags;
  for (const tag of tags) {
    // 有效的固定标签必须有路由名称
    if (tag.name) {
      tagsViewStore.addVisitedView(tag);
    }
  }
}

function addTags() {
  if (route.meta.title) {
    tagsViewStore.addView({
      name: route.name as string,
      title: route.meta.title,
      path: route.path,
      fullPath: route.fullPath,
      affix: !!route.meta?.affix,
      keepAlive: !!route.meta?.keepAlive,
    });
  }
}

function moveToCurrentTag() {
  nextTick(() => {
    for (const tag of visitedViews.value) {
      if (tag.path === route.path && tag.fullPath !== route.fullPath) {
        tagsViewStore.updateVisitedView({
          name: route.name as string,
          title: route.meta.title || "",
          path: route.path,
          fullPath: route.fullPath,
          affix: !!route.meta?.affix,
          keepAlive: !!route.meta?.keepAlive,
        });
      }
    }
  });
}

function isActive(tag: TagView) {
  return tag.path === route.path;
}

function isAffix(tag: TagView) {
  return tag?.affix;
}

function isFirstView() {
  try {
    return (
      selectedTag.value.path === "/dashboard" ||
      selectedTag.value.fullPath === tagsViewStore.visitedViews[1].fullPath
    );
  } catch {
    return false;
  }
}

function isLastView() {
  try {
    return (
      selectedTag.value.fullPath ===
      tagsViewStore.visitedViews[tagsViewStore.visitedViews.length - 1].fullPath
    );
  } catch {
    return false;
  }
}

function refreshSelectedTag(view: TagView) {
  tagsViewStore.delCachedView(view);
  const { fullPath } = view;
  nextTick(() => {
    router.replace({ path: "/redirect" + fullPath });
  });
}

function toLastView(visitedViews: TagView[], view?: TagView) {
  const latestView = visitedViews.slice(-1)[0];
  if (latestView && latestView.fullPath) {
    router.push(latestView.fullPath);
  } else if (view?.name === "Dashboard") {
    router.replace({ path: "/redirect" + view.fullPath });
  } else {
    router.push("/");
  }
}

function closeSelectedTag(view: TagView) {
  tagsViewStore.delView(view).then((res: any) => {
    if (isActive(view)) {
      toLastView(res.visitedViews, view);
    }
  });
}

function closeLeftTags() {
  tagsViewStore.delLeftViews(selectedTag.value).then((res: any) => {
    if (!res.visitedViews.find((item: any) => item.path === route.path)) {
      toLastView(res.visitedViews);
    }
  });
}

function closeRightTags() {
  tagsViewStore.delRightViews(selectedTag.value).then((res: any) => {
    if (!res.visitedViews.find((item: any) => item.path === route.path)) {
      toLastView(res.visitedViews);
    }
  });
}

function closeOtherTags() {
  router.push(selectedTag.value);
  tagsViewStore.delOtherViews(selectedTag.value).then(() => {
    moveToCurrentTag();
  });
}

function closeAllTags(view: TagView) {
  tagsViewStore.delAllViews().then((res: any) => {
    toLastView(res.visitedViews, view);
  });
}

/**
 * 打开标签右键菜单
 */
function openContentMenu(tag: TagView, e: MouseEvent) {
  const menuMinWidth = 105;
  const offsetLeft = proxy?.$el.getBoundingClientRect().left;
  const offsetWidth = proxy?.$el.offsetWidth;
  const maxLeft = offsetWidth - menuMinWidth;
  const l = e.clientX - offsetLeft + 15;

  left.value = l > maxLeft ? maxLeft : l;
  top.value = layout.value === "mix" ? e.clientY - 50 : e.clientY;
  contentMenuVisible.value = true;
  selectedTag.value = tag;
}

/**
 * 关闭标签右键菜单
 */
function closeContentMenu() {
  contentMenuVisible.value = false;
}

/**
 * 滚动时隐藏右键菜单
 */
function handleScroll() {
  closeContentMenu();
}

function findOutermostParent(tree: any[], findName: string) {
  const parentMap: Record<string, any> = {};

  function buildParentMap(node: any, parent: any) {
    parentMap[node.name] = parent;
    if (node.children) {
      for (let i = 0; i < node.children.length; i++) {
        buildParentMap(node.children[i], node);
      }
    }
  }

  for (let i = 0; i < tree.length; i++) {
    buildParentMap(tree[i], null);
  }

  let currentNode = parentMap[findName];
  while (currentNode) {
    if (!parentMap[currentNode.name]) {
      return currentNode;
    }
    currentNode = parentMap[currentNode.name];
  }

  return null;
}

const syncActiveTopMenu = (newVal: string) => {
  if (layout.value !== "mix") return;
  const parent = findOutermostParent(permissionStore.routes, newVal);
  if (parent && appStore.activeTopMenu !== parent.path) {
    appStore.activeTopMenu(parent.path);
  }
};

// 使用混合布局时保持顶部菜单高亮同步
watch(
  () => route.name,
  (newVal) => {
    if (newVal) {
      syncActiveTopMenu(newVal as string);
    }
  },
  {
    deep: true,
  }
);

onMounted(() => {
  initTags();
});
</script>

<style lang="scss" scoped>
.tags-container {
  width: 100%;
  height: 34px;
  background: rgb(255 255 255 / 82%);
  backdrop-filter: blur(10px);
  border-bottom: 1px solid rgb(148 163 184 / 14%);

  .tags-item {
    display: inline-block;
    padding: 5px 10px;
    margin: 4px 0 0 5px;
    font-size: 12px;
    cursor: pointer;
    background: rgb(255 255 255 / 88%);
    border: 1px solid rgb(203 213 225 / 72%);
    border-radius: 10px;
    transition: all 0.2s ease;

    &:hover {
      color: var(--el-color-primary);
      background: rgb(239 246 255 / 96%);
      border-color: rgb(96 165 250 / 38%);
    }

    &:first-of-type {
      margin-left: 15px;
    }

    &:last-of-type {
      margin-right: 15px;
    }

    .close-icon {
      border-radius: 50%;

      &:hover {
        color: #fff;
        background-color: var(--el-color-primary);
      }
    }

    &.active {
      color: #fff;
      background: linear-gradient(135deg, var(--el-color-primary), #2563eb);
      border-color: transparent;
      box-shadow: 0 8px 18px rgb(37 99 235 / 22%);

      &::before {
        display: inline-block;
        width: 7px;
        height: 7px;
        margin-right: 5px;
        content: "";
        background: #fff;
        border-radius: 50%;
      }

      .close-icon:hover {
        color: var(--el-color-primary);
        background-color: var(--el-fill-color-light);
      }
    }
  }
}

.contextmenu {
  position: absolute;
  z-index: 99;
  font-size: 12px;
  background: rgb(255 255 255 / 96%);
  border: 1px solid rgb(148 163 184 / 16%);
  border-radius: 12px;
  box-shadow: 0 18px 34px rgb(15 23 42 / 12%);

  li {
    padding: 8px 16px;
    cursor: pointer;
    transition: background-color 0.2s ease;

    &:hover {
      background: var(--el-fill-color-light);
    }
  }
}

.scroll-container {
  position: relative;
  width: 100%;
  overflow: hidden;
  white-space: nowrap;

  .el-scrollbar__bar {
    bottom: 0;
  }

  .el-scrollbar__wrap {
    height: 49px;
  }
}
</style>
