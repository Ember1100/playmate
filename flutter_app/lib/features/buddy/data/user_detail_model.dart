class CareerDetailModel {
  const CareerDetailModel({
    this.jobTitle,
    this.company,
    this.experience,
    this.lookingFor,
    required this.skills,
  });

  final String? jobTitle;
  final String? company;
  final String? experience;
  final String? lookingFor;
  final List<String> skills;

  factory CareerDetailModel.fromJson(Map<String, dynamic> j) => CareerDetailModel(
        jobTitle:   j['job_title']   as String?,
        company:    j['company']     as String?,
        experience: j['experience']  as String?,
        lookingFor: j['looking_for'] as String?,
        skills:     (j['skills'] as List<dynamic>? ?? []).cast<String>(),
      );

  bool get isEmpty =>
      jobTitle == null && company == null && experience == null &&
      lookingFor == null && skills.isEmpty;
}

class UserDetailModel {
  const UserDetailModel({
    required this.id,
    required this.username,
    this.avatarUrl,
    this.bio,
    required this.gender,
    this.city,
    required this.tags,
    required this.isVerified,
    required this.creditScore,
    required this.creditLabel,
    required this.level,
    this.career,
  });

  final String id;
  final String username;
  final String? avatarUrl;
  final String? bio;
  final int gender;
  final String? city;
  final List<String> tags;
  final bool isVerified;
  final int creditScore;
  final String creditLabel;
  final int level;
  final CareerDetailModel? career;

  String get genderLabel {
    switch (gender) {
      case 1: return '男';
      case 2: return '女';
      default: return '';
    }
  }

  factory UserDetailModel.fromResponses({
    required Map<String, dynamic> user,
    Map<String, dynamic>? stats,
    Map<String, dynamic>? career,
  }) {
    final creditScore = stats?['credit_score'] as int? ?? 0;
    final creditLabel = stats?['credit_label'] as String? ?? '普通';
    return UserDetailModel(
      id:          user['id']          as String,
      username:    user['username']    as String,
      avatarUrl:   user['avatar_url']  as String?,
      bio:         user['bio']         as String?,
      gender:      user['gender']      as int? ?? 0,
      city:        user['city']        as String?,
      tags:        (user['tags'] as List<dynamic>? ?? []).cast<String>(),
      isVerified:  user['is_verified'] as bool? ?? false,
      creditScore: creditScore,
      creditLabel: creditLabel,
      level:       stats?['level']     as int? ?? 1,
      career: career != null && career['is_public'] == true
          ? CareerDetailModel.fromJson(career)
          : null,
    );
  }
}
