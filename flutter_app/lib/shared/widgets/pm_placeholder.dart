import 'package:flutter/material.dart';
import '../../app/theme.dart';

/// 通用占位页面（开发中）
class PmPlaceholderScreen extends StatelessWidget {
  const PmPlaceholderScreen({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.construction_rounded, size: 56, color: AppColors.primary),
            const SizedBox(height: 16),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            const Text('即将上线，敬请期待',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
