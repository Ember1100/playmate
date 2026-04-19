class TagModel {
  const TagModel({
    required this.id,
    required this.name,
    required this.category,
  });

  factory TagModel.fromJson(Map<String, dynamic> j) => TagModel(
        id:       j['id']       as int,
        name:     j['name']     as String,
        category: j['category'] as String,
      );

  final int    id;
  final String name;
  final String category;
}

class CareerModel {
  const CareerModel({
    this.jobTitle,
    this.company,
    this.experience,
    this.lookingFor,
    required this.skills,
    required this.isPublic,
  });

  factory CareerModel.fromJson(Map<String, dynamic> j) => CareerModel(
        jobTitle:   j['job_title']   as String?,
        company:    j['company']     as String?,
        experience: j['experience']  as String?,
        lookingFor: j['looking_for'] as String?,
        skills:     (j['skills'] as List<dynamic>? ?? []).cast<String>(),
        isPublic:   j['is_public']   as bool? ?? true,
      );

  final String? jobTitle;
  final String? company;
  final String? experience;
  final String? lookingFor;
  final List<String> skills;
  final bool isPublic;
}
