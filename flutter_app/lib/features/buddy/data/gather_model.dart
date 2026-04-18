import 'package:flutter/material.dart';

class Gather {
  const Gather({
    required this.id,
    required this.creatorId,
    required this.creatorUsername,
    this.creatorAvatar,
    required this.title,
    this.location,
    required this.startTime,
    required this.endTime,
    this.firstMenuId,
    this.firstMenuName,
    this.secondMenuId,
    this.secondMenuName,
    required this.capacity,
    this.description,
    required this.vibes,
    required this.status,
    this.groupId,
    required this.joinedCount,
    required this.isJoined,
    required this.memberAvatars,
    required this.memberUsernames,
    required this.createdAt,
  });

  final String id;
  final String creatorId;
  final String creatorUsername;
  final String? creatorAvatar;
  final String title;
  final String? location;
  final DateTime startTime;
  final DateTime endTime;
  final int? firstMenuId;
  final String? firstMenuName;
  final int? secondMenuId;
  final String? secondMenuName;
  final int capacity;
  final String? description;
  final List<String> vibes;
  final int status;
  final String? groupId;
  final int joinedCount;
  final bool isJoined;
  final List<String> memberAvatars;     // 与 memberUsernames 一一对应，无头像时为空串
  final List<String> memberUsernames;   // 参加成员用户名（最多 5 人）
  final DateTime createdAt;

  bool get isFull => joinedCount >= capacity;

  /// 搭子标签名：「{二级菜单名}搭子」
  String get buddyTag => secondMenuName != null ? '${secondMenuName}搭子' : '搭子';

  /// 根据一级菜单名返回对应主题色
  Color get themeColor {
    switch (firstMenuName) {
      case '生活': return const Color(0xFFFF7A00);
      case '学习': return const Color(0xFF5DCAA5);
      case '兴趣': return const Color(0xFF2196F3);
      case '游戏': return const Color(0xFF9C27B0);
      default:    return const Color(0xFF888888);
    }
  }

  factory Gather.fromJson(Map<String, dynamic> json) {
    return Gather(
      id:               json['id'] as String,
      creatorId:        json['creator_id'] as String,
      creatorUsername:  json['creator_username'] as String,
      creatorAvatar:    json['creator_avatar'] as String?,
      title:            json['title'] as String,
      location:         json['location'] as String?,
      startTime:        DateTime.parse(json['start_time'] as String).toLocal(),
      endTime:          DateTime.parse(json['end_time'] as String).toLocal(),
      firstMenuId:      json['first_menu_id'] as int?,
      firstMenuName:    json['first_menu_name'] as String?,
      secondMenuId:     json['second_menu_id'] as int?,
      secondMenuName:   json['second_menu_name'] as String?,
      capacity:         json['capacity'] as int,
      description:      json['description'] as String?,
      vibes:            (json['vibes'] as List<dynamic>? ?? []).cast<String>(),
      status:           json['status'] as int,
      groupId:          json['group_id'] as String?,
      joinedCount:      json['joined_count'] as int,
      isJoined:         json['is_joined'] as bool? ?? false,
      memberAvatars:    (json['member_avatars'] as List<dynamic>? ?? []).cast<String>(),
      memberUsernames:  (json['member_usernames'] as List<dynamic>? ?? []).cast<String>(),
      createdAt:        DateTime.parse(json['created_at'] as String).toLocal(),
    );
  }

  Gather copyWith({int? joinedCount, bool? isJoined, List<String>? memberAvatars, List<String>? memberUsernames}) {
    return Gather(
      id:              id,
      creatorId:       creatorId,
      creatorUsername: creatorUsername,
      creatorAvatar:   creatorAvatar,
      title:           title,
      location:        location,
      startTime:       startTime,
      endTime:         endTime,
      firstMenuId:     firstMenuId,
      firstMenuName:   firstMenuName,
      secondMenuId:    secondMenuId,
      secondMenuName:  secondMenuName,
      capacity:        capacity,
      description:     description,
      vibes:           vibes,
      status:          status,
      groupId:         groupId,
      joinedCount:     joinedCount ?? this.joinedCount,
      isJoined:        isJoined ?? this.isJoined,
      memberAvatars:    memberAvatars ?? this.memberAvatars,
      memberUsernames:  memberUsernames ?? this.memberUsernames,
      createdAt:        createdAt,
    );
  }
}

// ── 搜索结果模型 ──────────────────────────────────────────────────────────────

class SearchUser {
  const SearchUser({
    required this.id,
    required this.username,
    this.avatarUrl,
    this.bio,
    required this.tags,
    this.city,
  });

  final String id;
  final String username;
  final String? avatarUrl;
  final String? bio;
  final List<String> tags;
  final String? city;

  factory SearchUser.fromJson(Map<String, dynamic> json) => SearchUser(
        id:        json['id'] as String,
        username:  json['username'] as String? ?? '',
        avatarUrl: json['avatar_url'] as String?,
        bio:       json['bio'] as String?,
        tags:      (json['tags'] as List<dynamic>? ?? []).cast<String>(),
        city:      json['city'] as String?,
      );
}

class BuddySearchResult {
  const BuddySearchResult({
    required this.users,
    required this.userTotal,
    required this.gathers,
    required this.gatherTotal,
  });

  final List<SearchUser> users;
  final int userTotal;
  final List<Gather> gathers;
  final int gatherTotal;

  bool get isEmpty => users.isEmpty && gathers.isEmpty;

  factory BuddySearchResult.fromJson(Map<String, dynamic> json) => BuddySearchResult(
        users: (json['users'] as List<dynamic>? ?? [])
            .map((e) => SearchUser.fromJson(e as Map<String, dynamic>))
            .toList(),
        userTotal:    json['user_total'] as int? ?? 0,
        gathers: (json['gathers'] as List<dynamic>? ?? [])
            .map((e) => Gather.fromJson(e as Map<String, dynamic>))
            .toList(),
        gatherTotal: json['gather_total'] as int? ?? 0,
      );
}

class CreateGatherRequest {
  const CreateGatherRequest({
    required this.title,
    this.location,
    required this.startTime,
    required this.endTime,
    this.firstMenuId,
    this.secondMenuId,
    required this.capacity,
    this.description,
    required this.vibes,
  });

  final String title;
  final String? location;
  final DateTime startTime;
  final DateTime endTime;
  final int? firstMenuId;
  final int? secondMenuId;
  final int capacity;
  final String? description;
  final List<String> vibes;

  Map<String, dynamic> toJson() => {
    'title':          title,
    'location':       location,
    'start_time':     startTime.toUtc().toIso8601String(),
    'end_time':       endTime.toUtc().toIso8601String(),
    'first_menu_id':  firstMenuId,
    'second_menu_id': secondMenuId,
    'capacity':       capacity,
    'description':    description,
    'vibes':          vibes,
  };
}
