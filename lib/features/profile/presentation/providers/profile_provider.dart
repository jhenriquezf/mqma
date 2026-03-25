import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_client.dart';
import '../../domain/profile_model.dart';

class ProfileNotifier extends AsyncNotifier<ProfileModel?> {
  @override
  Future<ProfileModel?> build() async => _fetch();

  Future<ProfileModel?> _fetch() async {
    final dio = ref.read(dioProvider);
    final response = await dio.get('/users/me/');
    final profileData = response.data['profile'];
    if (profileData == null) return null;
    return ProfileModel.fromJson(profileData as Map<String, dynamic>);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  /// Guarda cambios del perfil vía PATCH /users/profile/.
  /// Retorna null si fue exitoso, o el mensaje de error si falló.
  Future<String?> saveProfile({
    String? name,
    String? bio,
    String? industry,
    String? stage,
    String? lookingFor,
    String? linkedinUrl,
    String? mbti,
    List<String>? interests,
  }) async {
    try {
      final dio = ref.read(dioProvider);
      final current = state.value;

      final Map<String, dynamic> data = {
        if (name != null) 'name': name,
        if (bio != null) 'bio': bio,
        if (industry != null) 'industry': industry,
        if (stage != null) 'stage': stage,
        if (lookingFor != null) 'looking_for': lookingFor,
        if (linkedinUrl != null) 'linkedin_url': linkedinUrl,
        if (mbti != null) 'mbti': mbti,
      };

      if (interests != null) {
        // Preservamos los tags que no son 'interest' (skills, sector)
        // para no borrarlos al actualizar solo los intereses del usuario.
        final nonInterestTags = current?.tags
                .where((t) => t.category != 'interest')
                .map((t) => t.toJson())
                .toList() ??
            [];

        final interestTags = interests
            .where((t) => t.trim().isNotEmpty)
            .map((t) => {'tag': t.trim().toLowerCase(), 'category': 'interest'})
            .toList();

        data['tags'] = [...nonInterestTags, ...interestTags];
      }

      final response = await dio.patch('/users/profile/', data: data);
      state = AsyncData(ProfileModel.fromJson(response.data as Map<String, dynamic>));
      return null;
    } on DioException catch (e) {
      final detail = e.response?.data;
      if (detail is Map) {
        final msg = detail['detail'] ?? detail.values.firstOrNull;
        return msg?.toString() ?? 'Error al guardar perfil';
      }
      return e.message ?? 'Error al guardar perfil';
    } catch (e) {
      return 'Error inesperado: $e';
    }
  }
}

final profileProvider =
    AsyncNotifierProvider<ProfileNotifier, ProfileModel?>(ProfileNotifier.new);
