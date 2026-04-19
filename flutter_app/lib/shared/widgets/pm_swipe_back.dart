import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// 二级页面手势返回组件。
/// 向右滑动速度 > 300px/s 且有页面可返回时触发 pop，
/// 拖动过程中页面完全静止。
///
/// 使用 go_router 的 context.canPop() / context.pop() 以兼容
/// StatefulShellRoute，避免绕过 go_router 导航栈直接操作原生 Navigator。
class PmSwipeBack extends StatelessWidget {
  const PmSwipeBack({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity != null &&
            details.primaryVelocity! > 300 &&
            context.canPop()) {
          context.pop();
        }
      },
      child: child,
    );
  }
}
