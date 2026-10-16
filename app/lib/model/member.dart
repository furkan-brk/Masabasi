/// A club member / authenticated user.
class Member {
  const Member({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.email,
    this.role = 'member',
    this.bio,
    this.experienceLevel,
    this.clubStatus,
    this.favoriteGenres,
  });

  final String id;
  final String name;
  final String? avatarUrl;
  final String? email;

  /// 'member' | 'admin' — from the JWT / /me response.
  final String role;

  final String? bio;
  final String? experienceLevel;
  final String? clubStatus;

  /// Comma-separated genre strings stored as a single field on the backend.
  final String? favoriteGenres;

  bool get isAdmin => role == 'admin';

  factory Member.fromJson(Map<String, dynamic> json) {
    // Backend returns snake_case (GORM model): ID, display_name, avatar_url, ...
    // camelCase fallbacks keep mock-data constructors compiling.
    final rawId = json['ID'] ?? json['id'];
    final rawName = json['display_name'] ?? json['name'] ?? '';
    final rawAvatar = json['avatar_url'] ?? json['avatarUrl'];

    return Member(
      id: rawId?.toString() ?? '',
      name: rawName.toString(),
      avatarUrl: rawAvatar?.toString(),
      email: json['email'] as String?,
      role: json['role'] as String? ?? 'member',
      bio: json['bio'] as String?,
      experienceLevel: json['experience_level'] as String?,
      clubStatus: json['club_status'] as String?,
      favoriteGenres: json['favorite_genres'] as String?,
    );
  }
}
