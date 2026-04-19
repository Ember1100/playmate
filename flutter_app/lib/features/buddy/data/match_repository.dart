import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';

class MatchResult {
  const MatchResult({
    required this.matched,
    this.matchedUserId,
    this.username,
    this.avatarUrl,
    this.bio,
    this.commonInterests,
    this.score,
  });

  final bool matched;
  final String? matchedUserId;
  final String? username;
  final String? avatarUrl;
  final String? bio;
  final List<String>? commonInterests;
  final int? score;

  factory MatchResult.fromJson(Map<String, dynamic> json) {
    return MatchResult(
      matched:          json['matched'] as bool? ?? false,
      matchedUserId:    json['matched_user_id'] as String?,
      username:         json['username'] as String?,
      avatarUrl:        json['avatar_url'] as String?,
      bio:              json['bio'] as String?,
      commonInterests:  (json['common_interests'] as List<dynamic>?)
                            ?.map((e) => e as String)
                            .toList(),
      score:            json['score'] as int?,
    );
  }
}

class MatchRepository {
  MatchRepository(this._client);

  final ApiClient _client;

  Future<void> joinMatch({
    required List<String> activities,
    required int mood,
    required int genderPref,
  }) async {
    await _client.post<Map<String, dynamic>>(
      '/buddy/match/join',
      data: {
        'activities':   activities,
        'mood':         mood,
        'gender_pref':  genderPref,
      },
    );
  }

  Future<void> leaveMatch() async {
    await _client.delete<dynamic>('/buddy/match/leave');
  }

  Future<MatchResult> getResult() async {
    final resp = await _client.get<Map<String, dynamic>>('/buddy/match/result');
    return MatchResult.fromJson(resp['data'] as Map<String, dynamic>? ?? {});
  }

  Future<void> nextMatch({
    required List<String> activities,
    required int mood,
    required int genderPref,
  }) async {
    await _client.post<Map<String, dynamic>>(
      '/buddy/match/next',
      data: {
        'activities':   activities,
        'mood':         mood,
        'gender_pref':  genderPref,
      },
    );
  }
}

final matchRepositoryProvider = Provider<MatchRepository>((ref) {
  return MatchRepository(ref.watch(apiClientProvider));
});
