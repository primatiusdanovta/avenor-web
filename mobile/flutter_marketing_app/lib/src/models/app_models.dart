class AppUser {
  AppUser({
    required this.idUser,
    required this.nama,
    required this.role,
    required this.status,
  });

  final int idUser;
  final String nama;
  final String role;
  final String status;

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      idUser: json['id_user'] as int? ?? 0,
      nama: json['nama'] as String? ?? '',
      role: json['role'] as String? ?? '',
      status: json['status'] as String? ?? '',
    );
  }
}

class LoginPayload {
  LoginPayload({
    required this.token,
    required this.user,
    this.expiresAt,
  });

  final String token;
  final AppUser user;
  final String? expiresAt;

  factory LoginPayload.fromJson(Map<String, dynamic> json) {
    return LoginPayload(
      token: json['token'] as String? ?? '',
      user: AppUser.fromJson(json['user'] as Map<String, dynamic>? ?? {}),
      expiresAt: json['expires_at'] as String?,
    );
  }
}
