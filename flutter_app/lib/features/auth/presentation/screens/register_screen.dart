import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme.dart';
import '../../providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (ref.read(authNotifierProvider).isLoading) return;
    await ref.read(authNotifierProvider.notifier).register(
          _usernameController.text.trim(),
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
    // 注册成功后路由守卫自动跳转
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authNotifierProvider).isLoading;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                const Text(
                  '创建账号',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '加入玩伴，认识有趣的人',
                  style: TextStyle(
                      fontSize: 15, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 36),

                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    hintText: '昵称',
                    prefixIcon: Icon(Icons.badge_outlined,
                        color: AppColors.textSecondary),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return '请输入昵称';
                    if (v.length < 2) return '昵称至少2个字符';
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    hintText: '邮箱',
                    prefixIcon: Icon(Icons.email_outlined,
                        color: AppColors.textSecondary),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return '请输入邮箱';
                    if (!v.contains('@')) return '请输入有效的邮箱';
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    hintText: '密码（至少6位）',
                    prefixIcon: const Icon(Icons.lock_outline,
                        color: AppColors.textSecondary),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: AppColors.textSecondary,
                      ),
                      onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return '请输入密码';
                    if (v.length < 6) return '密码至少6位';
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                ElevatedButton(
                  onPressed: isLoading ? null : _register,
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('注册',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(height: 20),

                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('已有账号？',
                          style:
                              TextStyle(color: AppColors.textSecondary)),
                      TextButton(
                        onPressed: () => context.pop(),
                        child: const Text('立即登录',
                            style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
