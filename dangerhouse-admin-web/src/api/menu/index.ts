import request from "@/utils/request";
import { AxiosPromise } from "axios";
import { MenuQuery, MenuVO, MenuForm } from "./types";
const SYS_LOCAL = (import.meta as any).env?.VITE_SYSTEM_LOCAL_MODE === "true";

/**
 * 获取路由列表
 */
export function listRoutes() {
  return request({
    url: "/menus/routes",
    method: "get",
    headers: { "X-Silent-Error": "true" },
  });
}

/**
 * 获取菜单树形列表
 *
 * @param queryParams
 */
export function listMenus(queryParams: MenuQuery): AxiosPromise<MenuVO[]> {
  if (SYS_LOCAL) {
    const data: MenuVO[] = [
      {
        id: 1,
        name: "系统管理",
        type: "CATALOG" as any,
        path: "/system",
        component: "Layout",
        sort: 1,
        visible: 1,
        children: [
          {
            id: 11,
            name: "用户管理",
            type: "MENU" as any,
            path: "user",
            component: "system/user/index",
            sort: 1,
            visible: 1,
            children: [],
          },
          {
            id: 12,
            name: "角色管理",
            type: "MENU" as any,
            path: "role",
            component: "system/role/index",
            sort: 2,
            visible: 1,
            children: [],
          },
          {
            id: 13,
            name: "菜单管理",
            type: "MENU" as any,
            path: "menu",
            component: "system/menu/index",
            sort: 3,
            visible: 1,
            children: [],
          },
          {
            id: 14,
            name: "部门管理",
            type: "MENU" as any,
            path: "dept",
            component: "system/dept/index",
            sort: 4,
            visible: 1,
            children: [],
          },
          {
            id: 15,
            name: "字典管理",
            type: "MENU" as any,
            path: "dict",
            component: "system/dict/index",
            sort: 5,
            visible: 1,
            children: [],
          },
          {
            id: 16,
            name: "操作日志",
            type: "MENU" as any,
            path: "log",
            component: "system/log/index",
            sort: 6,
            visible: 1,
            children: [],
          },
        ],
      },
    ];
    return Promise.resolve({ code: 200, message: "成功", data } as any);
  }
  return request({
    url: "/menus",
    method: "get",
    params: queryParams,
  });
}

/**
 * 获取菜单下拉树形列表
 */
export function getMenuOptions(): AxiosPromise<OptionType[]> {
  if (SYS_LOCAL) {
    const data = [
      { label: "系统管理", value: 1 },
      { label: "用户管理", value: 11 },
      { label: "角色管理", value: 12 },
    ];
    return Promise.resolve({ code: 200, message: "success", data } as any);
  }
  return request({
    url: "/menus/options",
    method: "get",
  });
}

/**
 * 获取菜单表单数据
 *
 * @param id
 */
export function getMenuForm(id: number): AxiosPromise<MenuForm> {
  if (SYS_LOCAL) {
    const data = {
      id,
      name: "菜单",
      path: "menu",
      component: "system/menu/index",
      type: "MENU",
      sort: 1,
      visible: 1,
    } as any;
    return Promise.resolve({ code: 200, message: "success", data } as any);
  }
  return request({
    url: "/menus/" + id + "/form",
    method: "get",
  });
}

/**
 * 添加菜单
 *
 * @param data
 */
export function addMenu(data: MenuForm) {
  if (SYS_LOCAL) {
    return Promise.resolve({ code: 200, message: "成功", data: 1 } as any);
  }
  return request({
    url: "/menus",
    method: "post",
    data: data,
  });
}

/**
 * 修改菜单
 *
 * @param id
 * @param data
 */
export function updateMenu(id: string, data: MenuForm) {
  if (SYS_LOCAL) {
    return Promise.resolve({
      code: 200,
      message: "成功",
      data: null,
    } as any);
  }
  return request({
    url: "/menus/" + id,
    method: "put",
    data: data,
  });
}

/**
 * 删除菜单
 *
 * @param id 菜单ID
 */
export function deleteMenu(id: number) {
  if (SYS_LOCAL) {
    return Promise.resolve({
      code: 200,
      message: "success",
      data: null,
    } as any);
  }
  return request({
    url: "/menus/" + id,
    method: "delete",
  });
}
