import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/permission_util.dart';
import '../../providers/auth_provider.dart';
import '../capture/ai_detection_page.dart';
import '../capture/building_selection_page.dart';
import '../profile/profile_activity.dart';
import '../profile/user_profile_activity.dart';
import '../task/report_page.dart';
import 'building_list_page.dart';
import 'home_content.dart';
import 'home_providers.dart';
import 'user_home_content.dart';

class HomeActivity extends ConsumerWidget {
  const HomeActivity({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final isInspector = PermissionUtil.isInspector(currentUser);
    final selectedIndex = ref.watch(homeTabProvider);

    final pages = isInspector ? _inspectorPages() : _userPages(ref, context);
    final items = isInspector ? _inspectorItems() : _userItems();
    final safeIndex = selectedIndex >= pages.length ? 0 : selectedIndex;

    if (safeIndex != selectedIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(homeTabProvider.notifier).state = safeIndex;
      });
    }

    return Scaffold(
      body: IndexedStack(
        index: safeIndex,
        children: pages,
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        padding: EdgeInsets.zero,
        height: 72,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            for (final item in items)
              Expanded(
                child: _NavItem(
                  icon: item.icon,
                  label: item.label,
                  index: item.index,
                  currentIndex: safeIndex,
                  isCenter: item.isCenter,
                  onTap: () => ref.read(homeTabProvider.notifier).state = item.index,
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<Widget> _inspectorPages() {
    return [
      const HomeContent(),
      const BuildingListPage(),
      BuildingSelectionPage(onBuildingSelected: _onBuildingSelected),
      const ReportPage(),
      const ProfileActivity(),
    ];
  }

  List<Widget> _userPages(WidgetRef ref, BuildContext context) {
    return [
      UserHomeContent(
        onQuickDetection: () => _openBuildingSelection(context),
        onOpenBuildings: () => ref.read(homeTabProvider.notifier).state = 1,
        onOpenRecords: () => ref.read(homeTabProvider.notifier).state = 2,
        onOpenProfile: () => ref.read(homeTabProvider.notifier).state = 3,
      ),
      const BuildingListPage(),
      const ReportPage(),
      const UserProfileActivity(),
    ];
  }

  List<_NavItemConfig> _inspectorItems() {
    return const [
      _NavItemConfig(icon: Icons.home_filled, label: '首页', index: 0),
      _NavItemConfig(icon: Icons.domain, label: '建筑', index: 1),
      _NavItemConfig(icon: Icons.qr_code_scanner, label: '检测', index: 2, isCenter: true),
      _NavItemConfig(icon: Icons.assessment_outlined, label: '记录', index: 3),
      _NavItemConfig(icon: Icons.person_outline, label: '我的', index: 4),
    ];
  }

  List<_NavItemConfig> _userItems() {
    return const [
      _NavItemConfig(icon: Icons.home_filled, label: '首页', index: 0),
      _NavItemConfig(icon: Icons.domain, label: '建筑', index: 1),
      _NavItemConfig(icon: Icons.assignment_outlined, label: '记录', index: 2),
      _NavItemConfig(icon: Icons.person_outline, label: '我的', index: 3),
    ];
  }

  void _openBuildingSelection(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BuildingSelectionPage(onBuildingSelected: _onBuildingSelected),
      ),
    );
  }

  void _onBuildingSelected(BuildContext context, dynamic building) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AIDetectionPage(preSelectedBuilding: building),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int index;
  final int currentIndex;
  final bool isCenter;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.index,
    required this.currentIndex,
    required this.onTap,
    this.isCenter = false,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = currentIndex == index;
    const selectedColor = Color(0xFF2F80ED);
    const unselectedColor = Color(0xFF9CA3AF);
    final color = isSelected ? selectedColor : unselectedColor;

    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isCenter)
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: selectedColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: selectedColor.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            )
          else
            Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isCenter ? selectedColor : color,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItemConfig {
  final IconData icon;
  final String label;
  final int index;
  final bool isCenter;

  const _NavItemConfig({
    required this.icon,
    required this.label,
    required this.index,
    this.isCenter = false,
  });
}
