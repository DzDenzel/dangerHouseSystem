import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/building_models.dart';
import '../../data/models/detection_models.dart';
import '../../data/models/auth_models.dart';
import '../../domain/entities/task.dart';
import '../../presentation/login/login_activity.dart';
import '../../presentation/login/register_activity.dart';
import '../../presentation/home/home_activity.dart';
import '../../presentation/home/building_details_page.dart';
import '../../presentation/home/building_list_page.dart';
import '../../presentation/home/archived_dangerous_buildings_page.dart';
import '../../presentation/capture/building_create_page.dart';
import '../../presentation/capture/building_edit_page.dart';
import '../../presentation/capture/building_selection_page.dart';
import '../../presentation/capture/capture_activity.dart';
import '../../presentation/capture/ai_detection_page.dart';
import '../../presentation/result/result_activity.dart';
import '../../presentation/profile/profile_activity.dart';
import '../../presentation/profile/user_info_edit_page.dart';
import '../../presentation/profile/notifications_page.dart';
import '../../presentation/profile/help_page.dart';
import '../../presentation/profile/analysis_settings_page.dart';
import '../../presentation/profile/my_detection_archives_page.dart';
import '../../presentation/task/report_page.dart';
import '../../presentation/task/report_detail_page.dart';
import '../../core/auth/token_manager.dart';
import '../../main.dart';
import 'app_routes.dart';

/// 全局路由配置
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: AppRoutes.login,
    debugLogDiagnostics: true,
    routes: [
      GoRoute(
        path: AppRoutes.login,
        name: RouteNames.login,
        builder: (context, state) => const LoginActivity(),
      ),
      GoRoute(
        path: AppRoutes.register,
        name: RouteNames.register,
        builder: (context, state) => const RegisterActivity(),
      ),
      ShellRoute(
        builder: (context, state, child) => child,
        routes: [
          GoRoute(
            path: AppRoutes.home,
            name: RouteNames.home,
            builder: (context, state) => const HomeActivity(),
          ),
          GoRoute(
            path: '${AppRoutes.buildingDetailPath}/:id',
            name: RouteNames.buildingDetail,
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>?;
              final building = extra?['building'] as Building?;
              final id = int.tryParse(state.pathParameters['id'] ?? '0') ?? 0;
              if (building != null) {
                return BuildingDetailsPage(building: building);
              }
              return BuildingDetailsPage(
                building: Building(
                  id: id,
                  name: '',
                  address: '',
                  structureType: 'OTHER',
                ),
              );
            },
          ),
          GoRoute(
            path: AppRoutes.buildingList,
            name: RouteNames.buildingList,
            builder: (context, state) => const BuildingListPage(),
          ),
          GoRoute(
            path: AppRoutes.archivedBuildings,
            name: RouteNames.archivedBuildings,
            builder: (context, state) => const ArchivedDangerousBuildingsPage(),
          ),
          GoRoute(
            path: AppRoutes.buildingCreate,
            name: RouteNames.buildingCreate,
            builder: (context, state) => const BuildingCreatePage(),
          ),
          GoRoute(
            path: '${AppRoutes.buildingEditPath}/:id',
            name: RouteNames.buildingEdit,
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>?;
              final building = extra?['building'] as Building?;
              final id = int.tryParse(state.pathParameters['id'] ?? '0') ?? 0;
              if (building != null) {
                return BuildingEditPage(building: building);
              }
              return BuildingEditPage(
                building: Building(
                  id: id,
                  name: '',
                  address: '',
                  structureType: 'OTHER',
                ),
              );
            },
          ),
          GoRoute(
            path: AppRoutes.capture,
            name: RouteNames.capture,
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>?;
              final task = extra?['task'] as Task?;
              return CaptureActivity(task: task);
            },
          ),
          GoRoute(
            path: AppRoutes.buildingSelection,
            name: RouteNames.buildingSelection,
            builder: (context, state) => const BuildingSelectionPage(),
          ),
          GoRoute(
            path: AppRoutes.aiDetection,
            name: RouteNames.aiDetection,
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>?;
              final building = extra?['building'] as Building?;
              return AIDetectionPage(preSelectedBuilding: building);
            },
          ),
          GoRoute(
            path: AppRoutes.result,
            name: RouteNames.result,
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>?;
              return ResultActivity(
                result: extra?['result'] as DetectionResultDto?,
                imageFile: extra?['imageFile'],
                detectionId: extra?['detectionId'] as int?,
              );
            },
          ),
          GoRoute(
            path: '${AppRoutes.resultDetailPath}/:id',
            name: RouteNames.resultDetail,
            builder: (context, state) {
              final id = int.tryParse(state.pathParameters['id'] ?? '0') ?? 0;
              return ResultActivity(detectionId: id);
            },
          ),
          GoRoute(
            path: AppRoutes.profile,
            name: RouteNames.profile,
            builder: (context, state) => const ProfileActivity(),
          ),
          GoRoute(
            path: AppRoutes.profileEdit,
            name: RouteNames.profileEdit,
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>?;
              final user = extra?['user'] as LoginResponse?;
              if (user != null) {
                return UserInfoEditPage(user: user);
              }
              return UserInfoEditPage(
                user: LoginResponse(
                  id: 0,
                  username: '',
                  success: true,
                ),
              );
            },
          ),
          GoRoute(
            path: AppRoutes.notifications,
            name: RouteNames.notifications,
            builder: (context, state) => const NotificationsPage(),
          ),
          GoRoute(
            path: AppRoutes.help,
            name: RouteNames.help,
            builder: (context, state) => const HelpPage(),
          ),
          GoRoute(
            path: AppRoutes.analysisSettings,
            name: RouteNames.analysisSettings,
            builder: (context, state) => const AnalysisSettingsPage(),
          ),
          GoRoute(
            path: AppRoutes.myArchives,
            name: RouteNames.myArchives,
            builder: (context, state) => const MyDetectionArchivesPage(),
          ),
          GoRoute(
            path: AppRoutes.report,
            name: RouteNames.report,
            builder: (context, state) => const ReportPage(),
          ),
          GoRoute(
            path: '${AppRoutes.reportDetailPath}/:id',
            name: RouteNames.reportDetail,
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>?;
              final task = extra?['task'] as Task?;
              final id = int.tryParse(state.pathParameters['id'] ?? '0') ?? 0;
              return ReportDetailPage(task: task, detectionId: id);
            },
          ),
        ],
      ),
    ],
    redirect: (context, state) async {
      final isLoggedIn = await TokenManager.instance.hasToken();
      final isAuthRoute = state.matchedLocation == AppRoutes.login ||
          state.matchedLocation == AppRoutes.register;

      if (!isLoggedIn && !isAuthRoute) {
        return AppRoutes.login;
      }

      if (isLoggedIn && isAuthRoute) {
        return AppRoutes.home;
      }

      return null;
    },
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('页面未找到')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              '页面未找到: ${state.matchedLocation}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.home),
              child: const Text('返回首页'),
            ),
          ],
        ),
      ),
    ),
  );
});
