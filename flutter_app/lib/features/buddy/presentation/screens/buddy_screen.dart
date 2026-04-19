import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../shared/widgets/pm_image.dart';
import '../../../im/data/im_repository.dart';
import '../../../im/providers/im_provider.dart';
import '../../data/gather_model.dart';
import '../../data/gather_repository.dart';
import '../../providers/gather_provider.dart';
import '../../providers/menu_provider.dart';

/// 搭子 Tab 首页
class BuddyScreen extends ConsumerStatefulWidget {
  const BuddyScreen({super.key});

  @override
  ConsumerState<BuddyScreen> createState() => _BuddyScreenState();
}

class _BuddyScreenState extends ConsumerState<BuddyScreen> with WidgetsBindingObserver {
  // 一级菜单 ID（null = 全部）
  int? _selectedFirstMenuId;
  int _subTagIndex = -1;
  final int _topTab = 0;

  // ── 搜索状态 ──────────────────────────────────────────────────────────────
  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();
  bool _searchActive = false; // 搜索模式是否激活（唯一权威标志）
  bool _hasResults = false;
  bool _searchLoading = false;
  BuddySearchResult? _searchResult;

  // ── 搜索历史 ──────────────────────────────────────────────────────────────
  static const _historyKey = 'buddy_search_history';
  static const _historyMax = 10;
  List<String> _history = [];

  // 搜索模式：只要 _searchActive=true 就拦截返回手势，避免中间帧导致的漏拦截
  bool get _isSearching => _searchActive;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _searchFocus.addListener(() {
      if (_searchFocus.hasFocus && !_searchActive) {
        setState(() => _searchActive = true);
      } else {
        setState(() {}); // 失焦时仅刷新，不清 _searchActive
      }
    });
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_historyKey) ?? [];
    if (mounted) setState(() => _history = list);
  }

  Future<void> _addHistory(String keyword) async {
    final trimmed = keyword.trim();
    if (trimmed.isEmpty) return;
    final list = List<String>.from(_history)
      ..remove(trimmed)          // 去重：先移除旧的
      ..insert(0, trimmed);      // 置顶
    if (list.length > _historyMax) list.removeRange(_historyMax, list.length);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_historyKey, list);
    if (mounted) setState(() => _history = list);
  }

  Future<void> _removeHistory(String keyword) async {
    final list = List<String>.from(_history)..remove(keyword);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_historyKey, list);
    if (mounted) setState(() => _history = list);
  }

  Future<void> _clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
    if (mounted) setState(() => _history = []);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  // 在 WidgetsBinding 层拦截 Android 返回手势，
  // 比 PopScope 更早执行，与 go_router 嵌套 Navigator 层级无关
  @override
  Future<bool> didPopRoute() async {
    if (_searchActive) {
      _cancelSearch();
      return true; // 已处理，不再向上冒泡
    }
    return false; // 未处理，交给系统
  }

  // 仅更新输入框视觉状态（不触发 API）
  void _onSearchChanged(String text) {
    if (text.trim().isEmpty) {
      setState(() { _hasResults = false; _searchResult = null; });
    } else {
      setState(() => _searchActive = true);
    }
  }

  // 提交搜索（Enter / 历史词点击）→ 调 API
  Future<void> _doSearch() async {
    final text = _searchCtrl.text.trim();
    if (text.isEmpty) {
      setState(() => _hasResults = false);
      return;
    }
    setState(() { _searchActive = true; _searchLoading = true; });
    try {
      final result = await ref.read(gatherRepositoryProvider).search(text);
      if (mounted) {
        setState(() {
          _searchResult  = result;
          _hasResults    = !result.isEmpty;
          _searchLoading = false;
        });
      }
      await _addHistory(text); // 搜索成功后写入历史
    } catch (_) {
      if (mounted) setState(() { _searchLoading = false; _hasResults = false; });
    }
  }

  void _clearSearch() {
    _searchCtrl.clear();
    setState(() { _hasResults = false; _searchResult = null; });
    // 焦点保持，键盘不收起，用户可继续输入
  }

  void _cancelSearch() {
    _searchCtrl.clear();
    _searchFocus.unfocus();
    setState(() { _searchActive = false; _hasResults = false; _searchResult = null; });
  }

  // 从搜索结果直接发起私信（创建会话后跳转）
  Future<void> _startChat(SearchUser user) async {
    final router = GoRouter.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final convId = await ref.read(imRepositoryProvider).createConversation(user.id);
      // 刷新会话列表，确保消息 Tab 实时出现新对话
      ref.invalidate(conversationsProvider);
      if (mounted) {
        router.push('/im/chat/$convId', extra: {
          'username': user.username,
          'otherAvatarUrl': user.avatarUrl,
        });
      }
    } catch (_) {
      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(content: Text('创建会话失败，请重试')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // 搜索激活时拦截系统返回（Android 返回键 / 边缘滑动），改为取消搜索
      canPop: !_isSearching,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _cancelSearch();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFFFF9EF),
        body: SafeArea(
          child: Column(
            children: [
              _buildSearchBar(),
              Expanded(
                child: _isSearching
                    ? (_hasResults ? _buildResultList() : _buildSearchDefaultContent())
                    : _buildNormalContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── 搜索栏（贯穿所有状态的唯一输入框）────────────────────────────────────

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Row(
        children: [
          // 搜索框
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFFF8C42), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF8C42).withValues(alpha: 0.10),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const SizedBox(width: 12),
                  const Icon(Icons.search_rounded, color: Color(0xFFFF8C42), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchCtrl,
                      focusNode: _searchFocus,
                      textInputAction: TextInputAction.search,
                      onChanged: _onSearchChanged,
                      onSubmitted: (_) => _doSearch(),
                      style: const TextStyle(fontSize: 14, color: Color(0xFF2C2C2A)),
                      decoration: const InputDecoration(
                        hintText: '搜搭子或搭子局…',
                        hintStyle: TextStyle(fontSize: 14, color: Color(0xFFBBBBBB)),
                        filled: false,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 11),
                      ),
                    ),
                  ),
                  if (_searchCtrl.text.isNotEmpty)
                    GestureDetector(
                      onTap: _clearSearch,
                      child: Container(
                        width: 18, height: 18,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: const BoxDecoration(color: Color(0xFFDDDDDD), shape: BoxShape.circle),
                        child: const Icon(Icons.close, size: 11, color: Color(0xFF999999)),
                      ),
                    )
                  else
                    const SizedBox(width: 4),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 搜索结果列表（有结果时显示）─────────────────────────────────────────

  Widget _buildResultList() {
    if (_searchLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFFF7A00)));
    }
    final result = _searchResult;
    if (result == null || result.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded, size: 48, color: Color(0xFFDDDDDD)),
            SizedBox(height: 12),
            Text('没有找到相关搭子', style: TextStyle(color: Color(0xFF999999))),
          ],
        ),
      );
    }
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          // ── 搭子推荐 ──
          if (result.users.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('搭子推荐', style: TextStyle(fontSize: 13, color: Color(0xFF888780))),
                  Text('共 ${result.userTotal} 人', style: const TextStyle(fontSize: 12, color: Color(0xFFFF8C42))),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: result.users
                    .map((u) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _SearchUserCard(
                            user: u,
                            onTap: () => context.push('/buddy/user/${u.id}', extra: {
                              'username': u.username,
                              'avatarUrl': u.avatarUrl,
                            }),
                            onChat: () => _startChat(u),
                          ),
                        ))
                    .toList(),
              ),
            ),
          ],
          // ── 相关搭子局 ──
          if (result.gathers.isNotEmpty) ...[
            if (result.users.isNotEmpty)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                height: 0.5,
                color: const Color(0xFFE8E6E0),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('相关搭子局', style: TextStyle(fontSize: 13, color: Color(0xFF888780))),
                  Text('共 ${result.gatherTotal} 个', style: const TextStyle(fontSize: 12, color: Color(0xFFFF8C42))),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: result.gathers
                    .map((g) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _SearchGatherCard(
                            gather: g,
                            onTap: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                useRootNavigator: true,
                                enableDrag: false,
                                backgroundColor: Colors.transparent,
                                builder: (_) => _GatherDetailSheet(
                                  item: g,
                                  firstMenuId: g.firstMenuId,
                                ),
                              );
                            },
                          ),
                        ))
                    .toList(),
              ),
            ),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ── 搜索激活但未出结果：搜索历史 ─────────────────────────────────────────

  Widget _buildSearchDefaultContent() {
    if (_history.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history_rounded, size: 44, color: Color(0xFFDDDDDD)),
            SizedBox(height: 10),
            Text('暂无搜索记录', style: TextStyle(fontSize: 14, color: Color(0xFFBBBBBB))),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          // 标题行
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 12, 10),
            child: Row(
              children: [
                const Text('搜索历史',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF888780))),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    showDialog<void>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('清除历史记录'),
                        content: const Text('确定要清除全部搜索历史吗？'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
                          TextButton(
                            onPressed: () { Navigator.pop(ctx); _clearHistory(); },
                            child: const Text('清除', style: TextStyle(color: Color(0xFFE24B4A))),
                          ),
                        ],
                      ),
                    );
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    child: Text('清除', style: TextStyle(fontSize: 12, color: Color(0xFFBBBBBB))),
                  ),
                ),
              ],
            ),
          ),
          // 历史词列表
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _history.map((word) => GestureDetector(
                onTap: () async {
                  _searchCtrl.text = word;
                  await _doSearch();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFEEEEEE), width: 0.8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.history_rounded, size: 13, color: Color(0xFFCCCCCC)),
                      const SizedBox(width: 4),
                      Text(word, style: const TextStyle(fontSize: 13, color: Color(0xFF555550))),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () => _removeHistory(word),
                        child: const Icon(Icons.close, size: 13, color: Color(0xFFCCCCCC)),
                      ),
                    ],
                  ),
                ),
              )).toList(),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ── 普通内容（搜索未激活时）────────────────────────────────────────────────

  Widget _buildNormalContent() {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(child: _buildBanner()),
        SliverToBoxAdapter(child: _buildCategoryGrid(context)),
        SliverToBoxAdapter(child: _buildTopTabBar()),
        SliverToBoxAdapter(child: _buildCategoryTabs()),
        SliverToBoxAdapter(child: _buildSubTagRow()),
        _topTab == 0
            ? (_subTagIndex < 0
                ? _buildGatherListSliver()
                : _buildSubTagBuddyGridSliver())
            : _buildBuddyFeedGridSliver(),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }

  // ── 原有：横幅 ────────────────────────────────────────────────────────────
  Widget _buildBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      height: 148,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFE8C0), Color(0xFFFFD166), Color(0xFFFFB703)],
                  begin: Alignment(-0.7, -0.7),
                  end: Alignment(1, 1),
                ),
              ),
            ),
          ),
          Positioned(left: 28, top: 12, child: _CloudShape(width: 72, height: 36)),
          Positioned(left: 96, top: 24, child: _CloudShape(width: 56, height: 28, opacity: 0.9)),
          Positioned(right: 80, top: 8, child: _CloudShape(width: 64, height: 32)),
          const Positioned(
            left: 16, top: 0, bottom: 0,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('周末不宅', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF333333), letterSpacing: 1, height: 1.25)),
                Text('组队去野', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF333333), letterSpacing: 1, height: 1.25)),
              ],
            ),
          ),
          Positioned(right: -8, bottom: -12, width: 100, height: 100, child: CustomPaint(painter: _OwlPainter())),
          const Positioned(right: 10, bottom: 8, child: Text('1/1', style: TextStyle(fontSize: 11, color: Color(0x73000000)))),
          Positioned(
            bottom: 4, left: 0, right: 0,
            child: Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(2)))),
          ),
        ],
      ),
    );
  }

  // ── 原有：三分类卡片（线上搭子/线下搭子/职业搭子）────────────────────────
  Widget _buildCategoryGrid(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
      child: SizedBox(
        height: 202,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    child: _CategoryCard(title: '线上搭子', subtitle: '快速匹配', bgColor: const Color(0xFFFFE8C0), decoType: _CardDecoType.online, onTap: () => context.push('/buddy/candidates')),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: _CategoryCard(title: '发起搭子局', subtitle: '呼朋唤友出去玩', bgColor: const Color(0xFFFFE082), decoType: _CardDecoType.offline, onTap: () => _showPublishDialog()),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _CategoryCard(title: '职业搭子', subtitle: '您的专业老师', bgColor: const Color(0xFFFFE8C0), decoType: _CardDecoType.pro, onTap: () => context.push('/buddy/career')),
            ),
          ],
        ),
      ),
    );
  }

  // ── 原有：标签行 ──────────────────────────────────────────────────────────
  // ══════════════════════════════════════════════════════════════════════════
  //  以下是新增的搭子局 / 搭子人物 两层切换
  // ══════════════════════════════════════════════════════════════════════════

  // ── 顶部 Tab 栏：搭子局 / 搭子 ─────────────────────────────────────────
  Widget _buildTopTabBar() {
    return const SizedBox.shrink();
  }

  // ── 一级分类 Tab（搭子局 Tab 下才显示）────────────────────────────────────
  Widget _buildCategoryTabs() {
    if (_topTab != 0) return const SizedBox.shrink();
    final menusAsync = ref.watch(menusProvider);
    final menus = menusAsync.valueOrNull ?? [];
    // 构建 tab 列表：「全部」+ 各一级菜单
    final tabs = <(int?, String)>[(null, '全部'), ...menus.map((m) => (m.id, m.name))];
    return Container(
      height: 44,
      color: Colors.white,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: tabs.map((tab) {
            final selected = tab.$1 == _selectedFirstMenuId;
            return GestureDetector(
              onTap: () {
                final newId = tab.$1;
                if (newId != _selectedFirstMenuId) {
                  ref.invalidate(gatherListProvider(newId));
                }
                setState(() { _selectedFirstMenuId = newId; _subTagIndex = -1; });
              },
              child: Container(
                margin: const EdgeInsets.only(right: 4),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: selected ? const Color(0xFFFF7A00) : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  tab.$2,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                    color: selected ? Colors.white : const Color(0xFF666666),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ── 二级子标签行（点击 → 显示搭子人物）────────────────────────────────────
  Widget _buildSubTagRow() {
    if (_topTab != 0) return const SizedBox.shrink();
    // 从菜单 provider 取当前一级菜单的二级子项
    final menus = ref.watch(menusProvider).valueOrNull ?? [];
    final selectedMenu = _selectedFirstMenuId == null
        ? null
        : menus.where((m) => m.id == _selectedFirstMenuId).firstOrNull;
    final subItems = selectedMenu?.children ?? [];
    if (subItems.isEmpty) return const SizedBox.shrink();
    return Container(
      height: 40,
      color: const Color(0xFFFFF9EF),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: List.generate(subItems.length, (i) {
            final selected = i == _subTagIndex;
            return GestureDetector(
              onTap: () => setState(() { _subTagIndex = selected ? -1 : i; }),
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: selected ? const Color(0xFFFFEDD0) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: selected ? const Color(0xFFFF7A00) : const Color(0xFFEEEEEE)),
                ),
                child: Text(
                  '${subItems[i].name}搭子',
                  style: TextStyle(
                    fontSize: 12,
                    color: selected ? const Color(0xFFFF7A00) : const Color(0xFF666666),
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  // ── 搭子局卡片列表（Sliver）───────────────────────────────────────────────
  Widget _buildGatherListSliver() {
    final asyncGathers = ref.watch(gatherListProvider(_selectedFirstMenuId));

    return asyncGathers.when(
      loading: () => const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Center(child: CircularProgressIndicator(color: Color(0xFFFF7A00))),
        ),
      ),
      error: (e, _) => SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(children: [
            const Icon(Icons.wifi_off_outlined, size: 40, color: Color(0xFFCCCCCC)),
            const SizedBox(height: 8),
            const Text('加载失败，下拉刷新重试', style: TextStyle(color: Color(0xFF999999))),
            TextButton(
              onPressed: () => ref.read(gatherListProvider(_selectedFirstMenuId).notifier).refresh(),
              child: const Text('重试', style: TextStyle(color: Color(0xFFFF7A00))),
            ),
          ]),
        ),
      ),
      data: (items) {
        if (items.isEmpty) {
          return const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: Column(children: [
                Icon(Icons.group_outlined, size: 48, color: Color(0xFFDDDDDD)),
                SizedBox(height: 8),
                Text('暂无搭子局，来发起第一个吧', style: TextStyle(color: Color(0xFF999999))),
              ]),
            ),
          );
        }
        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (_, i) => Padding(
              padding: EdgeInsets.fromLTRB(12, i == 0 ? 10 : 0, 12, 12),
              child: _GatherCard(
                item: items[i],
                onTap: () => _showGatherDetail(context, items[i], _selectedFirstMenuId),
              ),
            ),
            childCount: items.length,
          ),
        );
      },
    );
  }

  void _showGatherDetail(BuildContext context, Gather item, int? firstMenuId) {
    showModalBottomSheet(
      context: context, isScrollControlled: true, useRootNavigator: true,
      backgroundColor: Colors.transparent, enableDrag: false,
      builder: (_) => _GatherDetailSheet(item: item, firstMenuId: firstMenuId),
    );
  }

  // ── 子标签 → 搭子人物网格（Sliver）────────────────────────────────────────
  SliverToBoxAdapter _buildSubTagBuddyGridSliver() {
    final menus = ref.watch(menusProvider).valueOrNull ?? [];
    final selectedMenu = _selectedFirstMenuId == null
        ? null
        : menus.where((m) => m.id == _selectedFirstMenuId).firstOrNull;
    final subItems = selectedMenu?.children ?? [];
    final tag = (_subTagIndex >= 0 && _subTagIndex < subItems.length)
        ? '${subItems[_subTagIndex].name}搭子'
        : '';
    final people = _mockBuddyPeople(tag);
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10,
          childAspectRatio: 0.47,
          children: people.map((p) => _BuddyPersonCard(data: p)).toList(),
        ),
      ),
    );
  }

  // ── 搭子 Tab → 原有 Feed 网格（Sliver）───────────────────────────────────
  SliverToBoxAdapter _buildBuddyFeedGridSliver() {
    const feeds = [
      _OrigFeedData('星际海渊', '价格面议', '已预约：0 剩余：10', 'https://picsum.photos/seed/meal/300/240'),
      _OrigFeedData('室内烤肉自助活动', '¥58.00', '已预约：0 剩余：8', 'https://picsum.photos/seed/bbq/300/240'),
      _OrigFeedData('骑在黎明破晓前露营折叠车', '免费', '已预约：0 剩余：5', 'https://picsum.photos/seed/friend/300/240'),
      _OrigFeedData('室内网球活动', '¥88.00', '已预约：0 剩余：12', 'https://picsum.photos/seed/tennis/300/240'),
    ];
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10,
          childAspectRatio: 0.78,
          children: feeds.map((f) => _OrigFeedCard(data: f)).toList(),
        ),
      ),
    );
  }

  void _showPublishDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (_) => _PublishGatherSheet(defaultFirstMenuId: _selectedFirstMenuId),
    );
  }


  // ── 搭子人物模拟数据 ──────────────────────────────────────────────────────
  List<_BuddyPerson> _mockBuddyPeople(String tag) {
    switch (tag) {
      case '饭搭子':
        return const [
          _BuddyPerson(name: '小鱼', age: 23, city: '上海', avatar: 'https://picsum.photos/seed/p1/200/200', desc: '爱吃川菜，周末约饭', tag: '饭搭子'),
          _BuddyPerson(name: '阿杰', age: 25, city: '上海', avatar: 'https://picsum.photos/seed/p2/200/200', desc: '探店达人，火锅爱好者', tag: '饭搭子'),
          _BuddyPerson(name: '甜甜', age: 22, city: '上海', avatar: 'https://picsum.photos/seed/p3/200/200', desc: '甜品控，周末想约下午茶', tag: '饭搭子'),
          _BuddyPerson(name: '大壮', age: 27, city: '上海', avatar: 'https://picsum.photos/seed/p4/200/200', desc: '烧烤达人，自带装备', tag: '饭搭子'),
        ];
      case '探店搭子':
        return const [
          _BuddyPerson(name: '小薇', age: 24, city: '上海', avatar: 'https://picsum.photos/seed/p5/200/200', desc: '咖啡探店，拍照达人', tag: '探店搭子'),
          _BuddyPerson(name: '浩哥', age: 26, city: '上海', avatar: 'https://picsum.photos/seed/p6/200/200', desc: '美食博主，寻找新店', tag: '探店搭子'),
        ];
      case '遛宠搭子':
        return const [
          _BuddyPerson(name: '毛毛妈', age: 25, city: '上海', avatar: 'https://picsum.photos/seed/p7/200/200', desc: '金毛家长，周末公园遛弯', tag: '遛宠搭子'),
          _BuddyPerson(name: '猫叔', age: 28, city: '上海', avatar: 'https://picsum.photos/seed/p8/200/200', desc: '三只猫主人，猫咖常客', tag: '遛宠搭子'),
          _BuddyPerson(name: '柯基控', age: 23, city: '上海', avatar: 'https://picsum.photos/seed/p9/200/200', desc: '柯基爸爸，寻遛狗伙伴', tag: '遛宠搭子'),
        ];
      case '观影搭子':
        return const [
          _BuddyPerson(name: '影迷小李', age: 24, city: '上海', avatar: 'https://picsum.photos/seed/p10/200/200', desc: '科幻迷，每周必看新片', tag: '观影搭子'),
          _BuddyPerson(name: '文艺青年', age: 26, city: '上海', avatar: 'https://picsum.photos/seed/p11/200/200', desc: '独立电影爱好者', tag: '观影搭子'),
        ];
      case '考研搭子':
        return const [
          _BuddyPerson(name: '学霸小陈', age: 22, city: '上海', avatar: 'https://picsum.photos/seed/p12/200/200', desc: '备战27考研，每天图书馆', tag: '考研搭子'),
          _BuddyPerson(name: '阿文', age: 23, city: '上海', avatar: 'https://picsum.photos/seed/p13/200/200', desc: '二战考研，互相监督', tag: '考研搭子'),
          _BuddyPerson(name: '小月', age: 21, city: '上海', avatar: 'https://picsum.photos/seed/p14/200/200', desc: '法硕备考，求研友', tag: '考研搭子'),
        ];
      case '摄影搭子':
        return const [
          _BuddyPerson(name: '阿光', age: 27, city: '上海', avatar: 'https://picsum.photos/seed/p15/200/200', desc: '风光摄影，周末扫街', tag: '摄影搭子'),
          _BuddyPerson(name: '小美', age: 24, city: '上海', avatar: 'https://picsum.photos/seed/p16/200/200', desc: '人像摄影，互拍互修', tag: '摄影搭子'),
        ];
      case '剧本杀搭子':
        return const [
          _BuddyPerson(name: '推理王', age: 25, city: '上海', avatar: 'https://picsum.photos/seed/p17/200/200', desc: '硬核推理，百本+经验', tag: '剧本杀搭子'),
          _BuddyPerson(name: '戏精本精', age: 23, city: '上海', avatar: 'https://picsum.photos/seed/p18/200/200', desc: '情感本爱好者，喜欢沉浸式', tag: '剧本杀搭子'),
          _BuddyPerson(name: '新手小白', age: 22, city: '上海', avatar: 'https://picsum.photos/seed/p19/200/200', desc: '刚入坑，求带飞', tag: '剧本杀搭子'),
        ];
      default:
        return const [
          _BuddyPerson(name: '搭伴用户', age: 25, city: '上海', avatar: 'https://picsum.photos/seed/pd/200/200', desc: '期待与你相遇', tag: '搭子'),
        ];
    }
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  原有组件（保持不变）
// ═════════════════════════════════════════════════════════════════════════════

class _CloudShape extends StatelessWidget {
  const _CloudShape({required this.width, required this.height, this.opacity = 1.0});
  final double width;
  final double height;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width, height: height,
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.85 * opacity), borderRadius: BorderRadius.circular(50)),
    );
  }
}

class _OwlPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 100;
    void ell(double cx, double cy, double rx, double ry, Color color) {
      canvas.drawOval(Rect.fromCenter(center: Offset(cx * s, cy * s), width: rx * 2 * s, height: ry * 2 * s), Paint()..color = color);
    }
    void circ(double cx, double cy, double r, Color color) {
      canvas.drawCircle(Offset(cx * s, cy * s), r * s, Paint()..color = color);
    }
    ell(72, 78, 42, 38, const Color(0xFFC5E1A5));
    ell(72, 72, 38, 34, const Color(0xFFDCEDC8));
    ell(58, 52, 18, 20, Colors.white);
    ell(58, 52, 10, 12, const Color(0xFF263238));
    circ(56, 48, 3, Colors.white);
    ell(78, 48, 14, 16, Colors.white);
    ell(78, 48, 8, 9, const Color(0xFF263238));
    circ(76, 44, 2.5, Colors.white);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

enum _CardDecoType { online, offline, pro }

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.title, required this.subtitle, required this.bgColor, required this.decoType, required this.onTap});
  final String title;
  final String subtitle;
  final Color bgColor;
  final _CardDecoType decoType;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(18), boxShadow: const [BoxShadow(blurRadius: 8, color: Color(0x0D000000), offset: Offset(0, 2))]),
        child: Stack(
          children: [
            Positioned(right: 4, bottom: 4, width: decoType == _CardDecoType.pro ? 80 : 64, height: decoType == _CardDecoType.pro ? 80 : 48, child: CustomPaint(painter: _CardDecoPainter(decoType))),
            Positioned(
              left: 14, top: 14, right: 40,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF222222))),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(fontSize: 11, color: Color(0xFF666666), height: 1.4), maxLines: 2),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardDecoPainter extends CustomPainter {
  const _CardDecoPainter(this.type);
  final _CardDecoType type;
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width; final h = size.height;
    void ell(double cx, double cy, double rx, double ry, Color color, {double opacity = 1.0}) {
      canvas.drawOval(Rect.fromCenter(center: Offset(cx * w, cy * h), width: rx * 2 * w, height: ry * 2 * h), Paint()..color = color.withValues(alpha: opacity));
    }
    switch (type) {
      case _CardDecoType.online:
        ell(0.67, 0.68, 0.31, 0.29, const Color(0xFFFCE4EC), opacity: 0.95);
        ell(0.39, 0.39, 0.25, 0.25, Colors.white);
        ell(0.72, 0.32, 0.19, 0.20, const Color(0xFFF8BBD9));
      case _CardDecoType.offline:
        ell(0.61, 0.64, 0.31, 0.27, Colors.white);
        ell(0.36, 0.36, 0.22, 0.23, const Color(0xFFFFF9C4));
        ell(0.72, 0.29, 0.17, 0.18, const Color(0xFFFFE082));
      case _CardDecoType.pro:
        ell(0.43, 0.28, 0.22, 0.14, Colors.white, opacity: 0.9);
        ell(0.65, 0.58, 0.30, 0.24, const Color(0xFF42A5F5), opacity: 0.65);
        ell(0.50, 0.78, 0.22, 0.16, const Color(0xFF64B5F6), opacity: 0.55);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ═════════════════════════════════════════════════════════════════════════════
//  顶层 Tab 文字
// ═════════════════════════════════════════════════════════════════════════════

// ═════════════════════════════════════════════════════════════════════════════
//  搭子局卡片
// ═════════════════════════════════════════════════════════════════════════════

class _GatherCard extends StatelessWidget {
  const _GatherCard({required this.item, required this.onTap});
  final Gather item;
  final VoidCallback onTap;

  String _fmtDate(DateTime dt) {
    final mo = dt.month.toString().padLeft(2, '0');
    final d  = dt.day.toString().padLeft(2, '0');
    return '${dt.year}年${mo}月${d}日';
  }

  String _fmtTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  // 同一天 → 显示"4月18日 15:56 - 17:56"；跨天 → 显示完整开始时间
  String _fmtRange(DateTime start, DateTime end) {
    final sameDay = start.year == end.year && start.month == end.month && start.day == end.day;
    if (sameDay) return '${_fmtDate(start)}  ${_fmtTime(start)} - ${_fmtTime(end)}';
    return '${_fmtDate(start)} ${_fmtTime(start)}';
  }

  @override
  Widget build(BuildContext context) {
    final color = item.themeColor;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFEDE5DA), width: 0.5),
          boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 6, offset: Offset(0, 2))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // ── 标题行 + 主题标签 ─────────────────────────────────────────
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: Text(item.title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A), height: 1.35)),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color.withAlpha(20),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color.withAlpha(80), width: 0.8),
              ),
              child: Text(item.buddyTag,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: color)),
            ),
          ]),
          const SizedBox(height: 12),
          // ── 地点 ─────────────────────────────────────────────────────
          if (item.location != null) ...[
            Row(children: [
              const Icon(Icons.location_on, size: 14, color: Color(0xFFE24B4A)),
              const SizedBox(width: 6),
              Expanded(child: Text(item.location!,
                  style: const TextStyle(fontSize: 13, color: Color(0xFF555555)),
                  maxLines: 1, overflow: TextOverflow.ellipsis)),
            ]),
            const SizedBox(height: 8),
          ],
          // ── 时间 ─────────────────────────────────────────────────────
          Row(children: [
            const Icon(Icons.access_time, size: 14, color: Color(0xFF4ADE80)),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                _fmtRange(item.startTime, item.endTime),
                style: const TextStyle(fontSize: 13, color: Color(0xFF555555)),
                maxLines: 1, overflow: TextOverflow.ellipsis,
              ),
            ),
          ]),
          const SizedBox(height: 14),
          // ── 底部：头像 + 人数 + 参加按钮 ─────────────────────────────
          Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            // 头像叠加
            if (item.memberAvatars.isNotEmpty)
              SizedBox(
                height: 28,
                width: item.memberAvatars.length * 20.0 + 8,
                child: Stack(children: List.generate(item.memberAvatars.length, (i) => Positioned(
                  left: i * 20.0,
                  child: Container(
                    width: 28, height: 28,
                    decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                    child: ClipOval(child: PmImage(item.memberAvatars[i], width: 28, height: 28, fit: BoxFit.cover)),
                  ),
                ))),
              ),
            if (item.memberAvatars.isNotEmpty) const SizedBox(width: 8),
            Text('${item.joinedCount}/${item.capacity} 人参加',
                style: const TextStyle(fontSize: 12, color: Color(0xFF888888))),
            const Spacer(),
            // 参加按钮
            GestureDetector(
              onTap: item.isFull ? null : onTap,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: item.isFull ? const Color(0xFFF0ECE6) : const Color(0xFFFF7A00),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  item.isFull ? '已满' : '参加',
                  style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600,
                    color: item.isFull ? const Color(0xFFC8BFB5) : Colors.white,
                  ),
                ),
              ),
            ),
          ]),
        ]),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  搭子人物数据模型 + 卡片
// ═════════════════════════════════════════════════════════════════════════════

class _BuddyPerson {
  const _BuddyPerson({required this.name, required this.age, required this.city, required this.avatar, required this.desc, required this.tag});
  final String name;
  final int age;
  final String city;
  final String avatar;
  final String desc;
  final String tag;
}

class _BuddyPersonCard extends StatelessWidget {
  const _BuddyPersonCard({required this.data});
  final _BuddyPerson data;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/buddy/user/mock_person'),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEDE5DA), width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 3:4 cover image ──────────────────────────────────────────
            AspectRatio(
              aspectRatio: 3 / 4,
              child: Stack(fit: StackFit.expand, children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: PmImage(data.avatar, fit: BoxFit.cover, width: double.infinity),
                ),
                Positioned(
                  top: 9, left: 9,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF8C42).withAlpha(230),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(data.tag, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: Colors.white)),
                  ),
                ),
              ]),
            ),
            // ── Body ─────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(11, 10, 11, 12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Name + age
                Row(children: [
                  Text(data.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF222222))),
                  const SizedBox(width: 5),
                  Text('${data.age}岁', style: const TextStyle(fontSize: 12, color: Color(0xFF999999))),
                ]),
                const SizedBox(height: 3),
                // Location
                Row(children: [
                  const Icon(Icons.location_on_outlined, size: 10, color: Color(0xFFC8BFB5)),
                  const SizedBox(width: 3),
                  Text(data.city, style: const TextStyle(fontSize: 11, color: Color(0xFFC8BFB5))),
                ]),
                const SizedBox(height: 6),
                // Description (2 lines)
                Text(data.desc,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF999999), height: 1.45),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 9),
                // Invite button
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () {},
                    style: TextButton.styleFrom(
                      backgroundColor: const Color(0xFFFF8C42),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('邀约', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                  ),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  原有 Feed 卡片（搭子 Tab 用）
// ═════════════════════════════════════════════════════════════════════════════

class _OrigFeedData {
  const _OrigFeedData(this.title, this.price, this.status, this.imageUrl);
  final String title;
  final String price;
  final String status;
  final String imageUrl;
}

class _OrigFeedCard extends StatelessWidget {
  const _OrigFeedCard({required this.data});
  final _OrigFeedData data;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/buddy/user/mock_feed'),
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: const [BoxShadow(blurRadius: 8, color: Color(0x0D000000), offset: Offset(0, 2))]),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(16)), child: PmImage(data.imageUrl, fit: BoxFit.cover, width: double.infinity))),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(data.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF222222)), maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(data.price, style: const TextStyle(fontSize: 13, color: Color(0xFFFF6700), fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(data.status, style: const TextStyle(fontSize: 10, color: Color(0xFF999999))),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  搭子局详情弹窗
// ═════════════════════════════════════════════════════════════════════════════

class _GatherDetailSheet extends ConsumerWidget {
  const _GatherDetailSheet({required this.item, required this.firstMenuId});
  final Gather item;
  final int? firstMenuId;

  String _fmtTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  String _fmtDate(DateTime dt) =>
      '${dt.year}年${dt.month.toString().padLeft(2, '0')}月${dt.day.toString().padLeft(2, '0')}日';

  // 时间区间：同一天 → 一行显示"4月18日 15:56 - 17:56"；跨天 → 各自完整
  Widget _buildTimeRange(DateTime start, DateTime end) {
    final sameDay = start.year == end.year &&
        start.month == end.month &&
        start.day == end.day;
    if (sameDay) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.play_circle_outline, size: 20, color: Color(0xFF5DCAA5)),
            const SizedBox(width: 10),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('活动时间', style: TextStyle(fontSize: 12, color: Color(0xFF999999))),
              const SizedBox(height: 2),
              Text(
                '${_fmtDate(start)}  ${_fmtTime(start)} - ${_fmtTime(end)}',
                style: const TextStyle(fontSize: 14, color: Color(0xFF333333), fontWeight: FontWeight.w500),
              ),
            ]),
          ]),
        ],
      );
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _DetailRow(icon: Icons.play_circle_outline, iconColor: const Color(0xFF5DCAA5), label: '开始时间', value: '${_fmtDate(start)} ${_fmtTime(start)}'),
      const SizedBox(height: 16),
      _DetailRow(icon: Icons.stop_circle_outlined, iconColor: const Color(0xFFE24B4A), label: '结束时间', value: '${_fmtDate(end)} ${_fmtTime(end)}'),
    ]);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topPad = MediaQuery.of(context).padding.top;
    // 优先用服务端最新数据；加载中 / 失败时回退到列表缓存或传入 item
    final detailAsync = ref.watch(gatherDetailProvider(item.id));
    final listGathers = ref.watch(gatherListProvider(firstMenuId)).valueOrNull;
    final current = detailAsync.valueOrNull
        ?? listGathers?.firstWhere((g) => g.id == item.id, orElse: () => item)
        ?? item;
    final color = current.themeColor;
    return Container(
      height: MediaQuery.of(context).size.height,
      decoration: const BoxDecoration(color: Colors.white),
      child: Column(
        children: [
          // ── 彩色渐变头部 ──────────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(20, topPad + 48, 20, 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [color, color.withValues(alpha: 0.7)],
              ),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close, color: Colors.white, size: 24),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.25), borderRadius: BorderRadius.circular(12)),
                  child: Text(current.buddyTag, style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600)),
                ),
              ]),
              const SizedBox(height: 14),
              Text(current.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
            ]),
          ),
          // ── 内容区 ────────────────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // ── 活动方式 ──────────────────────────────────────────────
                _DetailRow(
                  icon: current.activityMode == 'online'
                      ? Icons.wifi_outlined
                      : current.activityMode == 'invite'
                          ? Icons.people_outline
                          : Icons.place_outlined,
                  iconColor: current.activityMode == 'online'
                      ? const Color(0xFF2196F3)
                      : const Color(0xFFFF7A00),
                  label: '活动方式',
                  value: current.activityModeLabel,
                ),
                const SizedBox(height: 16),

                // ── 时间 ───────────────────────────────────────────────────
                _buildTimeRange(current.startTime, current.endTime),
                if (current.deadline != null) ...[
                  const SizedBox(height: 16),
                  _DetailRow(
                    icon: Icons.timer_outlined,
                    iconColor: const Color(0xFFE24B4A),
                    label: '报名截止',
                    value: '${_fmtDate(current.deadline!)} ${_fmtTime(current.deadline!)}',
                  ),
                ],
                const SizedBox(height: 16),

                // ── 地点 ───────────────────────────────────────────────────
                if (current.location != null && current.location!.isNotEmpty) ...[
                  _DetailRow(
                    icon: Icons.location_on_outlined,
                    iconColor: const Color(0xFFFF7A00),
                    label: '活动地点',
                    value: current.location!,
                  ),
                  const SizedBox(height: 16),
                ],
                if (current.landmark != null && current.landmark!.isNotEmpty) ...[
                  _DetailRow(
                    icon: Icons.near_me_outlined,
                    iconColor: const Color(0xFFAAAAAA),
                    label: '地标参考',
                    value: current.landmark!,
                  ),
                  const SizedBox(height: 16),
                ],

                // ── 参与信息 ──────────────────────────────────────────────
                _DetailRow(
                  icon: Icons.payments_outlined,
                  iconColor: const Color(0xFF5DCAA5),
                  label: '费用',
                  value: current.feeLabel,
                ),
                const SizedBox(height: 16),
                _DetailRow(
                  icon: Icons.person_outline,
                  iconColor: const Color(0xFF9C27B0),
                  label: '适合人群',
                  value: '${current.ageMin}–${current.ageMax} 岁 · ${['不限', '男生优先', '女生优先'][current.genderPref]}',
                ),
                const SizedBox(height: 16),

                // ── 活动说明 ──────────────────────────────────────────────
                if (current.description != null && current.description!.isNotEmpty) ...[
                  _DetailRow(
                    icon: Icons.notes_outlined,
                    iconColor: const Color(0xFF9C27B0),
                    label: '活动说明',
                    value: current.description!,
                  ),
                  const SizedBox(height: 16),
                ],

                // ── 行程安排 ──────────────────────────────────────────────
                if (current.schedule != null && current.schedule!.isNotEmpty) ...[
                  _DetailRow(
                    icon: Icons.format_list_bulleted_outlined,
                    iconColor: const Color(0xFF2196F3),
                    label: '行程安排',
                    value: current.schedule!,
                  ),
                  const SizedBox(height: 16),
                ],

                // ── 氛围标签 ──────────────────────────────────────────────
                if (current.vibes.isNotEmpty) ...[
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: current.vibes.map((v) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3E8),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFFDDB0)),
                      ),
                      child: Text(v, style: const TextStyle(fontSize: 12, color: Color(0xFFFF7A00))),
                    )).toList(),
                  ),
                  const SizedBox(height: 16),
                ],

                // ── 高级设置标记 ──────────────────────────────────────────
                if (current.requireRealName || current.requireReview || current.allowTransfer) ...[
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      if (current.requireRealName)
                        _badgeChip(Icons.badge_outlined, '需实名认证', const Color(0xFFE8F5E9), const Color(0xFF5DCAA5)),
                      if (current.requireReview)
                        _badgeChip(Icons.how_to_reg_outlined, '需审核入组', const Color(0xFFE3F2FD), const Color(0xFF2196F3)),
                      if (current.allowTransfer)
                        _badgeChip(Icons.swap_horiz_outlined, '可转让名额', const Color(0xFFF3E5F5), const Color(0xFF9C27B0)),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],

                const Text('参加的搭子', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF333333))),
                const SizedBox(height: 12),
                Row(children: [
                  // 已参加成员（有头像 → 图片；无头像 → 用户名首字母彩色圆）
                  ...List.generate(current.memberUsernames.length, (i) {
                    final username = current.memberUsernames[i];
                    final avatarUrl = i < current.memberAvatars.length ? current.memberAvatars[i] : '';
                    final initial = username.isNotEmpty ? username[0] : '?';
                    final colors = [
                      const Color(0xFF7F77DD), const Color(0xFF4ECDC4),
                      const Color(0xFFFF6B6B), const Color(0xFFFFBE0B),
                      const Color(0xFF5DCAA5),
                    ];
                    final bgColor = colors[i % colors.length];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: avatarUrl.isNotEmpty
                          ? Container(
                              width: 40, height: 40,
                              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFFEEEEEE), width: 2)),
                              child: ClipOval(child: PmImage(avatarUrl, width: 40, height: 40, fit: BoxFit.cover)),
                            )
                          : CircleAvatar(
                              radius: 20,
                              backgroundColor: bgColor,
                              child: Text(initial, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                            ),
                    );
                  }),
                  // 空余名额（最多显示 3 个）
                  ...List.generate((current.capacity - current.joinedCount).clamp(0, 3), (_) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Container(width: 40, height: 40, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFFDDDDDD), width: 1.5), color: const Color(0xFFF5F5F5)), child: const Icon(Icons.add, size: 18, color: Color(0xFFCCCCCC))),
                  )),
                ]),
                const SizedBox(height: 8),
                Text('已参加 ${current.joinedCount} 人，共 ${current.capacity} 个名额', style: const TextStyle(fontSize: 13, color: Color(0xFF888888))),
              ]),
            ),
          ),
          // ── 底部按钮 ──────────────────────────────────────────────────────
          Container(
            padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).padding.bottom + 12),
            decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Color(0xFFF0F0F0)))),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 进入群聊（已参加且有群组时显示）
                if (current.isJoined && current.groupId != null) ...[
                  SizedBox(
                    width: double.infinity, height: 44,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        context.push(
                          '/im/group/${current.groupId}',
                          extra: {
                            'groupName': current.title,
                            'memberCount': current.joinedCount,
                          },
                        );
                      },
                      icon: const Icon(Icons.chat_bubble_outline, size: 18),
                      label: const Text('进入搭子局群聊', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFFF7A00),
                        side: const BorderSide(color: Color(0xFFFF7A00)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                // 参加 / 退出按钮
                SizedBox(
                  width: double.infinity, height: 48,
                  child: ElevatedButton(
                    onPressed: current.isFull && !current.isJoined ? null : () async {
                      try {
                        if (current.isJoined) {
                          await ref.read(gatherListProvider(firstMenuId).notifier).leave(current.id);
                        } else {
                          await ref.read(gatherListProvider(firstMenuId).notifier).join(current.id);
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: current.isJoined
                          ? const Color(0xFFF0ECE6)
                          : const Color(0xFFFF7A00),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      current.isFull && !current.isJoined
                          ? '名额已满'
                          : current.isJoined
                              ? '退出搭子局'
                              : '立即参加（${current.joinedCount}/${current.capacity}）',
                      style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700,
                        color: current.isJoined ? const Color(0xFF888888) : Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _badgeChip(IconData icon, String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: fg),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 12, color: fg, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.icon, required this.iconColor, required this.label, required this.value});
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, size: 20, color: iconColor),
      const SizedBox(width: 10),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF999999))),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 14, color: Color(0xFF333333), fontWeight: FontWeight.w500)),
      ]),
    ]);
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  发起搭子局弹窗
// ═════════════════════════════════════════════════════════════════════════════

class _PublishGatherSheet extends ConsumerStatefulWidget {
  const _PublishGatherSheet({this.defaultFirstMenuId});
  final int? defaultFirstMenuId;

  @override
  ConsumerState<_PublishGatherSheet> createState() => _PublishGatherSheetState();
}

class _PublishGatherSheetState extends ConsumerState<_PublishGatherSheet> {
  // ── 步骤 ─────────────────────────────────────────────────────────────────
  int _step = 0; // 0–3

  // ── Step 1: 基本信息 ──────────────────────────────────────────────────────
  String _activityMode = 'offline'; // offline / online / invite
  int? _firstMenuId;
  int? _secondMenuId;
  final _titleCtrl = TextEditingController();
  final Set<int> _vibeSet = {};
  final _descCtrl = TextEditingController();

  // ── Step 2: 时间地点 ──────────────────────────────────────────────────────
  DateTime? _startTime;
  DateTime? _endTime;
  DateTime? _deadline;
  final _locationCtrl = TextEditingController();
  final _landmarkCtrl = TextEditingController();
  final _scheduleCtrl = TextEditingController();

  // ── Step 3: 参与设置 ──────────────────────────────────────────────────────
  int _capacity = 3;
  bool _customCapacity = false;
  final _customCapacityCtrl = TextEditingController();
  int _feeType = 0; // 0=免费 1=按需付费 2=AA制
  final _feeAmountCtrl = TextEditingController();
  int _ageMin = 18;
  int _ageMax = 35;
  int _genderPref = 0; // 0=不限 1=仅男 2=仅女
  final Set<int> _reqTagSet = {};
  bool _requireRealName = false;
  bool _requireReview = false;
  bool _allowTransfer = false;

  bool _submitting = false;

  // ── 常量 ──────────────────────────────────────────────────────────────────
  static const _vibeTags   = ['户外', '探索', '文艺', '运动', '美食', '学习'];
  static const _reqTags    = ['欢迎新手', '需有经验', '少说多做', '爱拍照', '宠物友好'];
  static const _stepLabels = ['基本信息', '时间地点', '参与设置', '确认发布'];
  static const _nextLabels = ['时间地点', '参与设置', '确认发布'];
  static const _feeLabels  = ['免费参与', '按需付费', 'AA 制'];

  @override
  void initState() {
    super.initState();
    _firstMenuId = widget.defaultFirstMenuId;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _locationCtrl.dispose();
    _landmarkCtrl.dispose();
    _scheduleCtrl.dispose();
    _customCapacityCtrl.dispose();
    _feeAmountCtrl.dispose();
    super.dispose();
  }

  // ── 步骤校验 ──────────────────────────────────────────────────────────────

  bool _validateStep() {
    switch (_step) {
      case 0:
        if (_titleCtrl.text.trim().isEmpty) { _showErr('请填写搭子局标题'); return false; }
        return true;
      case 1:
        if (_startTime == null || _endTime == null) { _showErr('请选择活动时间'); return false; }
        if (!_endTime!.isAfter(_startTime!)) { _showErr('结束时间必须晚于开始时间'); return false; }
        return true;
      default:
        return true;
    }
  }

  void _showErr(String msg) => showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      content: Text(msg, style: const TextStyle(fontSize: 14)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('知道了', style: TextStyle(color: Color(0xFFFF7A00))),
        ),
      ],
    ),
  );

  // ── 时间格式化 ────────────────────────────────────────────────────────────

  String _fmtDateTime(DateTime dt) {
    final wd = ['一','二','三','四','五','六','日'][dt.weekday - 1];
    final mo = dt.month.toString().padLeft(2, '0');
    final d  = dt.day.toString().padLeft(2, '0');
    final h  = dt.hour.toString().padLeft(2, '0');
    final m  = dt.minute.toString().padLeft(2, '0');
    return '${dt.year}/${mo}/$d (周$wd)  $h:$m';
  }

  // ── 通用时间选择器 ────────────────────────────────────────────────────────

  Future<DateTime?> _pickDT(DateTime? initial, {DateTime? firstDate}) async {
    final now  = DateTime.now();
    final base = firstDate ?? DateTime(now.year, now.month, now.day);
    final date = await showDatePicker(
      context: context,
      initialDate: initial ?? now,
      firstDate: base,
      lastDate: base.add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(colorScheme: const ColorScheme.light(primary: Color(0xFFFF7A00))),
        child: child!,
      ),
    );
    if (date == null || !mounted) return null;
    final time = await showTimePicker(
      context: context,
      initialTime: initial != null ? TimeOfDay.fromDateTime(initial) : const TimeOfDay(hour: 14, minute: 0),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(colorScheme: const ColorScheme.light(primary: Color(0xFFFF7A00))),
        child: child!,
      ),
    );
    if (time == null || !mounted) return null;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  // ── 提交 ──────────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    if (_submitting) return;
    final capacity = _customCapacity
        ? (int.tryParse(_customCapacityCtrl.text) ?? 8)
        : _capacity;
    final feeAmount = _feeType == 0 ? null : double.tryParse(_feeAmountCtrl.text);
    final vibesList = [
      ..._vibeSet.map((i) => _vibeTags[i]),
      ..._reqTagSet.map((i) => _reqTags[i]),
    ];
    setState(() => _submitting = true);
    try {
      final gather = await ref.read(gatherRepositoryProvider).createGather(
        CreateGatherRequest(
          title:           _titleCtrl.text.trim(),
          location:        _locationCtrl.text.trim().isEmpty ? null : _locationCtrl.text.trim(),
          landmark:        _landmarkCtrl.text.trim().isEmpty ? null : _landmarkCtrl.text.trim(),
          startTime:       _startTime!,
          endTime:         _endTime!,
          firstMenuId:     _firstMenuId,
          secondMenuId:    _secondMenuId,
          capacity:        capacity,
          description:     _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
          vibes:           vibesList,
          activityMode:    _activityMode,
          schedule:        _scheduleCtrl.text.trim().isEmpty ? null : _scheduleCtrl.text.trim(),
          deadline:        _deadline,
          feeType:         _feeType,
          feeAmount:       feeAmount,
          ageMin:          _ageMin,
          ageMax:          _ageMax,
          genderPref:      _genderPref,
          requireRealName: _requireRealName,
          requireReview:   _requireReview,
          allowTransfer:   _allowTransfer,
        ),
      );
      ref.read(gatherListProvider(_firstMenuId).notifier).prepend(gather);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) _showErr('发布失败：$e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // build
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      height: MediaQuery.of(context).size.height,
      color: const Color(0xFFF7F6F2),
      child: Column(
        children: [
          _buildTopBar(),
          _buildStepBar(),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(16, 16, 16, bottom + 8),
              physics: const BouncingScrollPhysics(),
              child: _buildStepBody(),
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Top bar
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildTopBar() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(4, MediaQuery.of(context).padding.top + 4, 12, 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close, size: 22, color: Color(0xFF555555)),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Text(
              '发起搭子局',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF222222)),
            ),
          ),
          const SizedBox(width: 44), // balance the close button
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Step progress bar
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildStepBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: Row(
        children: List.generate(_stepLabels.length * 2 - 1, (i) {
          if (i.isOdd) {
            // connector line
            final done = _step > i ~/ 2;
            return Expanded(
              child: Container(
                height: 2,
                color: done ? const Color(0xFFFF7A00) : const Color(0xFFE8E6E0),
              ),
            );
          }
          final idx = i ~/ 2;
          final done = _step > idx;
          final active = _step == idx;
          return Column(
            children: [
              Container(
                width: 28, height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: done
                      ? const Color(0xFFFF7A00)
                      : active
                          ? const Color(0xFFFF7A00)
                          : const Color(0xFFEEEEEE),
                ),
                child: Center(
                  child: done
                      ? const Icon(Icons.check, size: 14, color: Colors.white)
                      : Text(
                          '${idx + 1}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: active ? Colors.white : const Color(0xFFAAAAAA),
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _stepLabels[idx],
                style: TextStyle(
                  fontSize: 10,
                  color: (done || active) ? const Color(0xFFFF7A00) : const Color(0xFFAAAAAA),
                  fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Step body router
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildStepBody() {
    switch (_step) {
      case 0: return _buildStep1();
      case 1: return _buildStep2();
      case 2: return _buildStep3();
      default: return _buildStep4();
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Bottom navigation bar
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildBottomBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFF0F0F0))),
      ),
      child: Row(
        children: [
          // Left button: cancel (step 0) or prev
          if (_step == 0)
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFDDDDDD)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('取消', style: TextStyle(fontSize: 15, color: Color(0xFF888888))),
              ),
            )
          else
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _step--),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFFF7A00)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('上一步', style: TextStyle(fontSize: 15, color: Color(0xFFFF7A00))),
              ),
            ),
          const SizedBox(width: 12),
          // Right button: next or submit
          Expanded(
            flex: 2,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFFFF9A3C), Color(0xFFFF6B00)]),
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF7A00).withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _submitting ? null : () {
                  if (_step < 3) {
                    if (_validateStep()) setState(() => _step++);
                  } else {
                    _submit();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _submitting
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(
                        _step < 3 ? '下一步：${_nextLabels[_step]}' : '发布搭子局',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Step 1: 基本信息
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildStep1() {
    final menusAsync = ref.watch(menusProvider);
    final menus = menusAsync.valueOrNull ?? [];
    final selectedMenu = _firstMenuId == null
        ? null
        : menus.where((m) => m.id == _firstMenuId).firstOrNull;
    final subItems = selectedMenu?.children ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Activity type (activity mode)
        _StepCard(
          label: '活动类型',
          child: Row(
            children: [
              _buildModeBtn(label: '线下局', icon: Icons.place_outlined, value: 'offline'),
              const SizedBox(width: 8),
              _buildModeBtn(label: '线上局', icon: Icons.wifi_outlined, value: 'online'),
              const SizedBox(width: 8),
              _buildModeBtn(label: '约人局', icon: Icons.people_outline, value: 'invite'),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Title
        _StepCard(
          label: '活动标题 *',
          child: TextField(
            controller: _titleCtrl,
            maxLength: 50,
            style: const TextStyle(fontSize: 14, color: Color(0xFF222222)),
            decoration: InputDecoration(
              hintText: '例：周末一起去爬山',
              hintStyle: const TextStyle(fontSize: 14, color: Color(0xFFBBBBBB)),
              filled: true,
              fillColor: const Color(0xFFF5F5F5),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              counterText: '',
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Category
        _StepCard(
          label: '活动分类',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (menusAsync.isLoading)
                const SizedBox(height: 32, child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFFF7A00))))
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: menus.map((m) {
                    final sel = m.id == _firstMenuId;
                    return GestureDetector(
                      onTap: () => setState(() { _firstMenuId = m.id; _secondMenuId = null; }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 120),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: sel ? const Color(0xFFFF7A00) : const Color(0xFFF0F0F0),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(m.name,
                            style: TextStyle(fontSize: 13, color: sel ? Colors.white : const Color(0xFF555555),
                                fontWeight: sel ? FontWeight.w600 : FontWeight.w400)),
                      ),
                    );
                  }).toList(),
                ),
              if (subItems.isNotEmpty) ...[
                const SizedBox(height: 10),
                const Divider(height: 1, color: Color(0xFFEEEEEE)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: subItems.map((sub) {
                    final sel = sub.id == _secondMenuId;
                    return GestureDetector(
                      onTap: () => setState(() => _secondMenuId = sel ? null : sub.id),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 120),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: sel ? const Color(0xFFFFEDD0) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: sel ? const Color(0xFFFF7A00) : const Color(0xFFDDDDDD)),
                        ),
                        child: Text(sub.name,
                            style: TextStyle(fontSize: 12, color: sel ? const Color(0xFFFF7A00) : const Color(0xFF666666),
                                fontWeight: sel ? FontWeight.w600 : FontWeight.w400)),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Vibes
        _StepCard(
          label: '氛围标签（可多选）',
          optional: true,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(_vibeTags.length, (i) {
              final sel = _vibeSet.contains(i);
              return GestureDetector(
                onTap: () => setState(() => sel ? _vibeSet.remove(i) : _vibeSet.add(i)),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: sel ? const Color(0xFFFFF0DC) : const Color(0xFFF0F0F0),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: sel ? const Color(0xFFFF7A00) : Colors.transparent),
                  ),
                  child: Text(_vibeTags[i],
                      style: TextStyle(fontSize: 13, color: sel ? const Color(0xFFFF7A00) : const Color(0xFF666666),
                          fontWeight: sel ? FontWeight.w600 : FontWeight.w400)),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 12),

        // Description
        _StepCard(
          label: '活动说明',
          optional: true,
          child: TextField(
            controller: _descCtrl,
            maxLines: 4,
            maxLength: 500,
            style: const TextStyle(fontSize: 14, color: Color(0xFF222222)),
            decoration: InputDecoration(
              hintText: '介绍活动内容、注意事项、对参与者的要求…',
              hintStyle: const TextStyle(fontSize: 13, color: Color(0xFFBBBBBB)),
              filled: true,
              fillColor: const Color(0xFFF5F5F5),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              counterStyle: const TextStyle(fontSize: 11, color: Color(0xFFBBBBBB)),
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildModeBtn({required String label, required IconData icon, required String value}) {
    final sel = _activityMode == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activityMode = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: sel ? const Color(0xFFFF7A00) : const Color(0xFFF0F0F0),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: sel ? const Color(0xFFFF7A00) : const Color(0xFFDDDDDD)),
          ),
          child: Column(
            children: [
              Icon(icon, size: 20, color: sel ? Colors.white : const Color(0xFF888888)),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(fontSize: 12, color: sel ? Colors.white : const Color(0xFF666666),
                  fontWeight: sel ? FontWeight.w600 : FontWeight.w400)),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Step 2: 时间地点
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Times
        _StepCard(
          label: '活动时间 *',
          child: Column(
            children: [
              _buildTimePickerRow(
                label: '开始时间',
                value: _startTime,
                onTap: () async {
                  final dt = await _pickDT(_startTime);
                  if (dt != null) setState(() => _startTime = dt);
                },
              ),
              const SizedBox(height: 8),
              _buildTimePickerRow(
                label: '结束时间',
                value: _endTime,
                onTap: () async {
                  final dt = await _pickDT(_endTime, firstDate: _startTime);
                  if (dt != null) setState(() => _endTime = dt);
                },
              ),
              const SizedBox(height: 8),
              _buildTimePickerRow(
                label: '报名截止',
                value: _deadline,
                optional: true,
                onTap: () async {
                  final dt = await _pickDT(_deadline);
                  if (dt != null) setState(() => _deadline = dt);
                },
                onClear: _deadline != null ? () => setState(() => _deadline = null) : null,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Location (only for offline / invite)
        if (_activityMode != 'online') ...[
          _StepCard(
            label: '活动地点',
            optional: _activityMode == 'invite',
            child: Column(
              children: [
                TextField(
                  controller: _locationCtrl,
                  style: const TextStyle(fontSize: 14, color: Color(0xFF222222)),
                  decoration: InputDecoration(
                    hintText: '详细地址，例：上海市静安区XXXX',
                    hintStyle: const TextStyle(fontSize: 13, color: Color(0xFFBBBBBB)),
                    filled: true,
                    fillColor: const Color(0xFFF5F5F5),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                    prefixIcon: const Icon(Icons.place_outlined, size: 18, color: Color(0xFFFF7A00)),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _landmarkCtrl,
                  style: const TextStyle(fontSize: 14, color: Color(0xFF222222)),
                  decoration: InputDecoration(
                    hintText: '标志性建筑，例：地铁1号线A口向东100m',
                    hintStyle: const TextStyle(fontSize: 13, color: Color(0xFFBBBBBB)),
                    filled: true,
                    fillColor: const Color(0xFFF5F5F5),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                    prefixIcon: const Icon(Icons.near_me_outlined, size: 18, color: Color(0xFFAAAAAA)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Schedule / itinerary
        _StepCard(
          label: '行程安排',
          optional: true,
          child: TextField(
            controller: _scheduleCtrl,
            maxLines: 5,
            style: const TextStyle(fontSize: 14, color: Color(0xFF222222)),
            decoration: InputDecoration(
              hintText: '14:00 在地铁站集合\n14:30 出发去XX公园\n16:00 自由活动…',
              hintStyle: const TextStyle(fontSize: 13, color: Color(0xFFBBBBBB)),
              filled: true,
              fillColor: const Color(0xFFF5F5F5),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildTimePickerRow({
    required String label,
    required DateTime? value,
    required VoidCallback onTap,
    bool optional = false,
    VoidCallback? onClear,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Text('$label${optional ? ' (可选)' : ''}  ',
                style: const TextStyle(fontSize: 12, color: Color(0xFF999999))),
            Expanded(
              child: Text(
                value != null ? _fmtDateTime(value) : '点击选择',
                style: TextStyle(
                  fontSize: 13,
                  color: value != null ? const Color(0xFF333333) : const Color(0xFFBBBBBB),
                ),
              ),
            ),
            if (value != null && onClear != null)
              GestureDetector(
                onTap: onClear,
                child: const Icon(Icons.close, size: 16, color: Color(0xFFCCCCCC)),
              )
            else
              const Icon(Icons.chevron_right, size: 16, color: Color(0xFFCCCCCC)),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Step 3: 参与设置
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Capacity
        _StepCard(
          label: '参与人数 *',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ...[3, 5, 8, 10].map((n) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _buildCapBtn(label: '$n人', selected: !_customCapacity && _capacity == n,
                        onTap: () => setState(() { _capacity = n; _customCapacity = false; })),
                  )),
                  _buildCapBtn(label: '自定义', selected: _customCapacity,
                      onTap: () => setState(() => _customCapacity = true)),
                ],
              ),
              if (_customCapacity) ...[
                const SizedBox(height: 10),
                SizedBox(
                  width: 120,
                  child: TextField(
                    controller: _customCapacityCtrl,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: '2–50',
                      hintStyle: const TextStyle(fontSize: 13, color: Color(0xFFBBBBBB)),
                      filled: true,
                      fillColor: const Color(0xFFF5F5F5),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      isDense: true,
                      suffixText: '人',
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Fee
        _StepCard(
          label: '费用设置',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: List.generate(_feeLabels.length, (i) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _buildCapBtn(
                    label: _feeLabels[i],
                    selected: _feeType == i,
                    onTap: () => setState(() => _feeType = i),
                  ),
                )),
              ),
              if (_feeType == 1) ...[
                const SizedBox(height: 10),
                SizedBox(
                  width: 160,
                  child: TextField(
                    controller: _feeAmountCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: '金额',
                      filled: true,
                      fillColor: const Color(0xFFF5F5F5),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      isDense: true,
                      prefixText: '¥  ',
                      suffixText: '/人',
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Age range
        _StepCard(
          label: '年龄范围',
          child: Row(
            children: [
              _buildAgeField(value: _ageMin, onChanged: (v) => setState(() => _ageMin = v)),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text('–', style: TextStyle(fontSize: 16, color: Color(0xFF888888))),
              ),
              _buildAgeField(value: _ageMax, onChanged: (v) => setState(() => _ageMax = v)),
              const SizedBox(width: 8),
              const Text('岁', style: TextStyle(fontSize: 13, color: Color(0xFF888888))),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Gender preference
        _StepCard(
          label: '性别偏好',
          child: Row(
            children: [
              _buildGenderBtn(label: '不限', value: 0),
              const SizedBox(width: 8),
              _buildGenderBtn(label: '男生优先', value: 1),
              const SizedBox(width: 8),
              _buildGenderBtn(label: '女生优先', value: 2),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Requirement tags
        _StepCard(
          label: '参与要求',
          optional: true,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(_reqTags.length, (i) {
              final sel = _reqTagSet.contains(i);
              return GestureDetector(
                onTap: () => setState(() => sel ? _reqTagSet.remove(i) : _reqTagSet.add(i)),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: sel ? const Color(0xFFFFF0DC) : const Color(0xFFF0F0F0),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: sel ? const Color(0xFFFF7A00) : Colors.transparent),
                  ),
                  child: Text(_reqTags[i],
                      style: TextStyle(fontSize: 13, color: sel ? const Color(0xFFFF7A00) : const Color(0xFF666666),
                          fontWeight: sel ? FontWeight.w600 : FontWeight.w400)),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 12),

        // Toggles
        _StepCard(
          label: '高级设置',
          optional: true,
          child: Column(
            children: [
              _buildToggleRow(
                icon: Icons.badge_outlined,
                label: '需要实名认证',
                sub: '参与者需完成实名',
                value: _requireRealName,
                onChanged: (v) => setState(() => _requireRealName = v),
              ),
              const Divider(height: 20, thickness: 0.5, color: Color(0xFFF0F0F0)),
              _buildToggleRow(
                icon: Icons.how_to_reg_outlined,
                label: '需要审核加入',
                sub: '你来确认每位申请者',
                value: _requireReview,
                onChanged: (v) => setState(() => _requireReview = v),
              ),
              const Divider(height: 20, thickness: 0.5, color: Color(0xFFF0F0F0)),
              _buildToggleRow(
                icon: Icons.swap_horiz_outlined,
                label: '允许转让名额',
                sub: '参与者可以把名额转给他人',
                value: _allowTransfer,
                onChanged: (v) => setState(() => _allowTransfer = v),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildCapBtn({required String label, required bool selected, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFF7A00) : const Color(0xFFF0F0F0),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: TextStyle(fontSize: 13, color: selected ? Colors.white : const Color(0xFF555555),
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400)),
      ),
    );
  }

  Widget _buildAgeField({required int value, required ValueChanged<int> onChanged}) {
    return SizedBox(
      width: 64,
      child: TextField(
        controller: TextEditingController(text: '$value'),
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 14),
        onChanged: (s) {
          final v = int.tryParse(s);
          if (v != null && v >= 18 && v <= 35) onChanged(v);
        },
        decoration: InputDecoration(
          filled: true,
          fillColor: const Color(0xFFF5F5F5),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          isDense: true,
        ),
      ),
    );
  }

  Widget _buildGenderBtn({required String label, required int value}) {
    final sel = _genderPref == value;
    return GestureDetector(
      onTap: () => setState(() => _genderPref = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: sel ? const Color(0xFFFF7A00) : const Color(0xFFF0F0F0),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: TextStyle(fontSize: 13, color: sel ? Colors.white : const Color(0xFF555555),
                fontWeight: sel ? FontWeight.w600 : FontWeight.w400)),
      ),
    );
  }

  Widget _buildToggleRow({
    required IconData icon,
    required String label,
    required String sub,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFFFF7A00)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF333333))),
              Text(sub, style: const TextStyle(fontSize: 11, color: Color(0xFFAAAAAA))),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: const Color(0xFFFF7A00),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Step 4: 确认发布
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildStep4() {
    final capacity = _customCapacity
        ? (int.tryParse(_customCapacityCtrl.text) ?? _capacity)
        : _capacity;
    final menusAsync = ref.read(menusProvider);
    final menus = menusAsync.valueOrNull ?? [];
    final firstMenuName = menus.where((m) => m.id == _firstMenuId).firstOrNull?.name;
    final subItems = menus.where((m) => m.id == _firstMenuId).firstOrNull?.children ?? [];
    final secondMenuName = subItems.where((s) => s.id == _secondMenuId).firstOrNull?.name;

    final modeLabel = const {'offline': '线下局', 'online': '线上局', 'invite': '约人局'}[_activityMode] ?? '线下局';
    final feeLabel = _feeType == 0
        ? '免费'
        : _feeType == 2
            ? 'AA 制'
            : (_feeAmountCtrl.text.isNotEmpty ? '¥${_feeAmountCtrl.text}/人' : '按需付费');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Preview card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF7A00),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(modeLabel, style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600)),
                  ),
                  if (secondMenuName != null) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEDD0),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text('${secondMenuName}搭子',
                          style: const TextStyle(fontSize: 11, color: Color(0xFFFF7A00), fontWeight: FontWeight.w500)),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 10),
              Text(
                _titleCtrl.text.isEmpty ? '（未填写标题）' : _titleCtrl.text,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF222222)),
              ),
              const SizedBox(height: 12),
              if (_startTime != null)
                _buildPvInfoRow(Icons.schedule_outlined, _fmtDateTime(_startTime!)),
              if (_activityMode != 'online' && _locationCtrl.text.isNotEmpty)
                _buildPvInfoRow(Icons.place_outlined, _locationCtrl.text),
              _buildPvInfoRow(Icons.people_outline, '$capacity 人'),
              _buildPvInfoRow(Icons.payments_outlined, feeLabel),
              _buildPvInfoRow(Icons.person_outline, '${_ageMin}–${_ageMax} 岁 · ${['不限', '男生优先', '女生优先'][_genderPref]}'),
              if (firstMenuName != null)
                _buildPvInfoRow(Icons.category_outlined, firstMenuName),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Checklist
        _StepCard(
          label: '发布前检查',
          child: Column(
            children: [
              _buildCheckItem('活动标题已填写', _titleCtrl.text.trim().isNotEmpty),
              _buildCheckItem('开始时间已设置', _startTime != null),
              _buildCheckItem('结束时间已设置', _endTime != null),
              _buildCheckItem('时间顺序正确', _startTime != null && _endTime != null && _endTime!.isAfter(_startTime!)),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Notice
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF8EC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFFFE0A0)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Icon(Icons.info_outline, size: 16, color: Color(0xFFFF9A3C)),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  '发布后其他用户即可看到并申请参加。请确保信息准确，违规内容将被下架。',
                  style: TextStyle(fontSize: 12, color: Color(0xFF888888), height: 1.5),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildPvInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 14, color: const Color(0xFFAAAAAA)),
          const SizedBox(width: 6),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 12, color: Color(0xFF666666)))),
        ],
      ),
    );
  }

  Widget _buildCheckItem(String label, bool ok) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(ok ? Icons.check_circle : Icons.radio_button_unchecked,
              size: 16, color: ok ? const Color(0xFF5DCAA5) : const Color(0xFFCCCCCC)),
          const SizedBox(width: 8),
          Text(label,
              style: TextStyle(fontSize: 13, color: ok ? const Color(0xFF333333) : const Color(0xFFAAAAAA))),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 步骤卡片容器
// ─────────────────────────────────────────────────────────────────────────────

class _StepCard extends StatelessWidget {
  const _StepCard({required this.label, required this.child, this.optional = false});

  final String label;
  final Widget child;
  final bool optional;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(label,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF555555))),
              if (optional) ...[
                const SizedBox(width: 4),
                const Text('可选', style: TextStyle(fontSize: 11, color: Color(0xFFBBBBBB))),
              ],
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 表单行通用容器
// ─────────────────────────────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  const _Section({
    required this.iconBg,
    required this.icon,
    required this.label,
    required this.child,
    this.optional = false,
  });

  final Color iconBg;
  final String icon;
  final String label;
  final Widget child;
  final bool optional;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
              child: Center(child: Text(icon, style: const TextStyle(fontSize: 14))),
            ),
            const SizedBox(width: 8),
            Text(label,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF333333))),
            if (optional) ...[
              const SizedBox(width: 6),
              const Text('(可选)',
                  style: TextStyle(fontSize: 11, color: Color(0xFFAAAAAA))),
            ],
          ],
        ),
        const SizedBox(height: 10),
        child,
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  搜索结果：用户卡片
// ═════════════════════════════════════════════════════════════════════════════

class _SearchUserCard extends StatelessWidget {
  const _SearchUserCard({required this.user, this.onTap, this.onChat});
  final SearchUser user;
  final VoidCallback? onTap;
  final VoidCallback? onChat;

  // 根据 id 哈希取固定颜色，避免每次渲染跳色
  static const _colors = [
    Color(0xFFFF8C42), Color(0xFF5DCAA5), Color(0xFF7F77DD),
    Color(0xFFFF6B6B), Color(0xFFFFBE0B), Color(0xFF06D6A0),
  ];
  Color _avatarColor() => _colors[user.id.hashCode.abs() % _colors.length];

  @override
  Widget build(BuildContext context) {
    final tags = user.tags.take(3).toList();
    final desc = user.bio?.isNotEmpty == true ? user.bio! : '期待与你相遇';
    final meta = user.city ?? '未知城市';

    return GestureDetector(
      onTap: onTap,
      child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06), width: 0.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 头像
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: user.avatarUrl != null
                ? PmImage(user.avatarUrl!, width: 52, height: 52, fit: BoxFit.cover)
                : Container(
                    width: 52, height: 52,
                    color: _avatarColor(),
                    child: Center(
                      child: Text(
                        user.username.isNotEmpty ? user.username[0].toUpperCase() : '?',
                        style: const TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(user.username,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF2C2C2A))),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF7ED),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFFF8C42).withValues(alpha: 0.25), width: 0.5),
                      ),
                      child: const Text('搭子', style: TextStyle(fontSize: 11, color: Color(0xFFFF8C42))),
                    ),
                  ],
                ),
                if (tags.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 5,
                    children: tags.map((t) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(t, style: const TextStyle(fontSize: 11, color: Color(0xFF888780))),
                    )).toList(),
                  ),
                ],
                const SizedBox(height: 5),
                Text(desc,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF888780), height: 1.4),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(meta, style: const TextStyle(fontSize: 11, color: Color(0xFFBBBBBB))),
                    const Spacer(),
                    GestureDetector(
                      onTap: onChat,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                        decoration: BoxDecoration(color: const Color(0xFFFF8C42), borderRadius: BorderRadius.circular(10)),
                        child: const Text('打招呼', style: TextStyle(fontSize: 12, color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  搜索结果：搭子局卡片
// ═════════════════════════════════════════════════════════════════════════════

class _SearchGatherCard extends StatelessWidget {
  const _SearchGatherCard({required this.gather, this.onTap});
  final Gather gather;
  final VoidCallback? onTap;

  static const _memberBgColors = [
    Color(0xFFFDE68A), Color(0xFFD9F99D), Color(0xFFBFDBFE),
    Color(0xFFFECDD3), Color(0xFFC7D2FE),
  ];

  @override
  Widget build(BuildContext context) {
    final dateStr = '${gather.startTime.month}月${gather.startTime.day}日 '
        '${gather.startTime.hour.toString().padLeft(2, '0')}:'
        '${gather.startTime.minute.toString().padLeft(2, '0')}';
    final tag  = gather.vibes.isNotEmpty ? gather.vibes.first : gather.buddyTag;
    final extra = gather.location != null ? ' · ${gather.location}' : '';
    final remaining = gather.capacity - gather.joinedCount;

    return GestureDetector(
      onTap: onTap,
      child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text('${gather.title} · $dateStr',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF2C2C2A)),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(width: 8),
              Text('${gather.joinedCount}/${gather.capacity} 人',
                  style: const TextStyle(fontSize: 11, color: Color(0xFFBBBBBB))),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(color: const Color(0xFFFFF7ED), borderRadius: BorderRadius.circular(8)),
                child: Text(tag, style: const TextStyle(fontSize: 11, color: Color(0xFFFF8C42))),
              ),
              if (extra.isNotEmpty) ...[
                const SizedBox(width: 8),
                Expanded(child: Text(extra, style: const TextStyle(fontSize: 11, color: Color(0xFFBBBBBB)), maxLines: 1, overflow: TextOverflow.ellipsis)),
              ],
            ],
          ),
          if (gather.description != null) ...[
            const SizedBox(height: 6),
            Text(gather.description!,
                style: const TextStyle(fontSize: 12, color: Color(0xFF888780), height: 1.4),
                maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              // 成员头像堆叠
              SizedBox(
                height: 26,
                width: (gather.memberUsernames.take(4).length * 18 + 8).toDouble(),
                child: Stack(
                  children: gather.memberUsernames.take(4).toList().asMap().entries.map((e) {
                    final av = e.key < gather.memberAvatars.length ? gather.memberAvatars[e.key] : '';
                    return Positioned(
                      left: e.key * 18.0,
                      child: Container(
                        width: 24, height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          color: _memberBgColors[e.key % _memberBgColors.length],
                        ),
                        child: av.isNotEmpty
                            ? ClipOval(child: PmImage(av, width: 24, height: 24, fit: BoxFit.cover))
                            : Center(
                                child: Text(
                                  e.value.isNotEmpty ? e.value[0].toUpperCase() : '?',
                                  style: const TextStyle(fontSize: 9, color: Colors.white),
                                ),
                              ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(width: 8),
              Text('还差 $remaining 人', style: const TextStyle(fontSize: 11, color: Color(0xFFBBBBBB))),
              const Spacer(),
              GestureDetector(
                onTap: gather.isFull ? null : onTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: gather.isFull ? const Color(0xFFF0F0F0) : const Color(0xFFFF8C42),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(gather.isFull ? '已满员' : '我要加入',
                      style: TextStyle(fontSize: 12, color: gather.isFull ? const Color(0xFF999999) : Colors.white)),
                ),
              ),
            ],
          ),
        ],
      ),
      ),
    );
  }
}
