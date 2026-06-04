import 'package:dangerhouse_app/presentation/home/archived_dangerous_buildings_page.dart';
import 'package:dangerhouse_app/presentation/profile/analysis_settings_page.dart';
import 'package:dangerhouse_app/presentation/profile/account_security_page.dart';
import 'package:dangerhouse_app/presentation/profile/help_page.dart';
import 'package:dangerhouse_app/presentation/profile/my_detection_archives_page.dart';
import 'package:dangerhouse_app/presentation/profile/notifications_page.dart';
import 'package:dangerhouse_app/presentation/profile/user_info_edit_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_info.dart';
import '../../core/utils/common_utils.dart';
import '../../data/models/auth_models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/monthly_stats_provider.dart';
import '../login/login_activity.dart';

class ProfileActivity extends ConsumerStatefulWidget {
  const ProfileActivity({super.key});

  @override
  ConsumerState<ProfileActivity> createState() => _ProfileActivityState();
}

class _ProfileActivityState extends ConsumerState<ProfileActivity> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authNotifierProvider.notifier).refreshUserInfo();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final user = authState.data;
    final dashboardAsync = ref.watch(dashboardProvider);
    final monthlyStatsAsync = ref.watch(monthlyStatsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(context, user),
            Transform.translate(
              offset: const Offset(0, -40),
              child: _buildStatsCard(dashboardAsync, monthlyStatsAsync),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 0),
              child: _buildMenuList(context, ref),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, LoginResponse? user) {
    final String displayName = user?.nickname?.isNotEmpty == true
        ? user!.nickname!
        : (user?.username ?? '未登录用户');
    final roleDisplay = _buildRoleDisplay(user);

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2F80ED), Color(0xFF1976D2)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -40,
            right: -40,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -30,
            left: -30,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 56, 20, 80),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      if (user != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => UserInfoEditPage(user: user),
                          ),
                        );
                      }
                    },
                    child: Stack(
                      children: [
                        Container(
                          width: 68,
                          height: 68,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: (user?.avatar != null && user!.avatar!.isNotEmpty)
                                ? Image.network(
                                    ImageUtils.getFullImageUrl(user.avatar!) ?? '',
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => _buildAvatarPlaceholder(displayName),
                                  )
                                : _buildAvatarPlaceholder(displayName),
                          ),
                        ),
                        Positioned(
                          right: -6,
                          bottom: -6,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(Icons.edit, size: 12, color: Color(0xFF2F80ED)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          roleDisplay,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.verified_user, size: 12, color: Colors.white),
                              const SizedBox(width: 6),
                              Text(
                                '实名认证 · 设备已授权',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarPlaceholder(String displayName) {
    return Container(
      color: Colors.blueGrey.shade100,
      child: Center(
        child: Text(
          displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
          style: const TextStyle(
            fontSize: 24,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCard(AsyncValue<dynamic> dashboardAsync, AsyncValue<MonthlyStats> monthlyStatsAsync) {
    final monthlyDetectionCount = monthlyStatsAsync.valueOrNull?.monthlyDetectionCount ?? 0;
    final monthlyHighRiskCount = monthlyStatsAsync.valueOrNull?.monthlyHighRiskCount ?? 0;
    final growthRate = monthlyStatsAsync.valueOrNull?.growthRate ?? 0.0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          children: [
            dashboardAsync.when(
              data: (dashboard) => Row(
                children: [
                  _buildStatItem(
                    '${dashboard.detectionCount ?? 0}',
                    '累计评估',
                    trend: '+$monthlyDetectionCount',
                  ),
                  _buildVerticalDivider(),
                  _buildStatItem(
                    '${dashboard.buildingCount ?? 0}',
                    '建筑档案',
                    trend: '+0',
                  ),
                  _buildVerticalDivider(),
                  _buildStatItem(
                    '${dashboard.highRiskCount ?? 0}',
                    '危险建筑',
                    trend: '+$monthlyHighRiskCount',
                    isDanger: true,
                  ),
                ],
              ),
              loading: () => const Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              error: (e, _) => Row(
                children: [
                  _buildStatItem('0', '累计评估', trend: '+0'),
                  _buildVerticalDivider(),
                  _buildStatItem('0', '建筑档案', trend: '+0'),
                  _buildVerticalDivider(),
                  _buildStatItem('0', '危险建筑', trend: '+0', isDanger: true),
                ],
              ),
            ),
            Builder(
              builder: (context) {
                final isPositive = growthRate >= 0;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  color: const Color(0xFFF5F7FA),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isPositive ? Icons.trending_up : Icons.trending_down,
                        size: 14,
                        color: isPositive ? const Color(0xFF27AE60) : const Color(0xFFEF4444),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        '本月较上月检测量增长 ',
                        style: TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
                      ),
                      Text(
                        '${isPositive ? '+' : ''}${growthRate.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isPositive ? const Color(0xFF27AE60) : const Color(0xFFEF4444),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String count, String label, {String trend = '', bool isDanger = false}) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            Text(
              count,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isDanger ? const Color(0xFFFF4D4F) : const Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 10, color: Color(0xFF9CA3AF)),
            ),
            const SizedBox(height: 4),
            Text(
              '$trend 本月',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: isDanger ? const Color(0xFFFF4D4F) : const Color(0xFF27AE60),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      height: 40,
      width: 1,
      color: const Color(0xFFF3F4F6),
    );
  }

  Widget _buildMenuList(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMenuSection(
            title: '数据与档案',
            items: [
              _buildMenuItem(
                icon: Icons.description_outlined,
                iconColor: const Color(0xFF2F80ED),
                iconBg: const Color(0xFF2F80ED).withValues(alpha: 0.09),
                title: '我的检测数据档案',
                subtitle: '查看全部历史检测记录',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MyDetectionArchivesPage(),
                    ),
                  );
                },
              ),
              _buildMenuItem(
                icon: Icons.bookmark_outline,
                iconColor: const Color(0xFFFF8C00),
                iconBg: const Color(0xFFFF8C00).withValues(alpha: 0.09),
                title: '已归档的危险建筑',
                subtitle: '已标记为危险的建筑清单',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ArchivedDangerousBuildingsPage(),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildMenuSection(
            title: '系统与配置',
            items: [
              _buildMenuItem(
                icon: Icons.shield_outlined,
                iconColor: const Color(0xFF0F766E),
                iconBg: const Color(0xFF0F766E).withValues(alpha: 0.09),
                title: '账户与安全',
                subtitle: '管理登录密码与账户安全设置',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AccountSecurityPage(),
                    ),
                  );
                },
              ),
              _buildMenuItem(
                icon: Icons.settings_outlined,
                iconColor: const Color(0xFF6B7280),
                iconBg: const Color(0xFF6B7280).withValues(alpha: 0.09),
                title: '分析模型及基础设置',
                subtitle: 'AI模型参数与同步配置',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AnalysisSettingsPage(),
                    ),
                  );
                },
              ),
              _buildMenuItem(
                icon: Icons.notifications_none,
                iconColor: const Color(0xFF27AE60),
                iconBg: const Color(0xFF27AE60).withValues(alpha: 0.09),
                title: '消息与通知',
                subtitle: '检测结果提醒及报告推送',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NotificationsPage(),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildMenuSection(
            title: '帮助与支持',
            items: [
              _buildMenuItem(
                icon: Icons.help_outline,
                iconColor: const Color(0xFF9B59B6),
                iconBg: const Color(0xFF9B59B6).withValues(alpha: 0.09),
                title: '使用帮助',
                subtitle: '操作指引与常见问题解答',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const HelpPage(),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildLogoutButton(context, ref),
          const SizedBox(height: 16),
          Center(
            child: Text(
              AppInfo.appDisplayVersion,
              style: const TextStyle(fontSize: 10, color: Color(0xFFD1D5DB)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSection({required String title, required List<Widget> items}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Color(0xFF9CA3AF),
              letterSpacing: 0.5,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Column(
              children: [
                for (int i = 0; i < items.length; i++) ...[
                  items[i],
                  if (i < items.length - 1)
                    const Divider(height: 1, color: Color(0xFFF9FAFB), indent: 56, endIndent: 16),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFFD1D5DB), size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: () async {
        await ref.read(authNotifierProvider.notifier).logout();
        if (context.mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginActivity()),
            (route) => false,
          );
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFFE4E6)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout_rounded, color: Color(0xFFFF4D4F), size: 16),
            SizedBox(width: 8),
            Text(
              '退出当前设备认证',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFFFF4D4F),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _buildRoleDisplay(LoginResponse? user) {
    final roleText = (user?.roles != null && user!.roles!.isNotEmpty)
        ? user.roles!.join(' / ')
        : '系统用户';
    return '$roleText · ${AppInfo.appName}';
  }
}
