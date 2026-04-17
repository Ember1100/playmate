import 'package:flutter/material.dart';

/// 仅做淡入淡出，不跟手，不支持手势拖拽返回。
/// 配合各页面内的 [GestureDetector] 实现"松手才返回"效果。
class _FadePageTransitionsBuilder extends PageTransitionsBuilder {
  const _FadePageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: Curves.easeIn),
      child: child,
    );
  }
}

/// 全局颜色常量（来自设计规范）
class AppColors {
  AppColors._();

  // 主色
  static const primary       = Color(0xFFFF7A00); // 主橙
  static const primaryLight  = Color(0xFFFFE0C0); // 浅橙

  // 辅色
  static const secondary     = Color(0xFF5DCAA5); // 绿
  static const accent        = Color(0xFFE24B4A); // 红/强调

  // 文字
  static const textPrimary   = Color(0xFF222222);
  static const textSecondary = Color(0xFF999999);
  static const textMedium    = Color(0xFF666666);

  // 背景
  static const background    = Color(0xFFFFF8EC); // 极浅暖橙（页面底色）
  static const surface       = Color(0xFFFFFFFF);
  static const warmBg        = Color(0xFFFFE8C0); // 我的页面背景

  // 分割线 / 边框
  static const border        = Color(0xFFFFDDB8); // 暖橙边框

  // 功能色
  static const error         = Color(0xFFE24B4A);
  static const onlineGreen   = Color(0xFF4CAF50);
}

/// 圆角尺寸规范
class AppRadius {
  AppRadius._();

  static const card   = 12.0;
  static const button = 8.0;
  static const tag    = 20.0; // 标签胶囊
}

class AppTheme {
  AppTheme._();

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary:   AppColors.primary,
          secondary: AppColors.secondary,
          surface:   AppColors.surface,
          error:     AppColors.error,
        ),
        scaffoldBackgroundColor: AppColors.background,

        // 全平台用淡入淡出转场，去掉 iOS CupertinoPage 跟手拖拽行为
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: _FadePageTransitionsBuilder(),
            TargetPlatform.iOS:     _FadePageTransitionsBuilder(),
          },
        ),

        // AppBar
        appBarTheme: const AppBarTheme(
          backgroundColor:  AppColors.surface,
          foregroundColor:  AppColors.textPrimary,
          surfaceTintColor: Colors.transparent,
          elevation:        0,
          centerTitle:      true,
          titleTextStyle: TextStyle(
            color:      AppColors.textPrimary,
            fontSize:   17,
            fontWeight: FontWeight.w600,
          ),
        ),

        // 输入框
        inputDecorationTheme: InputDecorationTheme(
          filled:          true,
          fillColor:       AppColors.background,
          contentPadding:  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
            borderSide:   BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
            borderSide:   BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
            borderSide:   const BorderSide(color: AppColors.primary, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
            borderSide:   const BorderSide(color: AppColors.error, width: 1),
          ),
        ),

        // 主按钮
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            minimumSize:     const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.button),
            ),
            elevation: 0,
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),

        // 文字按钮
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: AppColors.primary),
        ),

        // 卡片
        cardTheme: CardThemeData(
          color:     AppColors.surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.card),
            side:         const BorderSide(color: AppColors.border),
          ),
        ),

        // Divider
        dividerTheme: const DividerThemeData(
          color:     AppColors.border,
          thickness: 0.5,
          space:     0,
        ),
      );
}
