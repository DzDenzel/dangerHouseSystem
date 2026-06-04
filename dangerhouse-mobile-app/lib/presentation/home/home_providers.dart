import 'package:flutter_riverpod/flutter_riverpod.dart';

// 管理首页 BottomNavigationBar 的选中索引
final homeTabProvider = StateProvider<int>((ref) => 0);
