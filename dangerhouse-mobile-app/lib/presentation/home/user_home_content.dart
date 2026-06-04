import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/auth_models.dart';
import '../../providers/auth_provider.dart';

class UserHomeContent extends ConsumerWidget {
  final VoidCallback onQuickDetection;
  final VoidCallback onOpenBuildings;
  final VoidCallback onOpenRecords;
  final VoidCallback onOpenProfile;

  const UserHomeContent({
    super.key,
    required this.onQuickDetection,
    required this.onOpenBuildings,
    required this.onOpenRecords,
    required this.onOpenProfile,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final displayName = _displayName(user);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHero(displayName),
              const SizedBox(height: 20),
              _buildPrimaryCard(),
              const SizedBox(height: 20),
              const Text(
                '常用功能',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 12),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.08,
                children: [
                  _ActionCard(
                    title: '快速检测',
                    subtitle: '立即选择房屋并开始检测',
                    icon: Icons.flash_on_rounded,
                    color: const Color(0xFFEF7D38),
                    onTap: onQuickDetection,
                  ),
                  _ActionCard(
                    title: '我的建筑',
                    subtitle: '查看和维护自己的房屋档案',
                    icon: Icons.home_work_rounded,
                    color: const Color(0xFF2F80ED),
                    onTap: onOpenBuildings,
                  ),
                  _ActionCard(
                    title: '我的记录',
                    subtitle: '查看自己的检测历史和结果',
                    icon: Icons.fact_check_outlined,
                    color: const Color(0xFF27AE60),
                    onTap: onOpenRecords,
                  ),
                  _ActionCard(
                    title: '我的信息',
                    subtitle: '查看账户信息与常用设置',
                    icon: Icons.person_outline_rounded,
                    color: const Color(0xFF6C63FF),
                    onTap: onOpenProfile,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHero(String displayName) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F4C81), Color(0xFF2F80ED)],
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text(
              '普通用户首页',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '你好，$displayName',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '这里保留最常用的几个功能，帮助你更快完成房屋查看、检测与个人信息管理。',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.86),
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, color: Color(0xFF2F80ED)),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              '你的房屋和检测记录会自动按当前账号过滤展示。',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF4B5563),
                height: 1.4,
              ),
            ),
          ),
        ],
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

class _ActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Ink(
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
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color),
              ),
              const Spacer(),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6B7280),
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
