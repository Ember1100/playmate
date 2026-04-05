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
        isNewUser: json['is_new_user'] as bool? ?? false,
      );

  final String  id;
  final String  username;
  final String? email;
  final String? phone;
  final String? avatarUrl;
  final String? bio;
  final int     gender;
  final String? birthday;
  final bool    isNewUser;
}

class AuthResponse {
  const AuthResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) => AuthResponse(
        accessToken: json['access_token'] as String,
        refreshToken: json['refresh_token'] as String,
        user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
      );

  final String accessToken;
  final String refreshToken;
  final UserModel user;
}
