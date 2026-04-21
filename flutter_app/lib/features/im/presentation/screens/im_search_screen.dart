import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme.dart';
import '../../../../shared/widgets/pm_image.dart';
import '../../../../shared/widgets/pm_swipe_back.dart';
import '../../data/im_model.dart';
import '../../providers/im_provider.dart';

class ImSearchScreen extends ConsumerStatefulWidget {
  const ImSearchScreen({super.key});

  @override
  ConsumerState<ImSearchScreen> createState() => _ImSearchScreenState();
}

class _ImSearchScreenState extends ConsumerState<ImSearchScreen> {
  final _controller = TextEditingController();
  final _focus      = FocusNode();
  String _query     = '';

  static const _avatarPalette = [
    (_AColor(0xFFFBEAF0), _AColor(0xFF993556)),
    (_AColor(0xFFE6F1FB), _AColor(0xFF185FA5)),
    (_AColor(0xFFE1F5EE), _AColor(0xFF0F6E56)),
    (_AColor(0xFFFAEEDA), _AColor(0xFF854F0B)),
    (_AColor(0xFFFAECE7), _AColor(0xFF993C1D)),
    (_AColor(0xFFEEEDFE), _AColor(0xFF534AB7)),
    (_AColor(0xFFF1EFE8), _AColor(0xFF5F5E5A)),
    (_AColor(0xFFFCEBEB), _AColor(0xFFA32D2D)),
  ];

  (Color, Color) _avatarColor(String seed) {
    final pair = _avatarPalette[seed.hashCode.abs() % _avatarPalette.length];
    return (pair.$1.c, pair.$2.c);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  String _formatTime(DateTime? dt) {
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1)  return '刚刚';
    if (diff.inMinutes < 60) return '${diff.inMinutes}分钟前';
    if (diff.inDays == 0)    return DateFormat('HH:mm').format(dt);
    if (diff.inDays < 7)     return ['日','一','二','三','四','五','六'][dt.weekday % 7];
    return DateFormat('MM-dd').format(dt);
  }

  List<_SearchResult> _buildResults(
    List<Conversation> convs,
    List<GroupSession> groups,
  ) {
    final q = _query.toLowerCase();
    final all = <_SearchResult>[
      ...convs.map((c) => _SearchResult(
            id:            c.id,
            name:          c.otherUsername,
            avatarUrl:     c.otherAvatarUrl,
            lastMessage:   c.lastMessage,
            lastMessageAt: c.lastMessageAt,
            isGroup:       false,
            otherId:       c.otherUserId,
          )),
      ...groups.map((g) => _SearchResult(
            id:            g.id,
            name:          g.name,
            avatarUrl:     g.avatarUrl,
            lastMessage:   g.lastMessage,
            lastMessageAt: g.lastMessageAt,
            isGroup:       true,
          )),
    ];
    all.sort((a, b) {
      if (a.lastMessageAt == null) return 1;
      if (b.lastMessageAt == null) return -1;
      return b.lastMessageAt!.compareTo(a.lastMessageAt!);
    });
    return all
        .where((s) =>
            s.name.toLowerCase().contains(q) ||
            (s.lastMessage?.toLowerCase().contains(q) ?? false))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final convsAsync  = ref.watch(conversationsProvider);
    final groupsAsync = ref.watch(groupSessionsProvider);
    final convs       = convsAsync.valueOrNull  ?? [];
    final groups      = groupsAsync.valueOrNull ?? [];
    final results     = _query.isEmpty ? <_SearchResult>[] : _buildResults(convs, groups);

    return PmSwipeBack(
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F6F6),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation:       0,
          automaticallyImplyLeading: false,
          titleSpacing: 12,
          title: Container(
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFF2F2F2),
              borderRadius: BorderRadius.circular(18),
            ),
            child: TextField(
              controller:     _controller,
              focusNode:      _focus,
              onChanged:      (v) => setState(() => _query = v.trim()),
              decoration: InputDecoration(
                hintText:   '搜索聊天内容',
                hintStyle:  const TextStyle(fontSize: 14, color: Color(0xFFAAAAAA)),
                prefixIcon: const Icon(Icons.search_rounded, size: 18, color: Color(0xFFAAAAAA)),
                suffixIcon: _query.isNotEmpty
                    ? GestureDetector(
                        onTap: () => setState(() { _controller.clear(); _query = ''; }),
                        child: const Icon(Icons.cancel, size: 16, color: Color(0xFFAAAAAA)),
                      )
                    : null,
                border:         InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                isDense:        true,
              ),
              style:           const TextStyle(fontSize: 14, color: Color(0xFF1A1A1A)),
              textInputAction: TextInputAction.search,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => context.pop(),
              child: const Text('取消', style: TextStyle(fontSize: 14, color: Color(0xFF555555))),
            ),
          ],
        ),
        body: _query.isEmpty
            ? _buildHint()
            : results.isEmpty
                ? _buildEmpty()
                : _buildResults2(results),
      ),
    );
  }

  Widget _buildHint() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_rounded, size: 52, color: Color(0xFFDDDDDD)),
          SizedBox(height: 12),
          Text('输入关键词搜索聊天',
              style: TextStyle(fontSize: 14, color: Color(0xFFAAAAAA))),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.search_off_rounded, size: 52, color: Color(0xFFDDDDDD)),
          const SizedBox(height: 12),
          Text('未找到「$_query」相关的聊天',
              style: const TextStyle(fontSize: 14, color: Color(0xFFAAAAAA))),
        ],
      ),
    );
  }

  Widget _buildResults2(List<_SearchResult> results) {
    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: results.length,
      separatorBuilder: (_, __) => const Divider(
        height: 0.5, thickness: 0.5, indent: 78, color: Color(0xFFEEEEEE),
      ),
      itemBuilder: (_, i) => _buildRow(results[i]),
    );
  }

  Widget _buildRow(_SearchResult item) {
    final (bg, fg) = _avatarColor(item.name);
    final label    = item.avatarUrl != null ? '' : (item.name.isNotEmpty ? item.name[0] : '?');

    return InkWell(
      onTap: () {
        if (item.isGroup) {
          context.push('/im/group/${item.id}', extra: {'groupName': item.name});
        } else {
          ref.read(conversationsProvider.notifier).clearUnread(item.id);
          context.push('/im/chat/${item.id}', extra: {
            'username':    item.name,
            'otherUserId': item.otherId,
          });
        }
      },
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // 头像
            Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: 23,
                  backgroundColor: bg,
                  backgroundImage: item.avatarUrl != null ? PmImageProvider(item.avatarUrl!) : null,
                  child: item.avatarUrl == null
                      ? Text(label,
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: fg))
                      : null,
                ),
                if (item.isGroup)
                  Positioned(
                    right: -2, bottom: -2,
                    child: Container(
                      width: 16, height: 16,
                      decoration: const BoxDecoration(
                          color: AppColors.primary, shape: BoxShape.circle),
                      alignment: Alignment.center,
                      child: const Icon(Icons.people, size: 10, color: Colors.white),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            // 内容（高亮匹配词）
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _HighlightText(
                          text:      item.name,
                          query:     _query,
                          baseStyle: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w500, color: Color(0xFF1A1A1A)),
                        ),
                      ),
                      Text(_formatTime(item.lastMessageAt),
                          style: const TextStyle(fontSize: 12, color: Color(0xFFAAAAAA))),
                    ],
                  ),
                  if (item.lastMessage != null) ...[
                    const SizedBox(height: 3),
                    _HighlightText(
                      text:      item.lastMessage!,
                      query:     _query,
                      baseStyle: const TextStyle(
                          fontSize: 13, color: Color(0xFF888888)),
                      maxLines:  1,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 高亮匹配词 ────────────────────────────────────────────────────────────────

class _HighlightText extends StatelessWidget {
  const _HighlightText({
    required this.text,
    required this.query,
    required this.baseStyle,
    this.maxLines,
  });

  final String     text;
  final String     query;
  final TextStyle  baseStyle;
  final int?       maxLines;

  @override
  Widget build(BuildContext context) {
    if (query.isEmpty) {
      return Text(text, style: baseStyle, maxLines: maxLines, overflow: TextOverflow.ellipsis);
    }
    final lower  = text.toLowerCase();
    final qLower = query.toLowerCase();
    final spans  = <TextSpan>[];
    int   start  = 0;
    int   idx    = lower.indexOf(qLower);

    while (idx != -1) {
      if (idx > start) {
        spans.add(TextSpan(text: text.substring(start, idx)));
      }
      spans.add(TextSpan(
        text:  text.substring(idx, idx + query.length),
        style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
      ));
      start = idx + query.length;
      idx   = lower.indexOf(qLower, start);
    }
    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start)));
    }

    return Text.rich(
      TextSpan(children: spans),
      style:    baseStyle,
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
    );
  }
}

// ── 数据模型 ──────────────────────────────────────────────────────────────────

class _SearchResult {
  const _SearchResult({
    required this.id,
    required this.name,
    required this.isGroup,
    this.avatarUrl,
    this.lastMessage,
    this.lastMessageAt,
    this.otherId,
  });

  final String    id;
  final String    name;
  final bool      isGroup;
  final String?   avatarUrl;
  final String?   lastMessage;
  final DateTime? lastMessageAt;
  final String?   otherId;
}

class _AColor {
  const _AColor(this.value);
  final int   value;
  Color get c => Color(value);
}
