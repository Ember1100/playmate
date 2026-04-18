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
    required this.category,
    required this.theme,
    required this.capacity,
    this.description,
    required this.vibes,
    required this.status,
    this.groupId,
    required this.joinedCount,
    required this.isJoined,
    required this.memberAvatars,
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
  final String category;
  final String theme;
  final int capacity;
  final String? description;
  final List<String> vibes;
  final int status;
  final String? groupId;
  final int joinedCount;
  final bool isJoined;
  final List<String> memberAvatars;
  final DateTime createdAt;

  bool get isFull => joinedCount >= capacity;

  /// 根据 theme 返回对应主题色
  Color get themeColor {
    switch (theme) {
      case '吃货': return const Color(0xFFFF7A00);
      case '看看': return const Color(0xFF9C27B0);
      case '运动': return const Color(0xFF5DCAA5);
      case '游戏': return const Color(0xFF2196F3);
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
      category:         json['category'] as String,
      theme:            json['theme'] as String,
      capacity:         json['capacity'] as int,
      description:      json['description'] as String?,
      vibes:            (json['vibes'] as List<dynamic>? ?? []).cast<String>(),
      status:           json['status'] as int,
      groupId:          json['group_id'] as String?,
      joinedCount:      json['joined_count'] as int,
      isJoined:         json['is_joined'] as bool? ?? false,
      memberAvatars:    (json['member_avatars'] as List<dynamic>? ?? []).cast<String>(),
      createdAt:        DateTime.parse(json['created_at'] as String).toLocal(),
    );
  }

  Gather copyWith({int? joinedCount, bool? isJoined, List<String>? memberAvatars}) {
    return Gather(
      id:              id,
      creatorId:       creatorId,
      creatorUsername: creatorUsername,
      creatorAvatar:   creatorAvatar,
      title:           title,
      location:        location,
      startTime:       startTime,
      endTime:         endTime,
      category:        category,
      theme:           theme,
      capacity:        capacity,
      description:     description,
      vibes:           vibes,
      status:          status,
      groupId:         groupId,
      joinedCount:     joinedCount ?? this.joinedCount,
      isJoined:        isJoined ?? this.isJoined,
      memberAvatars:   memberAvatars ?? this.memberAvatars,
      createdAt:       createdAt,
    );
  }
}

class CreateGatherRequest {
  const CreateGatherRequest({
    required this.title,
    this.location,
    required this.startTime,
    required this.endTime,
    required this.category,
    required this.theme,
    required this.capacity,
    this.description,
    required this.vibes,
  });

  final String title;
  final String? location;
  final DateTime startTime;
  final DateTime endTime;
  final String category;
  final String theme;
  final int capacity;
  final String? description;
  final List<String> vibes;

  Map<String, dynamic> toJson() => {
    'title':       title,
    'location':    location,
    'start_time':  startTime.toUtc().toIso8601String(),
    'end_time':    endTime.toUtc().toIso8601String(),
    'category':    category,
    'theme':       theme,
    'capacity':    capacity,
    'description': description,
    'vibes':       vibes,
  };
}

/// 发布表单选项 → 后端分类映射
String themeToCategory(String theme) {
  switch (theme) {
    case '吃货': return '生活';
    case '看看': return '生活';
    case '运动': return '兴趣';
    case '游戏': return '游戏';
    default:    return '生活';
  }
}
