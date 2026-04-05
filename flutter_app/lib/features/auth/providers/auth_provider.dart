import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/auth_model.dart';
import '../data/auth_repository.dart';

// 当前用户状态
final currentUserProvider = StateProvider<UserModel?>((ref) => null);

// 登录状态检查
final isLoggedInProvider = FutureProvider<bool>((ref) {
  return ref.watch(authRepositoryProvider).isLoggedIn();
});

// App 启动时恢复 session（从 Token 重新拉取用户信息）
final appStartupProvider = FutureProvider<void>((ref) async {
  final isLoggedIn = await ref.watch(isLoggedInProvider.future);
  if (!isLoggedIn) return;
  final user = await ref.read(authRepositoryProvider).getCurrentUser();
  if (user != null) {
    ref.read(currentUserProvider.notifier).state = user;
  } else {
    // Token 失效，清除登录态
    await ref.read(authRepositoryProvider).logout();
    ref.invalidate(isLoggedInProvider);
  }
});

// 登录 Notifier
class AuthNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> login(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(authRepositoryProvider);
      final auth = await repo.login(email: email, password: password);
      ref.read(currentUserProvider.notifier).state = auth.user;
      ref.invalidate(isLoggedInProvider);
    });
  }

  Future<void> devLogin(String phone, String password, {String? username}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(authRepositoryProvider);
      final auth = await repo.devLogin(phone: phone, password: password, username: username);
      ref.read(currentUserProvider.notifier).state = auth.user;
      ref.invalidate(isLoggedInProvider);
    });
  }

  Future<void> register(String username, String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(authRepositoryProvider);
      final auth = await repo.register(
          username: username, email: email, password: password);
      ref.read(currentUserProvider.notifier).state = auth.user;
      ref.invalidate(isLoggedInProvider);
    });
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    ref.read(currentUserProvider.notifier).state = null;
    ref.invalidate(isLoggedInProvider);
  }
}

final authNotifierProvider =
    AsyncNotifierProvider<AuthNotifier, void>(AuthNotifier.new);
