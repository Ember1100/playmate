import 'package:flutter/material.dart';

class Gather {
  const Gather({
    required this.id,
    required this.creatorId,
    required this.creatorUsername,
    this.creatorAvatar,
    required this.title,
    this.location,
    this.landmark,
    required this.startTime,
    required this.endTime,
    this.firstMenuId,
    this.firstMenuName,
    this.secondMenuId,
    this.secondMenuName,
    required this.capacity,
    this.description,
    required this.vibes,
    required this.activityMode,
    required this.status,
    this.groupId,
    this.schedule,
    this.deadline,
    this.feeType = 0,
    this.feeAmount,
    this.ageMin = 18,
    this.ageMax = 35,
    this.genderPref = 0,
    this.coverUrl,
    this.requireRealName = false,
    this.requireReview = false,
    this.allowTransfer = false,
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
  final String? landmark;
  final DateTime startTime;
  final DateTime endTime;
  final int? firstMenuId;
  final String? firstMenuName;
  final int? secondMenuId;
  final String? secondMenuName;
  final int capacity;
  final String? description;
  final List<String> vibes;
  final String activityMode; // "offline" | "online" | "invite"
  final int status;
  final String? groupId;
  final String? schedule;
  final DateTime? deadline;
  final int feeType;    // 0=免费 1=按需付费 2=AA制
  final double? feeAmount;
  final int ageMin;
  final int ageMax;
  final int genderPref; // 0=不限 1=仅男 2=仅女
  final String? coverUrl;
  final bool requireRealName;
  final bool requireReview;
  final bool allowTransfer;
  final int joinedCount;
  final bool isJoined;
  final List<String> memberAvatars;
  final List<String> memberUsernames;
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

  String get activityModeLabel {
    switch (activityMode) {
      case 'online': return '线上局';
      case 'invite': return '约人局';
      default:       return '线下局';
    }
  }

  String get feeLabel {
    if (feeType == 0) return '免费';
    if (feeType == 2) return 'AA 制';
    if (feeAmount != null) return '¥${feeAmount!.toStringAsFixed(feeAmount! % 1 == 0 ? 0 : 2)}/人';
    return '按需付费';
  }

  factory Gather.fromJson(Map<String, dynamic> json) {
    return Gather(
      id:               json['id'] as String,
      creatorId:        json['creator_id'] as String,
      creatorUsername:  json['creator_username'] as String,
      creatorAvatar:    json['creator_avatar'] as String?,
      title:            json['title'] as String,
      location:         json['location'] as String?,
      landmark:         json['landmark'] as String?,
      startTime:        DateTime.parse(json['start_time'] as String).toLocal(),
      endTime:          DateTime.parse(json['end_time'] as String).toLocal(),
      firstMenuId:      json['first_menu_id'] as int?,
      firstMenuName:    json['first_menu_name'] as String?,
      secondMenuId:     json['second_menu_id'] as int?,
      secondMenuName:   json['second_menu_name'] as String?,
      capacity:         json['capacity'] as int,
      description:      json['description'] as String?,
      vibes:            (json['vibes'] as List<dynamic>? ?? []).cast<String>(),
      activityMode:     json['activity_mode'] as String? ?? 'offline',
      status:           json['status'] as int,
      groupId:          json['group_id'] as String?,
      schedule:         json['schedule'] as String?,
      deadline:         json['deadline'] != null
          ? DateTime.parse(json['deadline'] as String).toLocal()
          : null,
      feeType:          json['fee_type'] as int? ?? 0,
      feeAmount:        (json['fee_amount'] as num?)?.toDouble(),
      ageMin:           json['age_min'] as int? ?? 18,
      ageMax:           json['age_max'] as int? ?? 35,
      genderPref:       json['gender_pref'] as int? ?? 0,
      coverUrl:         json['cover_url'] as String?,
      requireRealName:  json['require_real_name'] as bool? ?? false,
      requireReview:    json['require_review'] as bool? ?? false,
      allowTransfer:    json['allow_transfer'] as bool? ?? false,
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
      landmark:        landmark,
      startTime:       startTime,
      endTime:         endTime,
      firstMenuId:     firstMenuId,
      firstMenuName:   firstMenuName,
      secondMenuId:    secondMenuId,
      secondMenuName:  secondMenuName,
      capacity:        capacity,
      description:     description,
      vibes:           vibes,
      activityMode:    activityMode,
      status:          status,
      groupId:         groupId,
      schedule:        schedule,
      deadline:        deadline,
      feeType:         feeType,
      feeAmount:       feeAmount,
      ageMin:          ageMin,
      ageMax:          ageMax,
      genderPref:      genderPref,
      coverUrl:        coverUrl,
      requireRealName: requireRealName,
      requireReview:   requireReview,
      allowTransfer:   allowTransfer,
      joinedCount:     joinedCount ?? this.joinedCount,
      isJoined:        isJoined ?? this.isJoined,
      memberAvatars:   memberAvatars ?? this.memberAvatars,
      memberUsernames: memberUsernames ?? this.memberUsernames,
      createdAt:       createdAt,
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
    this.landmark,
    required this.startTime,
    required this.endTime,
    this.firstMenuId,
    this.secondMenuId,
    required this.capacity,
    this.description,
    required this.vibes,
    required this.activityMode,
    this.schedule,
    this.deadline,
    this.feeType = 0,
    this.feeAmount,
    this.ageMin = 18,
    this.ageMax = 35,
    this.genderPref = 0,
    this.coverUrl,
    this.requireRealName = false,
    this.requireReview = false,
    this.allowTransfer = false,
  });

  final String title;
  final String? location;
  final String? landmark;
  final DateTime startTime;
  final DateTime endTime;
  final int? firstMenuId;
  final int? secondMenuId;
  final int capacity;
  final String? description;
  final List<String> vibes;
  final String activityMode;
  final String? schedule;
  final DateTime? deadline;
  final int feeType;
  final double? feeAmount;
  final int ageMin;
  final int ageMax;
  final int genderPref;
  final String? coverUrl;
  final bool requireRealName;
  final bool requireReview;
  final bool allowTransfer;

  Map<String, dynamic> toJson() => {
    'title':              title,
    'location':           location,
    'landmark':           landmark,
    'start_time':         startTime.toUtc().toIso8601String(),
    'end_time':           endTime.toUtc().toIso8601String(),
    'first_menu_id':      firstMenuId,
    'second_menu_id':     secondMenuId,
    'capacity':           capacity,
    'description':        description,
    'vibes':              vibes,
    'activity_mode':      activityMode,
    'schedule':           schedule,
    'deadline':           deadline?.toUtc().toIso8601String(),
    'fee_type':           feeType,
    'fee_amount':         feeAmount,
    'age_min':            ageMin,
    'age_max':            ageMax,
    'gender_pref':        genderPref,
    'cover_url':          coverUrl,
    'require_real_name':  requireRealName,
    'require_review':     requireReview,
    'allow_transfer':     allowTransfer,
  };
}
