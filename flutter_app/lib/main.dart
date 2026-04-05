import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/providers/auth_provider.dart';

void main() {
  runApp(const ProviderScope(child: PlaymateApp()));
}

class PlaymateApp extends ConsumerWidget {
  const PlaymateApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final startup = ref.watch(appStartupProvider);

    // 启动初始化中：显示 Splash
    if (startup.isLoading) {
      return MaterialApp(
        theme: AppTheme.light,
        debugShowCheckedModeBanner: false,
        home: const Scaffold(
          backgroundColor: AppColors.surface,
          body: Center(
            child: CircleAvatar(
              radius: 36,
              backgroundColor: AppColors.primary,
              child: Icon(Icons.people_alt_rounded,
                  color: Colors.white, size: 36),
            ),
          ),
        ),
      );
    }

    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: '玩伴',
      theme: AppTheme.light,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
