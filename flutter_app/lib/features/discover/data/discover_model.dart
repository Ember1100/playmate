class MatchCandidate {
  const MatchCandidate({
    required this.id,
    required this.username,
    this.avatarUrl,
    this.bio,
    required this.gender,
    this.age,
    required this.tags,
    required this.matchScore,
  });

  factory MatchCandidate.fromJson(Map<String, dynamic> json) => MatchCandidate(
        id: json['id'] as String,
        username: json['username'] as String,
        avatarUrl: json['avatar_url'] as String?,
        bio: json['bio'] as String?,
        gender: json['gender'] as int? ?? 0,
        age: json['age'] as int?,
        tags: (json['tags'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
        matchScore: json['match_score'] as int? ?? 0,
      );

  final String id;
  final String username;
  final String? avatarUrl;
  final String? bio;
  final int gender;
  final int? age;
  final List<String> tags;
  final int matchScore;
}
