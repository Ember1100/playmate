import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/pm_image.dart';
import '../../../../core/api/api_client.dart';
import '../../data/im_model.dart';
import '../../data/websocket_service.dart';
import '../../providers/im_provider.dart';

class ImScreen extends ConsumerStatefulWidget {
  const ImScreen({super.key});

  @override
  ConsumerState<ImScreen> createState() => _ImScreenState();
}

class _ImScreenState extends ConsumerState<ImScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  // ── 编辑模式 ──────────────────────────────────────────────────────────────
  StreamSubscription<Map<String, dynamic>>? _wsSub;

  bool _editMode = false;
  final Set<String> _selected = {};

  void _toggleEdit() {
    setState(() {
      _editMode = !_editMode;
      _selected.clear();
    });
  }

  void _toggleSelect(String id) {
    setState(() {
      if (_selected.contains(id)) {
        _selected.remove(id);
      } else {
        _selected.add(id);
      }
    });
  }

  void _deleteSelected() {
    // TODO: 调用 API 删除选中会话
    ref.read(conversationsProvider.notifier).state.whenData((list) {
      ref.read(conversationsProvider.notifier).state =
          AsyncData(list.where((c) => !_selected.contains(c.id)).toList());
    });
    setState(() {
      _editMode = false;
      _selected.clear();
    });
  }

  void _markReadSelected() {
    // TODO: 调用 API 批量已读
    ref.read(conversationsProvider.notifier).state.whenData((list) {
      ref.read(conversationsProvider.notifier).state = AsyncData(
        list.map((c) => _selected.contains(c.id)
            ? Conversation(
                id: c.id, otherUserId: c.otherUserId,
                otherUsername: c.otherUsername, otherAvatarUrl: c.otherAvatarUrl,
                lastMessage: c.lastMessage, lastMessageAt: c.lastMessageAt,
                unreadCount: 0)
            : c).toList(),
      );
    });
    setState(() {
      _editMode = false;
      _selected.clear();
    });
  }

  static const _tabs = ['全部', '系统通知', '搭子邀约', '互动消息'];

  static const _avatarColors = [
    Color(0xFF7F77DD),
    Color(0xFF4ECDC4),
    Color(0xFFFF6B6B),
    Color(0xFFFFBE0B),
    Color(0xFF06D6A0),
    Color(0xFF5DCAA5),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _initWebSocket();
  }

  Future<void> _initWebSocket() async {
    final tokenStorage = ref.read(tokenStorageProvider);
    final token = await tokenStorage.getAccessToken();
    if (token == null) return;
    final wsService = ref.read(wsServiceProvider);
    await wsService.connect(token);
    _wsSub = wsService.messages.listen((data) {
      final type = data['type'] as String?;
      if (type == 'new_message') {
        ref.read(conversationsProvider.notifier).refresh();
      } else if (type == 'new_group_message') {
        ref.read(groupSessionsProvider.notifier).refresh();
      }
    });
  }

  @override
  void dispose() {
    _wsSub?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  String _formatTime(DateTime? dt) {
    if (dt == null) return '';
    final now  = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1)  return '刚刚';
    if (diff.inHours < 1)    return '${diff.inMinutes}分钟前';
    if (diff.inDays == 0)    return DateFormat('HH:mm').format(dt);
    if (diff.inDays < 7)     return ['日','一','二','三','四','五','六'][dt.weekday % 7];
    return DateFormat('MM-dd').format(dt);
  }

  // ── 通知图标 & 颜色 ────────────────────────────────────────────────────────

  IconData _notifIcon(NotificationType type) => switch (type) {
        NotificationType.system      => Icons.campaign_rounded,
        NotificationType.buddyRequest => Icons.person_add_rounded,
        NotificationType.invitation  => Icons.group_add_rounded,
        NotificationType.interaction => Icons.favorite_rounded,
      };

  Color _notifColor(NotificationType type) => switch (type) {
        NotificationType.system      => const Color(0xFFFF9800),
        NotificationType.buddyRequest => const Color(0xFF5DCAA5),
        NotificationType.invitation  => const Color(0xFF7F77DD),
        NotificationType.interaction => const Color(0xFFE24B4A),
      };

  // ── 构建方法 ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final conversationsAsync  = ref.watch(conversationsProvider);
    final groupSessionsAsync  = ref.watch(groupSessionsProvider);
    final notificationsAsync  = ref.watch(notificationsProvider);

    final notifs = notificationsAsync.valueOrNull ?? [];
    final systemUnread   = notifs.where((n) => n.type == NotificationType.system && !n.isRead).length;
    final buddyUnread    = notifs.where((n) => (n.type == NotificationType.buddyRequest || n.type == NotificationType.invitation) && !n.isRead).length;
    final interactUnread = notifs.where((n) => n.type == NotificationType.interaction && !n.isRead).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text('消息'),
        actions: [
          TextButton(
            onPressed: _toggleEdit,
            child: Text(
              _editMode ? '完成' : '编辑',
              style: const TextStyle(color: AppColors.primary),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable:         true,
          tabAlignment:         TabAlignment.start,
          labelColor:           AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor:       AppColors.primary,
          indicatorSize:        TabBarIndicatorSize.label,
          labelStyle:           const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontSize: 13),
          tabs: [
            Tab(text: _tabs[0]),
            _BadgeTab(label: _tabs[1], count: systemUnread),
            _BadgeTab(label: _tabs[2], count: buddyUnread),
            _BadgeTab(label: _tabs[3], count: interactUnread),
          ],
        ),
      ),
      bottomNavigationBar: _editMode
          ? SafeArea(
              child: Container(
                height: 56,
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  border: Border(top: BorderSide(color: AppColors.border)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton.icon(
                        onPressed: _selected.isEmpty ? null : _markReadSelected,
                        icon: const Icon(Icons.done_all_rounded, size: 18),
                        label: const Text('标记已读'),
                        style: TextButton.styleFrom(
                          foregroundColor: _selected.isEmpty
                              ? AppColors.textSecondary
                              : AppColors.primary,
                        ),
                      ),
                    ),
                    const VerticalDivider(width: 1, indent: 12, endIndent: 12),
                    Expanded(
                      child: TextButton.icon(
                        onPressed: _selected.isEmpty ? null : _deleteSelected,
                        icon: const Icon(Icons.delete_outline_rounded, size: 18),
                        label: const Text('删除'),
                        style: TextButton.styleFrom(
                          foregroundColor: _selected.isEmpty
                              ? AppColors.textSecondary
                              : AppColors.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
      body: TabBarView(
        controller: _tabController,
        children: [
          // ── 全部 ──────────────────────────────────────────────────────────
          _buildAllTab(conversationsAsync, groupSessionsAsync, notifs),

          // ── 系统通知 ───────────────────────────────────────────────────────
          _buildNotifList(
            notifs.where((n) => n.type == NotificationType.system).toList(),
            emptyText: '暂无系统通知',
            emptyIcon: Icons.notifications_none_rounded,
          ),

          // ── 搭子邀约 ───────────────────────────────────────────────────────
          _buildNotifList(
            notifs.where((n) => n.type == NotificationType.buddyRequest || n.type == NotificationType.invitation).toList(),
            emptyText: '暂无搭子邀约',
            emptyIcon: Icons.people_outline_rounded,
          ),

          // ── 互动消息 ───────────────────────────────────────────────────────
          _buildNotifList(
            notifs.where((n) => n.type == NotificationType.interaction).toList(),
            emptyText: '暂无互动消息',
            emptyIcon: Icons.favorite_border_rounded,
          ),
        ],
      ),
    );
  }

  // ── 全部 Tab ────────────────────────────────────────────────────────────────

  Widget _buildAllTab(
    AsyncValue<List<Conversation>> convsAsync,
    AsyncValue<List<GroupSession>> groupsAsync,
    List<AppNotification> notifs,
  ) {
    final convs   = convsAsync.valueOrNull  ?? [];
    final groups  = groupsAsync.valueOrNull ?? [];
    final systemUnread   = notifs.where((n) => n.type == NotificationType.system && !n.isRead).length;
    final buddyUnread    = notifs.where((n) => (n.type == NotificationType.buddyRequest || n.type == NotificationType.invitation) && !n.isRead).length;
    final interactUnread = notifs.where((n) => n.type == NotificationType.interaction && !n.isRead).length;

    // 合并并按时间排序
    final sessions = <_SessionItem>[
      ...convs.map((c) => _SessionItem.fromConv(c)),
      ...groups.map((g) => _SessionItem.fromGroup(g)),
    ]..sort((a, b) {
        if (a.lastMessageAt == null) return 1;
        if (b.lastMessageAt == null) return -1;
        return b.lastMessageAt!.compareTo(a.lastMessageAt!);
      });

    return RefreshIndicator(
      onRefresh: () async {
        await Future.wait([
          ref.read(conversationsProvider.notifier).refresh(),
          ref.read(groupSessionsProvider.notifier).refresh(),
          ref.read(notificationsProvider.notifier).refresh(),
        ]);
      },
      child: ListView(
        children: [
          // 编辑模式隐藏快捷入口
          if (!_editMode) ...[
            _buildQuickEntry(systemUnread, buddyUnread, interactUnread),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text('私信 & 群聊',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ),
          ],
          if (sessions.isEmpty)
            const _EmptyHint(icon: Icons.chat_bubble_outline, text: '暂无消息，去找个搭伴聊聊吧')
          else
            ...sessions.asMap().entries.map((e) => _buildSessionItem(e.key, e.value)),
        ],
      ),
    );
  }

  Widget _buildQuickEntry(int systemUnread, int buddyUnread, int interactUnread) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          _QuickEntryItem(
            emoji: '🔔',
            label: '系统通知',
            bgColor: const Color(0xFFFFF0E0),
            unread: systemUnread,
            onTap: () => _tabController.animateTo(1),
          ),
          _QuickEntryItem(
            emoji: '🤝',
            label: '搭子邀约',
            bgColor: const Color(0xFFE8F4F0),
            unread: buddyUnread,
            onTap: () => _tabController.animateTo(2),
          ),
          _QuickEntryItem(
            emoji: '❤️',
            label: '互动消息',
            bgColor: const Color(0xFFFFE8E8),
            unread: interactUnread,
            onTap: () => _tabController.animateTo(3),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionItem(int index, _SessionItem item) {
    final color     = _avatarColors[index % _avatarColors.length];
    final timeStr   = _formatTime(item.lastMessageAt);
    final isChecked = _selected.contains(item.id);

    return InkWell(
      onTap: () {
        if (_editMode) {
          _toggleSelect(item.id);
          return;
        }
        if (item.type == _SessionType.dm) {
          ref.read(conversationsProvider.notifier).clearUnread(item.id);
          context.push('/im/chat/${item.id}', extra: {
            'username': item.name,
            'otherUserId': item.otherId,
          });
        } else {
          context.push('/im/group/${item.id}', extra: {
            'groupName': item.name,
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: isChecked ? AppColors.primaryLight.withAlpha(60) : AppColors.surface,
        child: Row(
          children: [
            // 编辑模式复选框
            if (_editMode) ...[
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 24, height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isChecked ? AppColors.primary : Colors.transparent,
                  border: Border.all(
                    color: isChecked ? AppColors.primary : AppColors.textSecondary,
                    width: 2,
                  ),
                ),
                child: isChecked
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 12),
            ],
            // 头像
            Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: color,
                  backgroundImage: item.avatarUrl != null ? PmImageProvider(item.avatarUrl!) : null,
                  child: item.avatarUrl == null
                      ? Text(item.name.isNotEmpty ? item.name[0] : '?',
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))
                      : null,
                ),
                if (item.type == _SessionType.group)
                  Positioned(
                    right: -2, bottom: -2,
                    child: Container(
                      width: 16, height: 16,
                      decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                      child: const Icon(Icons.people, size: 10, color: Colors.white),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            // 内容
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(item.name,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                            overflow: TextOverflow.ellipsis),
                      ),
                      Text(timeStr, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Expanded(
                        child: Text(item.lastMessage ?? '',
                            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                      if (item.unreadCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(color: AppColors.error, borderRadius: BorderRadius.circular(10)),
                          child: Text(
                            item.unreadCount > 99 ? '99+' : '${item.unreadCount}',
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
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

  // ── 通知列表 ────────────────────────────────────────────────────────────────

  Widget _buildNotifList(
    List<AppNotification> notifs, {
    required String emptyText,
    required IconData emptyIcon,
  }) {
    if (notifs.isEmpty) {
      return _EmptyHint(icon: emptyIcon, text: emptyText);
    }
    return ListView.separated(
      itemCount: notifs.length,
      separatorBuilder: (_, __) => const Divider(height: 1, indent: 64, color: AppColors.border),
      itemBuilder: (context, index) => _buildNotifItem(notifs[index]),
    );
  }

  Widget _buildNotifItem(AppNotification n) {
    final iconColor = _notifColor(n.type);
    final icon      = _notifIcon(n.type);
    final isBuddy   = n.type == NotificationType.buddyRequest;

    return InkWell(
      onTap: () {
        ref.read(notificationsProvider.notifier).markRead(n.id);
        if (n.type == NotificationType.buddyRequest || n.type == NotificationType.invitation) {
          context.push('/buddy/invitations');
        }
      },
      child: Container(
        color: n.isRead ? AppColors.surface : AppColors.primaryLight.withAlpha(40),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: iconColor.withAlpha(30),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(n.title,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary))),
                      Text(_formatTime(n.createdAt),
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(n.content,
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                  if (isBuddy && !n.isRead) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _ActionBtn(
                          label: '拒绝',
                          primary: false,
                          onTap: () => ref.read(notificationsProvider.notifier).markRead(n.id),
                        ),
                        const SizedBox(width: 8),
                        _ActionBtn(
                          label: '接受',
                          primary: true,
                          onTap: () {
                            ref.read(notificationsProvider.notifier).markRead(n.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('已接受搭子申请'), duration: Duration(seconds: 1)),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            if (!n.isRead)
              Container(
                width: 8, height: 8, margin: const EdgeInsets.only(top: 4, left: 4),
                decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
              ),
          ],
        ),
      ),
    );
  }
}

// ── 辅助数据类 ────────────────────────────────────────────────────────────────

enum _SessionType { dm, group }

class _SessionItem {
  const _SessionItem({
    required this.id,
    required this.type,
    required this.name,
    this.avatarUrl,
    this.lastMessage,
    this.lastMessageAt,
    required this.unreadCount,
    this.otherId,
  });

  factory _SessionItem.fromConv(Conversation c) => _SessionItem(
        id: c.id, type: _SessionType.dm,
        name: c.otherUsername, avatarUrl: c.otherAvatarUrl,
        lastMessage: c.lastMessage, lastMessageAt: c.lastMessageAt,
        unreadCount: c.unreadCount, otherId: c.otherUserId,
      );

  factory _SessionItem.fromGroup(GroupSession g) => _SessionItem(
        id: g.id, type: _SessionType.group,
        name: g.name, avatarUrl: g.avatarUrl,
        lastMessage: g.lastMessage, lastMessageAt: g.lastMessageAt,
        unreadCount: g.unreadCount,
      );

  final String id;
  final _SessionType type;
  final String name;
  final String? avatarUrl;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final int unreadCount;
  final String? otherId;
}

// ── 小组件 ────────────────────────────────────────────────────────────────────

class _BadgeTab extends StatelessWidget {
  const _BadgeTab({required this.label, required this.count});

  final String label;
  final int    count;

  @override
  Widget build(BuildContext context) {
    return Tab(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Padding(
            padding: EdgeInsets.only(right: count > 0 ? 8.0 : 0),
            child: Text(label),
          ),
          if (count > 0)
            Positioned(
              top: -2,
              right: 0,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _QuickEntryItem extends StatelessWidget {
  const _QuickEntryItem({
    required this.emoji,
    required this.label,
    required this.bgColor,
    required this.unread,
    required this.onTap,
  });

  final String emoji;
  final String label;
  final Color  bgColor;
  final int    unread;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: Text(emoji, style: const TextStyle(fontSize: 20)),
                ),
                if (unread > 0)
                  Positioned(
                    top: -4, right: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(color: AppColors.error, borderRadius: BorderRadius.circular(8)),
                      child: Text('$unread', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({required this.icon, required this.text});

  final IconData icon;
  final String   text;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 300,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 56, color: AppColors.textSecondary),
          const SizedBox(height: 16),
          Text(text, style: const TextStyle(color: AppColors.textSecondary, fontSize: 15)),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({required this.label, required this.primary, required this.onTap});

  final String       label;
  final bool         primary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: primary ? AppColors.primary : const Color(0xFFF0F0F0),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(label,
            style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w500,
              color: primary ? Colors.white : AppColors.textSecondary,
            )),
      ),
    );
  }
}
