import type { RouteRecordRaw } from "vue-router";

import router from "@/router";
import { usePermissionStore, useUserStore } from "@/store";
import NProgress from "@/utils/nprogress";

const WHITE_LIST = ["/login"];
const LOGIN_REDIRECT_KEY = "dangerhouse_login_redirect";

export function setupPermission() {
  router.beforeEach(async (to, from, next) => {
    NProgress.start();

    const hasToken = Boolean(localStorage.getItem("token"));

    if (hasToken) {
      if (to.path === "/login") {
        next({ path: "/" });
        NProgress.done();
        return;
      }

      const userStore = useUserStore();
      const permissionStore = usePermissionStore();
      const hasRoles =
        Array.isArray(userStore.user.roles) && userStore.user.roles.length > 0;
      const hasGeneratedRoutes = permissionStore.routes.length > 0;

      if (hasRoles && hasGeneratedRoutes) {
        if (to.matched.length === 0) {
          from.name ? next({ name: from.name }) : next("/404");
        } else {
          next();
        }
        return;
      }

      try {
        const roles = hasRoles
          ? userStore.user.roles
          : (await userStore.getUserInfo()).roles;
        const accessRoutes = await permissionStore.generateRoutes(roles);

        accessRoutes.forEach((route: RouteRecordRaw) => {
          router.addRoute(route);
        });

        next({ ...to, replace: true });
      } catch {
        await userStore.resetToken();
        sessionStorage.setItem(LOGIN_REDIRECT_KEY, to.fullPath || to.path);
        next("/login");
        NProgress.done();
      }
      return;
    }

    if (WHITE_LIST.includes(to.path)) {
      next();
      return;
    }

    sessionStorage.setItem(LOGIN_REDIRECT_KEY, to.fullPath || to.path);
    next("/login");
    NProgress.done();
  });

  router.afterEach(() => {
    NProgress.done();
  });
}
