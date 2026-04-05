import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme.dart';

/// 集市 Tab 首页（4个子模块入口）
class MarketScreen extends StatelessWidget {
  const MarketScreen({super.key});

  static const _modules = [
    _Module(
      icon:        Icons.find_in_page_outlined,
      activeIcon:  Icons.find_in_page_rounded,
      label:       '失物招领',
      description: '发布/寻找丢失物品',
      color:       Color(0xFFFF7A00),
      path:        '/market/lost-found',
    ),
    _Module(
      icon:        Icons.sell_outlined,
      activeIcon:  Icons.sell_rounded,
      label:       '二手闲置',
      description: '出售/购买闲置好物',
      color:       Color(0xFF5DCAA5),
      path:        '/market/second-hand',
    ),
    _Module(
      icon:        Icons.work_outline_rounded,
      activeIcon:  Icons.work_rounded,
      label:       '兼职啦',
      description: '发布/寻找兼职机会',
      color:       Color(0xFF5B8EF4),
      path:        '/market/part-time',
    ),
    _Module(
      icon:        Icons.swap_horiz_rounded,
      activeIcon:  Icons.swap_horiz_rounded,
      label:       '以物换物',
      description: '用闲置换你所需',
      color:       Color(0xFFE24B4A),
      path:        '/market/barter',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('集市'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_outline_rounded),
            onPressed: () => context.push('/profile/collects'),
            tooltip: '我的收藏',
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 模块入口 Grid
          Padding(
            padding: const EdgeInsets.all(16),
            child: GridView.count(
              shrinkWrap: true,
              physics:     const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing:  12,
              childAspectRatio: 1.6,
              children: _modules.map((m) => _ModuleCard(module: m)).toList(),
            ),
          ),
          // 最新发布占位
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('最新发布',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
                TextButton(
                  onPressed: () {},
                  child: const Text('查看全部',
                      style: TextStyle(color: AppColors.primary, fontSize: 13)),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: 6,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (_, _) => const _MarketItemPlaceholder(),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModuleCard extends StatelessWidget {
  const _ModuleCard({required this.module});
  final _Module module;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.card),
      onTap:        () => context.push(module.path),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color:        AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border:       Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color:        module.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(module.activeIcon, color: module.color, size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(module.label,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(module.description,
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MarketItemPlaceholder extends StatelessWidget {
  const _MarketItemPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:        AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border:       Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              color:        AppColors.primaryLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.image_outlined, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('标题加载中...', style: TextStyle(fontWeight: FontWeight.w500)),
                SizedBox(height: 4),
                Text('描述信息', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                SizedBox(height: 6),
                Text('¥ --', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Module {
  const _Module({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.description,
    required this.color,
    required this.path,
  });

  final IconData icon;
  final IconData activeIcon;
  final String   label;
  final String   description;
  final Color    color;
  final String   path;
}
