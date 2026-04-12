import 'package:flutter/material.dart';

/// 二级页面手势返回组件。
/// 向右滑动速度 > 300px/s 且有页面可返回时触发 pop，
/// 拖动过程中页面完全静止。
class PmSwipeBack extends StatelessWidget {
  const PmSwipeBack({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity != null &&
            details.primaryVelocity! > 300 &&
            Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      },
      child: child,
    );
  }
}
