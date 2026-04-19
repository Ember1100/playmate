import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app/theme.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/services/upload_service.dart';
import '../../../../shared/widgets/pm_image.dart';
import '../../../auth/data/auth_model.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../data/profile_data.dart';
import '../../providers/profile_providers.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;

  // 头像
  File?   _avatarFile;
  String? _avatarUrl;

  // 基本信息
  late final TextEditingController _usernameCtrl;
  late final TextEditingController _bioCtrl;
  late final TextEditingController _cityCtrl;
  int     _gender   = 0;
  String? _birthday;

  // 兴趣标签
  Set<int> _selectedTagIds = {};

  // 职业档案
  final TextEditingController _jobTitleCtrl    = TextEditingController();
  final TextEditingController _companyCtrl     = TextEditingController();
  final TextEditingController _lookingForCtrl  = TextEditingController();
  final TextEditingController _skillInputCtrl  = TextEditingController();
  String?      _experience;
  List<String> _skills       = [];
  bool         _careerPublic = true;

  static const _experienceOptions = ['不限', '1年以内', '1-3年', '3-5年', '5年以上'];

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider);
    _usernameCtrl = TextEditingController(text: user?.username ?? '');
    _bioCtrl      = TextEditingController(text: user?.bio ?? '');
    _cityCtrl     = TextEditingController(text: user?.city ?? '');
    _avatarUrl    = user?.avatarUrl;
    _gender       = user?.gender ?? 0;
    _birthday     = user?.birthday;

    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _bioCtrl.dispose();
    _cityCtrl.dispose();
    _jobTitleCtrl.dispose();
    _companyCtrl.dispose();
    _lookingForCtrl.dispose();
    _skillInputCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        ref.read(myTagIdsProvider.future),
        ref.read(myCareerProvider.future),
      ]);
      final tagIds = results[0] as List<int>;
      final career = results[1] as CareerModel?;
      if (!mounted) return;
      setState(() {
        _selectedTagIds = tagIds.toSet();
        if (career != null) {
          _jobTitleCtrl.text   = career.jobTitle   ?? '';
          _companyCtrl.text    = career.company    ?? '';
          _lookingForCtrl.text = career.lookingFor ?? '';
          _experience          = career.experience;
          _skills              = List.from(career.skills);
          _careerPublic        = career.isPublic;
        }
      });
    } catch (_) {
      // ignore load errors — form will still show with empty defaults
    }
  }

  Future<void> _pickAvatar() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 800,
    );
    if (picked != null && mounted) {
      setState(() => _avatarFile = File(picked.path));
    }
  }

  Future<void> _pickBirthday() async {
    DateTime initial = DateTime(2000);
    if (_birthday != null) {
      try { initial = DateTime.parse(_birthday!); } catch (_) {}
    }
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1960),
      lastDate: DateTime.now().subtract(const Duration(days: 1)),
      helpText: '选择生日',
      confirmText: '确认',
      cancelText: '取消',
    );
    if (picked != null && mounted) {
      setState(() => _birthday = picked.toIso8601String().substring(0, 10));
    }
  }

  void _addSkill() {
    final skill = _skillInputCtrl.text.trim();
    if (skill.isEmpty || _skills.contains(skill)) return;
    setState(() {
      _skills.add(skill);
      _skillInputCtrl.clear();
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      String? newAvatarUrl = _avatarUrl;
      if (_avatarFile != null) {
        newAvatarUrl = await ref.read(uploadServiceProvider).uploadAvatar(_avatarFile!);
      }

      final client = ref.read(apiClientProvider);

      // 1. 更新基本资料
      final resp = await client.put<Map<String, dynamic>>('/users/me', data: {
        'username':   _usernameCtrl.text.trim(),
        'bio':        _bioCtrl.text.trim(),
        'gender':     _gender,
        if (_birthday != null) 'birthday': _birthday,
        'city': _cityCtrl.text.trim().isEmpty ? null : _cityCtrl.text.trim(),
        'avatar_url': newAvatarUrl,
      });
      final updatedUser = UserModel.fromJson(resp['data'] as Map<String, dynamic>);
      ref.read(currentUserProvider.notifier).state = updatedUser;

      // 2. 更新兴趣标签
      await client.put<Map<String, dynamic>>('/users/me/tags', data: {
        'tag_ids': _selectedTagIds.toList(),
      });

      // 3. 更新职业档案
      await client.put<Map<String, dynamic>>('/users/me/career', data: {
        'job_title':   _jobTitleCtrl.text.trim().isEmpty   ? null : _jobTitleCtrl.text.trim(),
        'company':     _companyCtrl.text.trim().isEmpty    ? null : _companyCtrl.text.trim(),
        'experience':  _experience,
        'looking_for': _lookingForCtrl.text.trim().isEmpty ? null : _lookingForCtrl.text.trim(),
        'skills':      _skills,
        'is_public':   _careerPublic,
      });

      ref.invalidate(myTagIdsProvider);
      ref.invalidate(myCareerProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('保存成功')),
        );
        context.pop();
      }
    } on DioException catch (e) {
      if (mounted) {
        final msg = (e.response?.data as Map?)?['message'] as String? ?? '保存失败';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final allTagsAsync = ref.watch(allTagsProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.pop(),
        ),
        title: const Text('编辑资料'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                  )
                : const Text(
                    '保存',
                    style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 16),
                  ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
          children: [
            // ── 头像 ────────────────────────────────────────────────
            _buildAvatarSection(),
            const SizedBox(height: 28),

            // ── 基本信息 ─────────────────────────────────────────────
            _buildSectionTitle('基本信息'),
            const SizedBox(height: 14),
            _buildLabel('昵称'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _usernameCtrl,
              decoration: const InputDecoration(hintText: '你的昵称'),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return '昵称不能为空';
                if (v.trim().length < 2) return '至少 2 个字符';
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildLabel('个性签名'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _bioCtrl,
              maxLines: 3,
              maxLength: 200,
              decoration: const InputDecoration(hintText: '介绍一下自己吧'),
            ),
            const SizedBox(height: 16),
            _buildLabel('性别'),
            const SizedBox(height: 8),
            _buildGenderSelector(),
            const SizedBox(height: 16),
            _buildLabel('生日'),
            const SizedBox(height: 6),
            _buildBirthdayPicker(),
            const SizedBox(height: 16),
            _buildLabel('城市'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _cityCtrl,
              decoration: const InputDecoration(hintText: '你所在的城市'),
            ),
            const SizedBox(height: 28),

            // ── 兴趣标签 ─────────────────────────────────────────────
            _buildSectionTitle('兴趣标签'),
            const SizedBox(height: 6),
            const Text(
              '最多选 10 个，帮助找到志同道合的搭子',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 14),
            allTagsAsync.when(
              data: (tags) => _buildTagSelector(tags),
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                ),
              ),
              error: (_, _) => const Text('标签加载失败', style: TextStyle(color: AppColors.error)),
            ),
            const SizedBox(height: 28),

            // ── 职业档案 ─────────────────────────────────────────────
            _buildSectionTitle('职业档案'),
            const SizedBox(height: 4),
            _buildCareerPublicToggle(),
            const SizedBox(height: 14),
            _buildLabel('职位名称'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _jobTitleCtrl,
              decoration: const InputDecoration(hintText: '如：前端工程师、产品经理'),
            ),
            const SizedBox(height: 16),
            _buildLabel('公司/组织'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _companyCtrl,
              decoration: const InputDecoration(hintText: '你工作或学习的地方'),
            ),
            const SizedBox(height: 16),
            _buildLabel('工作经验'),
            const SizedBox(height: 8),
            _buildExperienceSelector(),
            const SizedBox(height: 16),
            _buildLabel('希望找到'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _lookingForCtrl,
              maxLines: 2,
              decoration: const InputDecoration(hintText: '描述你希望找到什么样的搭子'),
            ),
            const SizedBox(height: 16),
            _buildLabel('技能标签'),
            const SizedBox(height: 8),
            _buildSkillsEditor(),
          ],
        ),
      ),
    );
  }

  // ── 头像 ──────────────────────────────────────────────────────────────────

  Widget _buildAvatarSection() {
    return Center(
      child: GestureDetector(
        onTap: _pickAvatar,
        child: Stack(
          children: [
            CircleAvatar(
              radius: 44,
              backgroundColor: AppColors.primary,
              backgroundImage: _avatarFile != null
                  ? FileImage(_avatarFile!) as ImageProvider
                  : (_avatarUrl != null ? PmImageProvider(_avatarUrl!) : null),
              child: (_avatarFile == null && _avatarUrl == null)
                  ? Text(
                      (_usernameCtrl.text.isNotEmpty ? _usernameCtrl.text : 'U')
                          .substring(0, 1)
                          .toUpperCase(),
                      style: const TextStyle(
                        fontSize: 32,
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    )
                  : null,
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(Icons.camera_alt, color: Colors.white, size: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 性别选择 ──────────────────────────────────────────────────────────────

  Widget _buildGenderSelector() {
    const options = [(0, '保密'), (1, '男'), (2, '女')];
    return Row(
      children: options.map((opt) {
        final selected = _gender == opt.$1;
        return Padding(
          padding: const EdgeInsets.only(right: 10),
          child: GestureDetector(
            onTap: () => setState(() => _gender = opt.$1),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                opt.$2,
                style: TextStyle(
                  fontSize: 14,
                  color: selected ? Colors.white : const Color(0xFF666666),
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── 生日选择器 ────────────────────────────────────────────────────────────

  Widget _buildBirthdayPicker() {
    return GestureDetector(
      onTap: _pickBirthday,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F7F7),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE0E0E0)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                _birthday ?? '请选择生日',
                style: TextStyle(
                  fontSize: 15,
                  color: _birthday != null ? const Color(0xFF222222) : const Color(0xFFBBBBBB),
                ),
              ),
            ),
            const Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  // ── 兴趣标签 ──────────────────────────────────────────────────────────────

  Widget _buildTagSelector(List<TagModel> tags) {
    final categories = tags.map((t) => t.category).toSet().toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: categories.map((cat) {
        final catTags = tags.where((t) => t.category == cat).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              cat,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: catTags.map((tag) {
                final selected = _selectedTagIds.contains(tag.id);
                return GestureDetector(
                  onTap: () => setState(() {
                    if (selected) {
                      _selectedTagIds.remove(tag.id);
                    } else if (_selectedTagIds.length < 10) {
                      _selectedTagIds.add(tag.id);
                    }
                  }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.primary : const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      tag.name,
                      style: TextStyle(
                        fontSize: 13,
                        color: selected ? Colors.white : const Color(0xFF444444),
                        fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],
        );
      }).toList(),
    );
  }

  // ── 职业档案公开开关 ──────────────────────────────────────────────────────

  Widget _buildCareerPublicToggle() {
    return Row(
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('公开职业档案', style: TextStyle(fontSize: 14, color: Color(0xFF333333))),
              SizedBox(height: 2),
              Text(
                '开启后其他用户可以看到你的职业信息',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        Switch(
          value: _careerPublic,
          activeThumbColor: AppColors.primary,
          onChanged: (v) => setState(() => _careerPublic = v),
        ),
      ],
    );
  }

  // ── 工作经验选择 ──────────────────────────────────────────────────────────

  Widget _buildExperienceSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _experienceOptions.map((opt) {
        final selected = _experience == opt;
        return GestureDetector(
          onTap: () => setState(() => _experience = selected ? null : opt),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: selected ? AppColors.primary : const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              opt,
              style: TextStyle(
                fontSize: 13,
                color: selected ? Colors.white : const Color(0xFF444444),
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── 技能标签编辑器 ────────────────────────────────────────────────────────

  Widget _buildSkillsEditor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ..._skills.map(
              (skill) => Chip(
                label: Text(skill, style: const TextStyle(fontSize: 12)),
                deleteIcon: const Icon(Icons.close, size: 14),
                onDeleted: () => setState(() => _skills.remove(skill)),
                backgroundColor: const Color(0xFFFFF0E0),
                labelStyle: const TextStyle(color: AppColors.primary),
                side: BorderSide.none,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
        if (_skills.isNotEmpty) const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _skillInputCtrl,
                decoration: const InputDecoration(
                  hintText: '输入技能名称',
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                onSubmitted: (_) => _addSkill(),
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: _addSkill,
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFFFFF0E0),
                foregroundColor: AppColors.primary,
              ),
              child: const Text('添加'),
            ),
          ],
        ),
      ],
    );
  }

  // ── 共用组件 ──────────────────────────────────────────────────────────────

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(width: 3, height: 16, color: AppColors.primary,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF222222)),
        ),
      ],
    );
  }

  Widget _buildLabel(String label) {
    return Text(
      label,
      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
    );
  }
}
