import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';

/// 底部导航 Shell（固定高度 98px + 安全区域）
///
/// Tab 顺序（来自设计规范）：
///   0 搭子 | 1 趣玩 | 2 圈子 | 3 集市 | 4 我的
class PmBottomNav extends StatelessWidget {
  const PmBottomNav({super.key, required this.shell});

  final StatefulNavigationShell shell;

  static const _tabs = [
    _TabItem(icon: Icons.people_alt_outlined,   activeIcon: Icons.people_alt_rounded,    label: '搭子'),
    _TabItem(icon: Icons.celebration_outlined,  activeIcon: Icons.celebration_rounded,   label: '趣玩'),
    _TabItem(icon: Icons.forum_outlined,        activeIcon: Icons.forum_rounded,         label: '圈子'),
    _TabItem(icon: Icons.storefront_outlined,   activeIcon: Icons.storefront_rounded,    label: '集市'),
    _TabItem(icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded,       label: '我的'),
  ];

  void _onTap(int index) {
    shell.goBranch(index, initialLocation: index == shell.currentIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: shell,
      bottomNavigationBar: _buildNavBar(context),
    );
  }

  Widget _buildNavBar(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return Container(
      height: 98 + bottomPadding,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.border, width: 0.5),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomPadding),
        child: Row(
          children: List.generate(
            _tabs.length,
            (i) => Expanded(child: _buildItem(i)),
          ),
        ),
      ),
    );
  }

  Widget _buildItem(int index) {
    final selected = index == shell.currentIndex;
    final tab      = _tabs[index];
    final color    = selected ? AppColors.primary : AppColors.textSecondary;

    return InkWell(
      onTap:      () => _onTap(index),
      splashColor: AppColors.primaryLight,
      child: SizedBox(
        height: 98,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(selected ? tab.activeIcon : tab.icon, color: color, size: 26),
            const SizedBox(height: 4),
            Text(
              tab.label,
              style: TextStyle(
                fontSize:   11,
                color:      color,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabItem {
  const _TabItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });

  final IconData icon;
  final IconData activeIcon;
  final String   label;
}
