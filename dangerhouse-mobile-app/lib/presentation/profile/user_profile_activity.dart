import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_info.dart';
import '../../core/utils/common_utils.dart';
import '../../data/models/auth_models.dart';
import '../../providers/auth_provider.dart';
import '../login/login_activity.dart';
import 'account_security_page.dart';
import 'help_page.dart';
import 'notifications_page.dart';
import 'user_info_edit_page.dart';

class UserProfileActivity extends ConsumerWidget {
  const UserProfileActivity({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            _buildHeader(user),
            const SizedBox(height: 20),
            _buildAccountCard(context, user),
            const SizedBox(height: 16),
            _buildMenuCard(
              title: '常用服务',
              children: [
                _MenuTile(
                  icon: Icons.notifications_none,
                  title: '消息通知',
                  subtitle: '查看系统提醒和结果通知',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const NotificationsPage()),
                    );
                  },
                ),
                _MenuTile(
                  icon: Icons.help_outline,
                  title: '使用帮助',
                  subtitle: '查看使用说明和常见问题',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const HelpPage()),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildLogoutButton(context, ref),
            const SizedBox(height: 16),
            Center(
              child: Text(
                AppInfo.appDisplayVersion,
                style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(LoginResponse? user) {
    final displayName = _displayName(user);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2D3142), Color(0xFF4F5D75)],
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.white.withValues(alpha: 0.14),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: (user?.avatar != null && user!.avatar!.isNotEmpty)
                  ? Image.network(
                      ImageUtils.getFullImageUrl(user.avatar!) ?? '',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _avatarFallback(displayName),
                    )
                  : _avatarFallback(displayName),
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
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '普通用户 · ${AppInfo.appName}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountCard(BuildContext context, LoginResponse? user) {
    return _buildMenuCard(
      title: '账户信息',
      children: [
        _MenuTile(
          icon: Icons.shield_outlined,
          title: '账户与安全',
          subtitle: '管理登录密码与账户安全设置',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AccountSecurityPage()),
            );
          },
        ),
        _MenuTile(
          icon: Icons.person_outline,
          title: '我的资料',
          subtitle: '查看并编辑昵称、手机号、邮箱和头像',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => UserInfoEditPage(
                  user: user ??
                      LoginResponse(
                        success: true,
                        id: 0,
                        username: '',
                      ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildMenuCard({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context, WidgetRef ref) {
    return ElevatedButton(
      onPressed: () async {
        await ref.read(authNotifierProvider.notifier).logout();
        if (context.mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginActivity()),
            (route) => false,
          );
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFEF4444),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: const Text(
        '退出当前账户',
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _avatarFallback(String displayName) {
    return Container(
      color: Colors.white.withValues(alpha: 0.18),
      alignment: Alignment.center,
      child: Text(
        displayName.isNotEmpty ? displayName.substring(0, 1).toUpperCase() : 'U',
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  String _displayName(LoginResponse? user) {
    final nickname = user?.nickname?.trim();
    if (nickname != null && nickname.isNotEmpty) return nickname;
    final username = user?.username?.trim();
    if (username != null && username.isNotEmpty) return username;
    return '用户';
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFEEF4FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: const Color(0xFF2F80ED), size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFFD1D5DB)),
          ],
        ),
      ),
    );
  }
}
