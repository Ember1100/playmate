import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    // 防止重复点击
    if (ref.read(authNotifierProvider).isLoading) return;
    await ref.read(authNotifierProvider.notifier).login(
          _emailController.text.trim(),
          _passwordController.text,
        );
    if (!mounted) return;
    final authState = ref.read(authNotifierProvider);
    if (authState.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(authState.error.toString()),
            backgroundColor: AppColors.error),
      );
    }
    // 登录成功后 isLoggedInProvider 已 invalidate，路由守卫自动跳转到 /discover
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authNotifierProvider).isLoading;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 64),

                // Logo
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(Icons.people_alt_rounded,
                      color: Colors.white, size: 36),
                ),
                const SizedBox(height: 24),

                const Text(
                  '欢迎来到玩伴',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '遇见有趣的灵魂',
                  style: TextStyle(fontSize: 15, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 48),

                // 邮箱
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    hintText: '手机号 / 邮箱',
                    prefixIcon: Icon(Icons.person_outline, color: AppColors.textSecondary),
                  ),
                  validator: (v) =>
                      v == null || v.isEmpty ? '请输入账号' : null,
                ),
                const SizedBox(height: 12),

                // 密码
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    hintText: '密码',
                    prefixIcon: const Icon(Icons.lock_outline, color: AppColors.textSecondary),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: AppColors.textSecondary,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (v) =>
                      v == null || v.isEmpty ? '请输入密码' : null,
                ),
                const SizedBox(height: 28),

                // 登录按钮
                ElevatedButton(
                  onPressed: isLoading ? null : _login,
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('登录',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(height: 20),

                // 注册跳转
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('还没有账号？',
                        style: TextStyle(color: AppColors.textSecondary)),
                    TextButton(
                      onPressed: () => context.push('/register'),
                      child: const Text('立即注册',
                          style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),

                const SizedBox(height: 32),
                const Row(
                  children: [
                    Expanded(child: Divider(color: AppColors.border)),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text('其他登录方式',
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 13)),
                    ),
                    Expanded(child: Divider(color: AppColors.border)),
                  ],
                ),
                const SizedBox(height: 20),

                // 第三方登录
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _ThirdPartyButton(
                      icon: Icons.wechat,
                      color: const Color(0xFF07C160),
                      label: '微信',
                      onTap: () {},
                    ),
                    const SizedBox(width: 24),
                    _ThirdPartyButton(
                      icon: Icons.apple,
                      color: AppColors.textPrimary,
                      label: 'Apple',
                      onTap: () {},
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ThirdPartyButton extends StatelessWidget {
  const _ThirdPartyButton({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.background,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 6),
          Text(label,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
