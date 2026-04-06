import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/register_screen.dart';
import '../features/auth/presentation/screens/questionnaire_screen.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/buddy/presentation/screens/buddy_screen.dart';
import '../features/circle/presentation/screens/circle_screen.dart';
import '../features/fun/presentation/screens/fun_screen.dart';
import '../features/im/presentation/screens/chat_screen.dart';
import '../features/market/presentation/screens/market_screen.dart';
import '../features/profile/presentation/screens/profile_screen.dart';
import '../shared/widgets/pm_bottom_nav.dart';
import '../shared/widgets/pm_placeholder.dart';

// ── 路由刷新通知器（响应登录/登出状态变化）─────────────────────────────────────

class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier(this._ref) {
    _ref.listen<AsyncValue<bool>>(isLoggedInProvider, (_, _) => notifyListeners());
    _ref.listen(currentUserProvider, (_, _) => notifyListeners());
  }

  final Ref _ref;

  String? redirect(BuildContext context, GoRouterState state) {
    final loggedIn   = _ref.read(isLoggedInProvider).valueOrNull ?? false;
    final currentUser = _ref.read(currentUserProvider);
    final location   = state.matchedLocation;

    final onAuthRoute = location.startsWith('/auth/');

    // 未登录 → 强制到登录页
    if (!loggedIn) {
      return onAuthRoute ? null : '/auth/login';
    }

    // 已登录 + 访问登录/注册/已完成问卷 → 回首页
    if (loggedIn && (location == '/auth/login' || location == '/auth/register')) {
      return '/buddy';
    }

    // 已登录 + 未完成问卷 → 问卷页
    if (currentUser?.isNewUser == true && location != '/auth/questionnaire') {
      return '/auth/questionnaire';
    }

    // 已登录 + 已完成问卷 + 还在问卷页 → 跳回首页
    if (loggedIn && currentUser?.isNewUser == false && location == '/auth/questionnaire') {
      return '/buddy';
    }

    return null;
  }
}

// ── Router Provider ───────────────────────────────────────────────────────────

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterNotifier(ref);
  ref.onDispose(notifier.dispose);

  return GoRouter(
    initialLocation:    '/buddy',
    refreshListenable:  notifier,
    redirect:           notifier.redirect,
    routes: [
      // ── 认证页（Shell 之外）───────────────────────────────────────────────
      GoRoute(
        path:    '/auth/login',
        builder: (_, _) => const LoginScreen(),
      ),
      GoRoute(
        path:    '/auth/register',
        builder: (_, _) => const RegisterScreen(),
      ),
      GoRoute(
        path:    '/auth/questionnaire',
        builder: (_, _) => const QuestionnaireScreen(),
      ),

      // ── 私信聊天（Shell 之外，全屏）────────────────────────────────────────
      GoRoute(
        path: '/im/chat/:conversationId',
        builder: (_, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return ChatScreen(
            conversationId: state.pathParameters['conversationId']!,
            otherUsername:  extra?['username'] as String? ?? '聊天',
            otherAvatarUrl: extra?['otherAvatarUrl'] as String?,
          );
        },
      ),

      // ── 主 Shell（5 个 Tab）──────────────────────────────────────────────
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => PmBottomNav(shell: shell),
        branches: [
          // Tab 0：圈子
          StatefulShellBranch(routes: [
            GoRoute(
              path:    '/circle',
              builder: (_, _) => const CircleScreen(),
              routes: [
                GoRoute(
                  path: 'topic/:id',
                  builder: (_, s) => PmPlaceholderScreen(title: '话题 ${s.pathParameters['id']}'),
                ),
                GoRoute(
                  path: 'poll/:id',
                  builder: (_, s) => PmPlaceholderScreen(title: '投票 ${s.pathParameters['id']}'),
                ),
                GoRoute(
                  path:    'groups',
                  builder: (_, _) => const PmPlaceholderScreen(title: '社群列表'),
                  routes: [
                    GoRoute(
                      path:    ':id',
                      builder: (_, s) => PmPlaceholderScreen(title: '社群 ${s.pathParameters['id']}'),
                    ),
                  ],
                ),
              ],
            ),
          ]),

          // Tab 1：集市
          StatefulShellBranch(routes: [
            GoRoute(
              path:    '/market',
              builder: (_, _) => const MarketScreen(),
              routes: [
                GoRoute(
                  path:    'lost-found',
                  builder: (_, _) => const PmPlaceholderScreen(title: '失物招领'),
                  routes: [
                    GoRoute(path: 'publish', builder: (_, _) => const PmPlaceholderScreen(title: '发布失物招领')),
                    GoRoute(path: ':id',     builder: (_, s) => PmPlaceholderScreen(title: '失物详情 ${s.pathParameters['id']}')),
                  ],
                ),
                GoRoute(
                  path:    'second-hand',
                  builder: (_, _) => const PmPlaceholderScreen(title: '二手闲置'),
                  routes: [
                    GoRoute(path: 'publish', builder: (_, _) => const PmPlaceholderScreen(title: '发布二手')),
                    GoRoute(path: ':id',     builder: (_, s) => PmPlaceholderScreen(title: '二手详情 ${s.pathParameters['id']}')),
                  ],
                ),
                GoRoute(
                  path:    'part-time',
                  builder: (_, _) => const PmPlaceholderScreen(title: '兼职啦'),
                  routes: [
                    GoRoute(path: 'publish', builder: (_, _) => const PmPlaceholderScreen(title: '发布兼职')),
                    GoRoute(path: ':id',     builder: (_, s) => PmPlaceholderScreen(title: '兼职详情 ${s.pathParameters['id']}')),
                  ],
                ),
                GoRoute(
                  path:    'barter',
                  builder: (_, _) => const PmPlaceholderScreen(title: '以物换物'),
                  routes: [
                    GoRoute(path: 'publish', builder: (_, _) => const PmPlaceholderScreen(title: '发布换物')),
                    GoRoute(path: ':id',     builder: (_, s) => PmPlaceholderScreen(title: '换物详情 ${s.pathParameters['id']}')),
                  ],
                ),
              ],
            ),
          ]),

          // Tab 2：搭子
          StatefulShellBranch(routes: [
            GoRoute(
              path:    '/buddy',
              builder: (_, _) => const BuddyScreen(),
              routes: [
                GoRoute(path: 'candidates',  builder: (_, _) => const PmPlaceholderScreen(title: '搭子推荐')),
                GoRoute(path: 'invitations', builder: (_, _) => const PmPlaceholderScreen(title: '邀约管理')),
                GoRoute(path: 'career',      builder: (_, _) => const PmPlaceholderScreen(title: '职业搭子阵地')),
              ],
            ),
          ]),

          // Tab 3：趣玩
          StatefulShellBranch(routes: [
            GoRoute(
              path:    '/fun',
              builder: (_, _) => const FunScreen(),
            ),
          ]),

          // Tab 4：我的
          StatefulShellBranch(routes: [
            GoRoute(
              path:    '/profile',
              builder: (_, _) => const ProfileScreen(),
              routes: [
                GoRoute(path: 'notifications', builder: (_, _) => const PmPlaceholderScreen(title: '消息中心')),
                GoRoute(path: 'collects',      builder: (_, _) => const PmPlaceholderScreen(title: '我的收藏')),
                GoRoute(path: 'member',        builder: (_, _) => const PmPlaceholderScreen(title: '会员中心')),
                GoRoute(path: 'growth-report', builder: (_, _) => const PmPlaceholderScreen(title: '成长报告')),
                GoRoute(path: 'feedback',      builder: (_, _) => const PmPlaceholderScreen(title: '需求反馈')),
                GoRoute(path: 'settings',      builder: (_, _) => const PmPlaceholderScreen(title: '设置')),
                GoRoute(
                  path:    'notes',
                  builder: (_, _) => const PmPlaceholderScreen(title: '学习笔记'),
                  routes: [
                    GoRoute(path: ':id', builder: (_, s) => PmPlaceholderScreen(title: '笔记 ${s.pathParameters['id']}')),
                  ],
                ),
              ],
            ),
          ]),
        ],
      ),
    ],
  );
});
