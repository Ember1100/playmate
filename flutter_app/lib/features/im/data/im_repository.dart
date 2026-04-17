import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import 'im_model.dart';

class ImRepository {
  ImRepository(this._client);

  final ApiClient _client;

  Future<List<Conversation>> getConversations() async {
    try {
      final resp = await _client.get<Map<String, dynamic>>('/im/conversations');
      final data = resp['data'] as List<dynamic>? ?? [];
      final list = data
          .map((e) => Conversation.fromJson(e as Map<String, dynamic>))
          .toList();
      if (list.isNotEmpty) return list;
    } catch (_) {}
    // mock fallback
    return [
      Conversation(
        id: 'mock-conv-1',
        otherUserId: 'user-chen',
        otherUsername: '陈思远',
        lastMessage: '明天有空一起打球吗？',
        lastMessageAt: DateTime.now().subtract(const Duration(minutes: 5)),
        unreadCount: 2,
      ),
      Conversation(
        id: 'mock-conv-2',
        otherUserId: 'user-li',
        otherUsername: '李雨萌',
        lastMessage: '哈哈好的，下午三点见！',
        lastMessageAt: DateTime.now().subtract(const Duration(hours: 2)),
        unreadCount: 0,
      ),
    ];
  }

  Future<List<Message>> getMessages(String conversationId,
      {int page = 1}) async {
    try {
      final resp = await _client.get<Map<String, dynamic>>(
        '/im/conversations/$conversationId/messages',
        params: {'page': page},
      );
      final pageData = resp['data'] as Map<String, dynamic>? ?? {};
      final items = pageData['items'] as List<dynamic>? ?? [];
      final list = items
          .map((e) => Message.fromJson(e as Map<String, dynamic>))
          .toList();
      if (list.isNotEmpty) return list;
    } catch (_) {}
    return _mockMessages(conversationId);
  }

  static List<Message> _mockMessages(String conversationId) {
    final now = DateTime.now();
    final otherId = 'other-$conversationId';

    final Map<String, List<_M>> scripts = {
      'mock-conv-1': [
        _M(otherId, '嘿，最近在忙什么呢？', now.subtract(const Duration(hours: 2, minutes: 30))),
        _M('me', '在准备一个项目，有点忙哈哈', now.subtract(const Duration(hours: 2, minutes: 20))),
        _M(otherId, '加油！对了，周末有没有空打球？', now.subtract(const Duration(hours: 2))),
        _M('me', '周六下午应该可以，几点？', now.subtract(const Duration(hours: 1, minutes: 50))),
        _M(otherId, '下午两点操场见？', now.subtract(const Duration(hours: 1, minutes: 40))),
        _M('me', '好的没问题！', now.subtract(const Duration(hours: 1, minutes: 35))),
        _M(otherId, '明天有空一起打球吗？', now.subtract(const Duration(minutes: 5))),
      ],
      'mock-conv-2': [
        _M(otherId, '你好，看到你也对爬山感兴趣！', now.subtract(const Duration(days: 1, hours: 3))),
        _M('me', '对啊，你经常爬吗？', now.subtract(const Duration(days: 1, hours: 2, minutes: 50))),
        _M(otherId, '差不多每个月两次，主要在郊区', now.subtract(const Duration(days: 1, hours: 2, minutes: 40))),
        _M('me', '有没有推荐的线路？', now.subtract(const Duration(days: 1, hours: 2, minutes: 20))),
        _M(otherId, '可以试试天柱山，难度适中风景很好', now.subtract(const Duration(days: 1, hours: 2))),
        _M('me', '听起来不错，下次一起？', now.subtract(const Duration(hours: 3))),
        _M(otherId, '哈哈好的，下午三点见！', now.subtract(const Duration(hours: 2))),
      ],
    };

    final script = scripts[conversationId] ?? [
      _M(otherId, '你好！很高兴认识你 😊', now.subtract(const Duration(hours: 1))),
      _M('me', '你好！我也是，期待我们成为搭伴～', now.subtract(const Duration(minutes: 50))),
      _M(otherId, '有空一起出来玩吗？', now.subtract(const Duration(minutes: 30))),
    ];

    return script.asMap().entries.map((e) => Message(
          id: 'mock-msg-${conversationId.hashCode}-${e.key}',
          conversationId: conversationId,
          senderId: e.value.sender,
          type: 1,
          content: e.value.text,
          createdAt: e.value.at,
          isRecalled: false,
        )).toList();
  }

  Future<Message> sendMessage({
    required String conversationId,
    required String content,
  }) async {
    final resp = await _client.post<Map<String, dynamic>>(
      '/im/conversations/$conversationId/messages',
      data: {'type': 1, 'content': content},
    );
    return Message.fromJson(resp['data'] as Map<String, dynamic>);
  }

  Future<String> createConversation(String userId) async {
    final resp = await _client.post<Map<String, dynamic>>(
      '/im/conversations',
      data: {'target_user_id': userId},
    );
    final data = resp['data'] as Map<String, dynamic>;
    return data['id'] as String;
  }

  Future<List<GroupSession>> getGroupSessions() async {
    try {
      final resp = await _client.get<Map<String, dynamic>>(
        '/circle/groups',
        params: {'joined': true, 'with_last_message': true},
      );
      final data = resp['data'] as List<dynamic>? ?? [];
      final list = data
          .map((e) => GroupSession.fromJson(e as Map<String, dynamic>))
          .toList();
      if (list.isNotEmpty) return list;
    } catch (_) {}
    return GroupSession.mockList;
  }

  Future<List<AppNotification>> getNotifications() async {
    try {
      final resp = await _client.get<Map<String, dynamic>>('/notifications');
      final data = resp['data'] as List<dynamic>? ?? [];
      final list = data
          .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
          .toList();
      if (list.isNotEmpty) return list;
    } catch (_) {}
    return AppNotification.mockList;
  }

  Future<void> markNotificationRead(String id) async {
    try {
      await _client.post<Map<String, dynamic>>('/notifications/$id/read');
    } catch (_) {}
  }

  Future<List<GroupMessage>> getGroupMessages(String groupId, {int page = 1}) async {
    try {
      final resp = await _client.get<Map<String, dynamic>>(
        '/circle/groups/$groupId/messages',
        params: {'page': page},
      );
      final pageData = resp['data'] as Map<String, dynamic>? ?? {};
      final items = pageData['items'] as List<dynamic>? ?? [];
      final list = items.map((e) => GroupMessage.fromJson(e as Map<String, dynamic>)).toList();
      if (list.isNotEmpty) return list;
    } catch (_) {}
    return _mockGroupMessages(groupId);
  }

  static List<GroupMessage> _mockGroupMessages(String groupId) {
    final now = DateTime.now();
    const myId = 'me';

    final Map<String, List<_GM>> scripts = {
      'mock-group-1': [
        _GM('sys',     '',      '小赵 加入了群聊',                99, now.subtract(const Duration(days: 3))),
        _GM('zhao',    '小赵',  '大家好，我是新来的！',           1, now.subtract(const Duration(days: 3, minutes: -2))),
        _GM('ali',     '阿李',  '欢迎！我们每天早上六点出发',     1, now.subtract(const Duration(days: 3, minutes: -5))),
        _GM('xiaomei', '小美',  '明天天气不错，适合跑步 🌤️',     1, now.subtract(const Duration(hours: 2))),
        _GM('ali',     '阿李',  '对，风也不大',                   1, now.subtract(const Duration(hours: 1, minutes: 55))),
        _GM('xiaomei', '小美',  '有没有人带补给？上次忘带水了',   1, now.subtract(const Duration(hours: 1, minutes: 50))),
        _GM(myId,      '我',    '我带两瓶，够用',                 1, now.subtract(const Duration(hours: 1, minutes: 45))),
        _GM('zhao',    '小赵',  '我也带了能量棒，可以分享',       1, now.subtract(const Duration(hours: 1, minutes: 40))),
        _GM('ali',     '阿李',  '太棒了！',                       1, now.subtract(const Duration(minutes: 20))),
        _GM('zhao',    '小赵',  '明早六点操场见！',               1, now.subtract(const Duration(minutes: 15))),
      ],
      'mock-group-2': [
        _GM('chen',   '陈队长', '大家这周末爬天柱山，有兴趣吗？', 1, now.subtract(const Duration(days: 2))),
        _GM('wang',   '老王',   '天柱山多高？',                   1, now.subtract(const Duration(days: 2, minutes: -10))),
        _GM('chen',   '陈队长', '主峰1489米，难度中等',           1, now.subtract(const Duration(days: 2, minutes: -20))),
        _GM(myId,     '我',     '我报名！需要带什么装备？',       1, now.subtract(const Duration(days: 2, minutes: -30))),
        _GM('chen',   '陈队长', '登山鞋、冲锋衣、水就行',         1, now.subtract(const Duration(days: 2, minutes: -40))),
        _GM('linlin', '琳琳',   '我第一次爬，会累吗？',           1, now.subtract(const Duration(days: 1, hours: 5))),
        _GM('wang',   '老王',   '问题不大，我上次带新手来过',     1, now.subtract(const Duration(days: 1, hours: 4, minutes: 55))),
        _GM('linlin', '琳琳',   '那好，我也报名！🙋',             1, now.subtract(const Duration(days: 1, hours: 4, minutes: 50))),
        _GM('chen',   '陈队长', '路线已发群里，记得带水',         1, now.subtract(const Duration(hours: 4))),
        _GM(myId,     '我',     '好的，周六见！',                 1, now.subtract(const Duration(hours: 3, minutes: 45))),
        _GM('linlin', '琳琳',   '期待！第一次爬山小激动 😆',      1, now.subtract(const Duration(hours: 1))),
        _GM('wang',   '老王',   '路线已发群里，记得带水',         1, now.subtract(const Duration(minutes: 4))),
      ],
    };

    final script = scripts[groupId] ?? [
      _GM('user-a', '群成员A', '大家好！',             1, now.subtract(const Duration(hours: 1))),
      _GM(myId,     '我',     '大家好～',              1, now.subtract(const Duration(minutes: 55))),
      _GM('user-b', '群成员B', '欢迎！有活动叫上我',   1, now.subtract(const Duration(minutes: 30))),
    ];

    return script.asMap().entries.map((e) => GroupMessage(
      id: 'mock-gm-${groupId.hashCode}-${e.key}',
      groupId: groupId,
      senderId: e.value.senderId,
      senderUsername: e.value.username,
      type: e.value.type,
      content: e.value.content,
      isRecalled: false,
      createdAt: e.value.at,
    )).toList();
  }
}

final imRepositoryProvider = Provider<ImRepository>((ref) {
  return ImRepository(ref.watch(apiClientProvider));
});

class _M {
  const _M(this.sender, this.text, this.at);
  final String sender;
  final String text;
  final DateTime at;
}

class _GM {
  const _GM(this.senderId, this.username, this.content, this.type, this.at);
  final String senderId;
  final String username;
  final String content;
  final int type;
  final DateTime at;
}
