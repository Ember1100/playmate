import 'package:flutter/material.dart';
import '../../../../app/theme.dart';

/// 新人问卷页（登录后 is_new_user=true 时跳转）
class QuestionnaireScreen extends StatelessWidget {
  const QuestionnaireScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('完善信息'),
        automaticallyImplyLeading: false, // 禁止返回，必须完成问卷
      ),
      body: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.assignment_outlined, size: 64, color: AppColors.primary),
            SizedBox(height: 20),
            Text('欢迎加入玩伴！',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('请花 30 秒完成新人问卷，帮我们为你推荐最合适的搭子',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                textAlign: TextAlign.center),
            SizedBox(height: 40),
            Text('问卷功能开发中...', style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}
