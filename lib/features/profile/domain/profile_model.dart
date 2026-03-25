class ProfileTagModel {
  final String id;
  final String tag;
  final String category;

  const ProfileTagModel({
    required this.id,
    required this.tag,
    required this.category,
  });

  factory ProfileTagModel.fromJson(Map<String, dynamic> json) => ProfileTagModel(
        id: json['id'].toString(),
        tag: json['tag'] as String,
        category: json['category'] as String,
      );

  Map<String, dynamic> toJson() => {'tag': tag, 'category': category};
}

class ProfileModel {
  final String id;
  final String email;
  final String? name;
  final int? age;
  final String? bio;
  final String? industry;
  final String? stage;
  final String? lookingFor;
  final String? linkedinUrl;
  final String? mbti;
  final double? npsAvg;
  final bool onboardingComplete;
  final List<ProfileTagModel> tags;

  const ProfileModel({
    required this.id,
    required this.email,
    this.name,
    this.age,
    this.bio,
    this.industry,
    this.stage,
    this.lookingFor,
    this.linkedinUrl,
    this.mbti,
    this.npsAvg,
    required this.onboardingComplete,
    required this.tags,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) => ProfileModel(
        id: json['id'].toString(),
        email: json['email'] as String? ?? '',
        name: json['name'] as String?,
        age: json['age'] as int?,
        bio: json['bio'] as String?,
        industry: json['industry'] as String?,
        stage: json['stage'] as String?,
        lookingFor: json['looking_for'] as String?,
        linkedinUrl: json['linkedin_url'] as String?,
        mbti: json['mbti'] as String?,
        npsAvg: (json['nps_avg'] as num?)?.toDouble(),
        onboardingComplete: json['onboarding_complete'] as bool? ?? false,
        tags: (json['tags'] as List<dynamic>?)
                ?.map((t) => ProfileTagModel.fromJson(t as Map<String, dynamic>))
                .toList() ??
            [],
      );

  List<ProfileTagModel> get interestTags =>
      tags.where((t) => t.category == 'interest').toList();

  /// Nombre para mostrar; si no hay nombre, usa la parte local del email.
  String get displayName =>
      (name?.trim().isNotEmpty == true) ? name! : email.split('@').first;

  /// Iniciales para el avatar (máximo 2 letras).
  String get initials {
    final n = name?.trim();
    if (n == null || n.isEmpty) {
      return email.isNotEmpty ? email[0].toUpperCase() : '?';
    }
    final parts = n.split(RegExp(r'\s+'));
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return parts[0][0].toUpperCase();
  }
}
