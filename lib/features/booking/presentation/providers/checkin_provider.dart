import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_client.dart';
import '../../domain/booking_with_event_model.dart';

// Carga todas las reservas del usuario que son relevantes para check-in
// (confirmed o attended de eventos futuros/recientes)
final checkinBookingsProvider =
    FutureProvider.autoDispose<List<BookingWithEventModel>>((ref) async {
  final dio = ref.read(dioProvider);
  final response = await dio.get('/events/bookings/');
  final list = response.data as List<dynamic>;
  return list
      .map((e) => BookingWithEventModel.fromJson(e as Map<String, dynamic>))
      .where((b) => b.status == 'confirmed' || b.status == 'attended')
      .toList();
});

// Estado del check-in: null=inicial, String=booking_id exitoso
class CheckinNotifier extends AutoDisposeAsyncNotifier<String?> {
  @override
  Future<String?> build() async => null;

  Future<void> checkin(String bookingId) async {
    state = const AsyncLoading();
    try {
      final dio = ref.read(dioProvider);
      await dio.post('/events/checkin/', data: {'booking_id': bookingId});
      state = AsyncData(bookingId);
      ref.invalidate(checkinBookingsProvider);
    } on DioException catch (e) {
      state = AsyncError(_parseError(e), StackTrace.current);
    } catch (e, st) {
      state = AsyncError('Error inesperado. Intenta nuevamente.', st);
    }
  }

  void reset() => state = const AsyncData(null);

  String _parseError(DioException e) {
    final data = e.response?.data;
    if (data is Map) {
      if (data['detail'] != null) return data['detail'].toString();
      final bookingIdErrors = data['booking_id'];
      if (bookingIdErrors is List && bookingIdErrors.isNotEmpty) {
        return bookingIdErrors.first.toString();
      }
    }
    return 'No se pudo registrar el check-in.';
  }
}

final checkinProvider =
    AsyncNotifierProvider.autoDispose<CheckinNotifier, String?>(
  CheckinNotifier.new,
);
