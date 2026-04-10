import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'router.dart';
import 'theme.dart';
import '../features/auth/providers/auth_provider.dart';

class PlaymateApp extends ConsumerWidget {
  const PlaymateApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final startup = ref.watch(appStartupProvider);

    // 启动初始化中：显示 Splash
    if (startup.isLoading) {
      return MaterialApp(
        theme:                    AppTheme.light,
        debugShowCheckedModeBanner: false,
        home: const Scaffold(
          backgroundColor: AppColors.background,
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius:          40,
                  backgroundColor: AppColors.primary,
                  child:           Icon(Icons.people_alt_rounded,
                                       color: Colors.white, size: 40),
                ),
                SizedBox(height: 16),
                Text('搭伴',
                    style: TextStyle(
                        fontSize:   24,
                        fontWeight: FontWeight.bold,
                        color:      AppColors.primary)),
              ],
            ),
          ),
        ),
      );
    }

    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title:                    '搭伴',
      theme:                    AppTheme.light,
      routerConfig:             router,
      debugShowCheckedModeBanner: false,
    );
  }
}
