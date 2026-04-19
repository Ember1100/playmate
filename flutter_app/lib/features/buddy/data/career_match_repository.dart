import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';

// ── 匹配结果数据模型 ──────────────────────────────────────────────────────────

class CareerMatchResult {
  const CareerMatchResult({
    required this.matched,
    this.matchedUserId,
    this.username,
    this.avatarUrl,
    this.careerRole,
    this.company,
    this.experience,
    this.score,
    this.commonSkills,
    this.commonSkillCount,
    this.commonGoalCount,
    this.collabSuggestions,
  });

  final bool            matched;
  final String?         matchedUserId;
  final String?         username;
  final String?         avatarUrl;
  final String?         careerRole;
  final String?         company;
  final String?         experience;
  final int?            score;
  final List<String>?   commonSkills;
  final int?            commonSkillCount;
  final int?            commonGoalCount;
  final List<String>?   collabSuggestions;

  factory CareerMatchResult.fromJson(Map<String, dynamic> json) {
    return CareerMatchResult(
      matched:           json['matched'] as bool? ?? false,
      matchedUserId:     json['matched_user_id'] as String?,
      username:          json['username'] as String?,
      avatarUrl:         json['avatar_url'] as String?,
      careerRole:        json['career_role'] as String?,
      company:           json['company'] as String?,
      experience:        json['experience'] as String?,
      score:             json['score'] as int?,
      commonSkills:      (json['common_skills'] as List<dynamic>?)
                             ?.map((e) => e as String).toList(),
      commonSkillCount:  json['common_skill_count'] as int?,
      commonGoalCount:   json['common_goal_count'] as int?,
      collabSuggestions: (json['collab_suggestions'] as List<dynamic>?)
                             ?.map((e) => e as String).toList(),
    );
  }
}

// ── Repository ────────────────────────────────────────────────────────────────

class CareerMatchRepository {
  CareerMatchRepository(this._client);

  final ApiClient _client;

  Future<void> joinMatch({
    required List<String> fields,
    required List<String> goals,
    required String experience,
  }) async {
    await _client.post<Map<String, dynamic>>(
      '/buddy/career/match/join',
      data: {
        'fields':     fields,
        'goals':      goals,
        'experience': experience,
      },
    );
  }

  Future<void> leaveMatch() async {
    await _client.delete<dynamic>('/buddy/career/match/leave');
  }

  Future<CareerMatchResult> getResult() async {
    final resp = await _client.get<Map<String, dynamic>>('/buddy/career/match/result');
    return CareerMatchResult.fromJson(
      resp['data'] as Map<String, dynamic>? ?? {},
    );
  }

  Future<void> nextMatch({
    required List<String> fields,
    required List<String> goals,
    required String experience,
  }) async {
    await _client.post<Map<String, dynamic>>(
      '/buddy/career/match/next',
      data: {
        'fields':     fields,
        'goals':      goals,
        'experience': experience,
      },
    );
  }
}

final careerMatchRepositoryProvider = Provider<CareerMatchRepository>((ref) {
  return CareerMatchRepository(ref.watch(apiClientProvider));
});
