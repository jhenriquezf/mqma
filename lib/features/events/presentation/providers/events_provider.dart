import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_client.dart';
import '../../domain/event_model.dart';

final eventsProvider = FutureProvider<List<EventModel>>((ref) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get('/events/');
  final raw = response.data;
  final List data = raw is List ? raw : (raw['results'] as List? ?? []);
  return data.map((e) => EventModel.fromJson(e as Map<String, dynamic>)).toList();
});

final eventDetailProvider = FutureProvider.family<EventModel, String>((ref, id) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get('/events/$id/');
  return EventModel.fromJson(response.data as Map<String, dynamic>);
});
