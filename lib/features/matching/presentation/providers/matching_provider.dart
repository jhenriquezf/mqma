import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_client.dart';
import '../../domain/match_group_model.dart';

/// Retorna null cuando el grupo aún no está disponible (404 del backend).
/// Lanza error solo ante fallas reales de red o servidor.
final matchGroupProvider =
    FutureProvider.autoDispose.family<MatchGroupModel?, String>((ref, eventId) async {
  final dio = ref.watch(dioProvider);
  try {
    final response = await dio.get(
      '/matching/my-group/',
      queryParameters: {'event': eventId},
    );
    return MatchGroupModel.fromJson(response.data as Map<String, dynamic>);
  } on DioException catch (e) {
    if (e.response?.statusCode == 404) return null;
    rethrow;
  }
});
