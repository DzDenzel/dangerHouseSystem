import { ref } from "vue";
import { defineStore } from "pinia";
import type { RouteRecordRaw } from "vue-router";
import { constantRoutes } from "@/router";
import { store } from "@/store";
import { listRoutes } from "@/api/menu";

const modules = import.meta.glob("../../views/**/**.vue");
const Layout = () => import("@/layout/index.vue");

const useBackendMenus =
  (import.meta as any).env?.VITE_USE_BACKEND_MENUS === "true";
const enableSystemPages =
  (import.meta as any).env?.VITE_ENABLE_SYSTEM_PAGES === "true";

const buildingRoutes: any = {
  path: "/building",
  component: "Layout" as unknown as any,
  redirect: "/building/list",
  meta: { title: "建筑管理", icon: "OfficeBuilding", roles: ["ADMIN"] },
  children: [
    {
      path: "list",
      component: "building/index",
      name: "BuildingList",
      meta: { title: "建筑列表", icon: "OfficeBuilding", roles: ["ADMIN"] },
    },
    {
      path: "risk",
      component: "building/risk/index",
      name: "BuildingRisk",
      meta: { title: "高危建筑", icon: "Warning", roles: ["ADMIN"] },
    },
    {
      path: "detail",
      component: "building/detail/index",
      name: "BuildingDetail",
      meta: {
        title: "建筑详情",
        icon: "OfficeBuilding",
        hidden: true,
        roles: ["ADMIN"],
      },
    },
  ],
};

const detectionRoutes: any = {
  path: "/detection",
  component: "Layout" as unknown as any,
  redirect: "/detection/records",
  meta: {
    title: "检测管理",
    icon: "Check",
    roles: ["ADMIN"],
    alwaysShow: true,
  },
  children: [
    {
      path: "records",
      component: "detection/records/index",
      name: "Records",
      meta: { title: "检测记录", icon: "Document", roles: ["ADMIN"] },
    },
    {
      path: "detail",
      component: "detection/detail/index",
      name: "DetectionDetail",
      meta: {
        title: "检测详情",
        icon: "Document",
        hidden: true,
        roles: ["ADMIN"],
      },
    },
  ],
};

const systemRoutes: any = {
  path: "/system",
  component: "Layout" as unknown as any,
  meta: { title: "系统管理", icon: "Setting", roles: ["ADMIN"] },
  children: [
    {
      path: "user",
      component: "system/user/index",
      name: "User",
      meta: { title: "用户管理", icon: "User", roles: ["ADMIN"] },
    },
    {
      path: "log",
      component: "system/log/index",
      name: "Log",
      meta: { title: "操作日志", icon: "Document", roles: ["ADMIN"] },
    },
  ],
};

const fallbackAsyncRoutes: any[] = [
  buildingRoutes,
  detectionRoutes,
  ...(enableSystemPages ? [systemRoutes] : []),
];

const hasPermission = (roles: string[], route: RouteRecordRaw) => {
  if (route.meta?.roles) {
    if (roles.includes("ROOT")) return true;
    return roles.some((role) => route.meta?.roles?.includes(role));
  }
  return false;
};

const filterAsyncRoutes = (routes: RouteRecordRaw[], roles: string[]) => {
  const asyncRoutes: RouteRecordRaw[] = [];

  routes.forEach((route) => {
    const tmpRoute = { ...route };
    if (!tmpRoute.name) {
      tmpRoute.name = tmpRoute.path;
    }

    if (!hasPermission(roles, tmpRoute)) return;

    if (tmpRoute.component?.toString() === "Layout") {
      tmpRoute.component = Layout;
    } else {
      const component = modules[`../../views/${tmpRoute.component}.vue`];
      tmpRoute.component =
        component || modules[`../../views/error-page/404.vue`];
    }

    if (tmpRoute.children) {
      tmpRoute.children = filterAsyncRoutes(tmpRoute.children, roles);
    }

    asyncRoutes.push(tmpRoute);
  });

  return asyncRoutes;
};

export const usePermissionStore = defineStore("permission", () => {
  const routes = ref<RouteRecordRaw[]>([]);
  const mixLeftMenus = ref<RouteRecordRaw[]>([]);

  function setRoutes(newRoutes: RouteRecordRaw[]) {
    routes.value = constantRoutes.concat(newRoutes);
  }

  function generateRoutes(roles: string[]) {
    return new Promise<RouteRecordRaw[]>((resolve) => {
      if (!useBackendMenus) {
        const fallback = filterAsyncRoutes(fallbackAsyncRoutes, roles);
        setRoutes(fallback);
        resolve(fallback);
        return;
      }

      listRoutes()
        .then(({ data: asyncRoutes }) => {
          const accessedRoutes = filterAsyncRoutes(asyncRoutes, roles);
          if (accessedRoutes.length > 0) {
            setRoutes(accessedRoutes);
            resolve(accessedRoutes);
            return;
          }

          const fallback = filterAsyncRoutes(fallbackAsyncRoutes, roles);
          setRoutes(fallback);
          resolve(fallback);
        })
        .catch(() => {
          const fallback = filterAsyncRoutes(fallbackAsyncRoutes, roles);
          setRoutes(fallback);
          resolve(fallback);
        });
    });
  }

  function setMixLeftMenus(topMenuPath: string) {
    const matchedItem = routes.value.find((item) => item.path === topMenuPath);
    mixLeftMenus.value = matchedItem?.children || [];
  }

  return {
    routes,
    mixLeftMenus,
    setRoutes,
    generateRoutes,
    setMixLeftMenus,
  };
});

export function usePermissionStoreHook() {
  return usePermissionStore(store);
}
