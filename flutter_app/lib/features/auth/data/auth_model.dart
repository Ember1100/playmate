class UserModel {
  const UserModel({
    required this.id,
    required this.username,
    this.email,
    this.phone,
    this.avatarUrl,
    this.bio,
    required this.gender,
    this.birthday,
    this.city,
    this.tags = const [],
    this.isNewUser = false,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id:        json['id']       as String,
        username:  json['username'] as String,
        email:     json['email']    as String?,
        phone:     json['phone']    as String?,
        avatarUrl: json['avatar_url'] as String?,
        bio:       json['bio']      as String?,
        gender:    json['gender']   as int? ?? 0,
        birthday:  json['birthday'] as String?,
        city:      json['city']     as String?,
        tags:      (json['tags'] as List<dynamic>? ?? []).cast<String>(),
        isNewUser: json['is_new_user'] as bool? ?? false,
      );

  final String        id;
  final String        username;
  final String?       email;
  final String?       phone;
  final String?       avatarUrl;
  final String?       bio;
  final int           gender;
  final String?       birthday;
  final String?       city;
  final List<String>  tags;
  final bool          isNewUser;

  UserModel copyWith({
    String?       avatarUrl,
    String?       username,
    String?       bio,
    int?          gender,
    String?       birthday,
    String?       city,
    List<String>? tags,
    bool?         isNewUser,
  }) =>
      UserModel(
        id:        id,
        username:  username  ?? this.username,
        email:     email,
        phone:     phone,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        bio:       bio       ?? this.bio,
        gender:    gender    ?? this.gender,
        birthday:  birthday  ?? this.birthday,
        city:      city      ?? this.city,
        tags:      tags      ?? this.tags,
        isNewUser: isNewUser ?? this.isNewUser,
      );
}

class AuthResponse {
  const AuthResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) => AuthResponse(
        accessToken:  json['access_token']  as String,
        refreshToken: json['refresh_token'] as String,
        user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
      );

  final String    accessToken;
  final String    refreshToken;
  final UserModel user;
}
