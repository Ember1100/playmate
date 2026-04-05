import 'package:flutter/material.dart';
import '../../../../app/theme.dart';

/// 趣玩 Tab（MVP 静态展示）
class FunScreen extends StatelessWidget {
  const FunScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('趣玩')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 分类标签
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['全部', '线下活动', '线上互动', '技能学习', '娱乐休闲']
                  .map((label) => _CategoryChip(label: label, selected: label == '全部'))
                  .toList(),
            ),
          ),
          const SizedBox(height: 16),
          // 活动卡片占位
          ...List.generate(6, (i) => const _ActivityCardPlaceholder()),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.label, this.selected = false});
  final String label;
  final bool   selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color:        selected ? AppColors.primary : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.tag),
        border: Border.all(
          color: selected ? AppColors.primary : AppColors.border,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color:      selected ? Colors.white : AppColors.textSecondary,
          fontSize:   13,
          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }
}

class _ActivityCardPlaceholder extends StatelessWidget {
  const _ActivityCardPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color:        AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border:       Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 封面占位
          Container(
            height: 160,
            decoration: BoxDecoration(
              color:        AppColors.primaryLight,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppRadius.card),
              ),
            ),
            child: const Center(
              child: Icon(Icons.image_outlined, size: 48, color: AppColors.primary),
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('活动标题加载中...', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: 14, color: AppColors.textSecondary),
                    SizedBox(width: 2),
                    Text('地点', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    SizedBox(width: 12),
                    Icon(Icons.access_time_rounded, size: 14, color: AppColors.textSecondary),
                    SizedBox(width: 2),
                    Text('时间', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
