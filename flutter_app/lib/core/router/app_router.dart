import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/discover/presentation/screens/discover_screen.dart';
import '../../features/feed/presentation/screens/feed_screen.dart';
import '../../features/im/presentation/screens/chat_screen.dart';
import '../../features/im/presentation/screens/im_screen.dart';
import '../../features/profile/presentation/screens/edit_profile_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../shared/widgets/main_shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final isLoggedIn = ref.watch(isLoggedInProvider);

  return GoRouter(
    initialLocation: '/discover',
    redirect: (context, state) {
      final loggedIn = isLoggedIn.valueOrNull ?? false;
      final isAuthRoute = state.matchedLocation.startsWith('/login') ||
          state.matchedLocation.startsWith('/register');

      if (!loggedIn && !isAuthRoute) return '/login';
      if (loggedIn && isAuthRoute) return '/discover';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => MainShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/discover',
              builder: (context, state) => const DiscoverScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/im',
              builder: (context, state) => const ImScreen(),
              routes: [
                GoRoute(
                  path: ':conversationId',
                  builder: (context, state) {
                    final extra = state.extra as Map<String, dynamic>?;
                    return ChatScreen(
                      conversationId:
                          state.pathParameters['conversationId']!,
                      otherUsername:
                          extra?['username'] as String? ?? '聊天',
                    );
                  },
                ),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/feed',
              builder: (context, state) => const FeedScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/profile',
              builder: (context, state) => const ProfileScreen(),
              routes: [
                GoRoute(
                  path: 'edit',
                  builder: (context, state) => const EditProfileScreen(),
                ),
              ],
            ),
          ]),
        ],
      ),
    ],
  );
});
