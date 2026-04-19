import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../features/im/providers/im_provider.dart';

/// 底部导航 Shell（固定高度 98px + 安全区域）
///
/// Tab 顺序（来自 UI 设计稿）：
///   0 圈子 | 1 集市 | 2 搭子 | 3 消息 | 4 趣玩 | 5 我的
class PmBottomNav extends ConsumerWidget {
  const PmBottomNav({super.key, required this.shell});

  final StatefulNavigationShell shell;

  static const _tabs = [
    _TabItem(icon: Icons.forum_outlined,          activeIcon: Icons.forum_rounded,          label: '圈子'),
    _TabItem(icon: Icons.storefront_outlined,     activeIcon: Icons.storefront_rounded,     label: '集市'),
    _TabItem(icon: Icons.people_alt_outlined,     activeIcon: Icons.people_alt_rounded,     label: '搭子'),
    _TabItem(icon: Icons.chat_bubble_outline,     activeIcon: Icons.chat_bubble_rounded,    label: '消息'),
    _TabItem(icon: Icons.celebration_outlined,    activeIcon: Icons.celebration_rounded,    label: '趣玩'),
    _TabItem(icon: Icons.person_outline_rounded,  activeIcon: Icons.person_rounded,         label: '我的'),
  ];

  void _onTap(int index) {
    shell.goBranch(index, initialLocation: index == shell.currentIndex);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 全局 WS 连接 + 消息分发（登录后立即建立，无需先进入消息 Tab）
    ref.watch(wsHandlerProvider);
    final unreadCount = ref.watch(totalUnreadCountProvider);

    return Scaffold(
      body: shell,
      bottomNavigationBar: _buildNavBar(context, unreadCount),
    );
  }

  Widget _buildNavBar(BuildContext context, int unreadCount) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return Container(
      height: 98 + bottomPadding,
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(
          top: BorderSide(color: AppColors.border, width: 1.0),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomPadding),
        child: Row(
          children: List.generate(
            _tabs.length,
            (i) => Expanded(child: _buildItem(i, unreadCount)),
          ),
        ),
      ),
    );
  }

  Widget _buildItem(int index, int unreadCount) {
    final selected  = index == shell.currentIndex;
    final tab       = _tabs[index];
    final color     = selected ? AppColors.primary : AppColors.textSecondary;
    // 只在消息 tab（index 3）显示角标
    final showBadge = index == 3 && unreadCount > 0;

    return InkWell(
      onTap:       () => _onTap(index),
      splashColor: AppColors.primaryLight,
      child: SizedBox(
        height: 98,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(selected ? tab.activeIcon : tab.icon, color: color, size: 26),
                if (showBadge)
                  Positioned(
                    top:   -4,
                    right: -6,
                    child: Container(
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        unreadCount > 99 ? '99+' : '$unreadCount',
                        style: const TextStyle(
                          color:      Colors.white,
                          fontSize:   9,
                          fontWeight: FontWeight.bold,
                          height:     1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              tab.label,
              style: TextStyle(
                fontSize:   11.5,
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
