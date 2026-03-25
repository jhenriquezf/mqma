import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_client.dart';
import '../../domain/booking_model.dart';

class BookingNotifier extends AutoDisposeAsyncNotifier<BookingModel?> {
  @override
  Future<BookingModel?> build() async => null;

  Future<void> createBooking(String eventId) async {
    state = const AsyncLoading();
    try {
      final dio = ref.read(dioProvider);
      final response = await dio.post(
        '/events/bookings/',
        data: {'event_id': eventId},
      );
      state = AsyncData(
        BookingModel.fromJson(response.data as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      state = AsyncError(_parseError(e), StackTrace.current);
    } catch (e, st) {
      state = AsyncError('Error inesperado. Intenta nuevamente.', st);
    }
  }

  String _parseError(DioException e) {
    final data = e.response?.data;
    if (data is Map) {
      final eventIdErrors = data['event_id'];
      if (eventIdErrors is List && eventIdErrors.isNotEmpty) {
        return eventIdErrors.first.toString();
      }
      final nonFieldErrors = data['non_field_errors'];
      if (nonFieldErrors is List && nonFieldErrors.isNotEmpty) {
        return nonFieldErrors.first.toString();
      }
      if (data['detail'] != null) return data['detail'].toString();
    }
    return 'No se pudo crear la reserva.';
  }
}

final bookingProvider =
    AsyncNotifierProvider.autoDispose<BookingNotifier, BookingModel?>(
  BookingNotifier.new,
);
