import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme.dart';
import '../../providers/auth_provider.dart';

// ── 静态数据（MVP 硬编码，后期从接口拉取）────────────────────────────────────

class _TagItem {
  const _TagItem(this.id, this.label);
  final int    id;
  final String label;
}

const _identities = [
  (value: 'student',   label: '学生',     icon: Icons.school_outlined),
  (value: 'worker',    label: '职场人',   icon: Icons.work_outline),
  (value: 'freelance', label: '自由职业', icon: Icons.laptop_mac_outlined),
  (value: 'other',     label: '其他',     icon: Icons.person_outline),
];

const _interestItems = [
  _TagItem(1,  '音乐'),  _TagItem(2,  '电影'),  _TagItem(3,  '游戏'),
  _TagItem(4,  '运动'),  _TagItem(5,  '读书'),  _TagItem(6,  '旅行'),
  _TagItem(7,  '美食'),  _TagItem(8,  '摄影'),  _TagItem(9,  '绘画'),
  _TagItem(10, '健身'),  _TagItem(11, '编程'),  _TagItem(12, '舞蹈'),
  _TagItem(13, '烹饪'),  _TagItem(14, '宠物'),  _TagItem(15, '户外'),
];

const _purposeItems = [
  _TagItem(101, '饭搭子'),   _TagItem(102, '学习搭子'), _TagItem(103, '运动搭子'),
  _TagItem(104, '游戏搭子'), _TagItem(105, '旅行搭子'), _TagItem(106, '工作搭子'),
  _TagItem(107, '聊天搭子'), _TagItem(108, '兴趣搭子'),
];

const _ageRanges = ['18-22', '23-28', '29-35'];

// ── 主页面 ─────────────────────────────────────────────────────────────────────

class QuestionnaireScreen extends ConsumerStatefulWidget {
  const QuestionnaireScreen({super.key});

  @override
  ConsumerState<QuestionnaireScreen> createState() =>
      _QuestionnaireScreenState();
}

class _QuestionnaireScreenState extends ConsumerState<QuestionnaireScreen> {
  final _pageController = PageController();
  int _page = 0;

  String?        _identity;
  final Set<int> _interests = {};
  final Set<int> _purposes  = {};
  String?        _ageRange;
  final _cityCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cityCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _pageController.dispose();
    _cityCtrl.dispose();
    super.dispose();
  }

  bool get _canProceed => switch (_page) {
        0 => _identity != null,
        1 => _interests.length >= 3,
        2 => _purposes.isNotEmpty,
        3 => _ageRange != null && _cityCtrl.text.trim().isNotEmpty,
        _ => false,
      };

  void _next() {
    if (_page < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve:    Curves.easeInOut,
      );
    } else {
      _submit();
    }
  }

  Future<void> _submit() async {
    await ref.read(questionnaireNotifierProvider.notifier).submit(
          identity:  _identity!,
          city:      _cityCtrl.text.trim(),
          ageRange:  _ageRange!,
          interests: _interests.toList(),
          purposes:  _purposes.toList(),
        );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(questionnaireNotifierProvider);

    ref.listen(questionnaireNotifierProvider, (_, next) {
      if (next.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error.toString())),
        );
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('完善信息'),
        automaticallyImplyLeading: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: _ProgressBar(current: _page, total: 4),
        ),
      ),
      body: PageView(
        controller:    _pageController,
        physics:       const NeverScrollableScrollPhysics(),
        onPageChanged: (i) => setState(() => _page = i),
        children: [
          _IdentityPage(
            selected: _identity,
            onSelect: (v) => setState(() => _identity = v),
          ),
          _TagPickerPage(
            title:    '选择你的兴趣爱好',
            subtitle: '至少选 3 个，最多 10 个',
            items:    _interestItems,
            selected: _interests,
            onToggle: (id) => setState(() {
              if (_interests.contains(id)) {
                _interests.remove(id);
              } else if (_interests.length < 10) {
                _interests.add(id);
              }
            }),
          ),
          _TagPickerPage(
            title:    '你在找什么搭子',
            subtitle: '最多选 5 个',
            items:    _purposeItems,
            selected: _purposes,
            onToggle: (id) => setState(() {
              if (_purposes.contains(id)) {
                _purposes.remove(id);
              } else if (_purposes.length < 5) {
                _purposes.add(id);
              }
            }),
          ),
          _BasicInfoPage(
            ageRange:         _ageRange,
            cityController:   _cityCtrl,
            onAgeRangeSelect: (v) => setState(() => _ageRange = v),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Opacity(
                opacity: _canProceed ? 1.0 : 0.4,
                child: ElevatedButton(
                  onPressed: (_canProceed && !state.isLoading) ? _next : null,
                  child: state.isLoading
                      ? const SizedBox(
                          height: 20, width: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : Text(_page == 3 ? '完成' : '下一步'),
                ),
              ),
              if (_page == 3) ...[
                const SizedBox(height: 4),
                TextButton(
                  onPressed: state.isLoading ? null : _submit,
                  child: const Text('跳过，稍后完善'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── 进度条 ─────────────────────────────────────────────────────────────────────

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.current, required this.total});
  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(total, (i) => Expanded(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: 3,
          margin: EdgeInsets.only(right: i < total - 1 ? 2 : 0),
          decoration: BoxDecoration(
            color: i <= current ? AppColors.primary : AppColors.border,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      )),
    );
  }
}

// ── 第 1 步：身份选择 ──────────────────────────────────────────────────────────

class _IdentityPage extends StatelessWidget {
  const _IdentityPage({required this.selected, required this.onSelect});
  final String?              selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 16),
        const Text('你的身份是？',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        const Text('帮助我们为你定制个性化体验',
            style: TextStyle(color: AppColors.textSecondary)),
        const SizedBox(height: 32),
        ..._identities.map((item) {
          final active = selected == item.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GestureDetector(
              onTap: () => onSelect(item.value),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                decoration: BoxDecoration(
                  color: active ? AppColors.primaryLight : AppColors.surface,
                  border: Border.all(
                      color: active ? AppColors.primary : AppColors.border,
                      width: active ? 1.5 : 1),
                  borderRadius: BorderRadius.circular(AppRadius.card),
                ),
                child: Row(children: [
                  Icon(item.icon,
                      color: active ? AppColors.primary : AppColors.textSecondary),
                  const SizedBox(width: 16),
                  Text(item.label,
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                          color: active ? AppColors.primary : AppColors.textPrimary)),
                  const Spacer(),
                  if (active)
                    const Icon(Icons.check_circle,
                        color: AppColors.primary, size: 20),
                ]),
              ),
            ),
          );
        }),
      ],
    );
  }
}

// ── 第 2 / 3 步：标签多选 ──────────────────────────────────────────────────────

class _TagPickerPage extends StatelessWidget {
  const _TagPickerPage({
    required this.title,
    required this.subtitle,
    required this.items,
    required this.selected,
    required this.onToggle,
  });

  final String            title;
  final String            subtitle;
  final List<_TagItem>    items;
  final Set<int>          selected;
  final ValueChanged<int> onToggle;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 16),
        Text(title,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Text(subtitle,
            style: const TextStyle(color: AppColors.textSecondary)),
        const SizedBox(height: 28),
        Wrap(
          spacing:   10,
          runSpacing: 10,
          children: items.map((tag) {
            final active = selected.contains(tag.id);
            return GestureDetector(
              onTap: () => onToggle(tag.id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                decoration: BoxDecoration(
                  color: active ? AppColors.primary : AppColors.surface,
                  border: Border.all(
                      color: active ? AppColors.primary : AppColors.border),
                  borderRadius: BorderRadius.circular(AppRadius.tag),
                ),
                child: Text(
                  tag.label,
                  style: TextStyle(
                    color: active ? Colors.white : AppColors.textPrimary,
                    fontWeight:
                        active ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        Text('已选 ${selected.length} 个',
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 13)),
      ],
    );
  }
}

// ── 第 4 步：基本信息 ──────────────────────────────────────────────────────────

class _BasicInfoPage extends StatelessWidget {
  const _BasicInfoPage({
    required this.ageRange,
    required this.cityController,
    required this.onAgeRangeSelect,
  });

  final String?               ageRange;
  final TextEditingController cityController;
  final ValueChanged<String>  onAgeRangeSelect;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 16),
        const Text('最后一步',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        const Text('告诉我们更多关于你的信息',
            style: TextStyle(color: AppColors.textSecondary)),
        const SizedBox(height: 32),

        const Text('你的年龄段',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        Row(
          children: List.generate(_ageRanges.length, (i) {
            final range  = _ageRanges[i];
            final active = ageRange == range;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: i < _ageRanges.length - 1 ? 8 : 0),
                child: GestureDetector(
                  onTap: () => onAgeRangeSelect(range),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: active ? AppColors.primaryLight : AppColors.surface,
                      border: Border.all(
                          color: active ? AppColors.primary : AppColors.border,
                          width: active ? 1.5 : 1),
                      borderRadius: BorderRadius.circular(AppRadius.button),
                    ),
                    child: Text(
                      range,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: active ? AppColors.primary : AppColors.textPrimary,
                        fontWeight:
                            active ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),

        const SizedBox(height: 28),

        const Text('所在城市',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        TextField(
          controller: cityController,
          decoration: const InputDecoration(
            hintText:   '请输入城市，如：上海',
            prefixIcon: Icon(Icons.location_on_outlined,
                color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }
}
