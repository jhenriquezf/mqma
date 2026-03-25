import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/api/api_client.dart';
import '../../domain/payment_model.dart';

// ── Estado del flujo ─────────────────────────────────────────────────────────

enum PaymentStep {
  idle,
  creatingBooking,
  initializingPayment,
  awaitingPayment, // browser abierto, esperando webhook + polling
  paid,
  failed,
}

class PaymentFlowState {
  final PaymentStep step;
  final String? bookingId;
  final String? token;
  final String? paymentUrl;
  final String? errorMessage;

  const PaymentFlowState({
    this.step = PaymentStep.idle,
    this.bookingId,
    this.token,
    this.paymentUrl,
    this.errorMessage,
  });

  PaymentFlowState copyWith({
    PaymentStep? step,
    String? bookingId,
    String? token,
    String? paymentUrl,
    String? errorMessage,
  }) =>
      PaymentFlowState(
        step: step ?? this.step,
        bookingId: bookingId ?? this.bookingId,
        token: token ?? this.token,
        paymentUrl: paymentUrl ?? this.paymentUrl,
        errorMessage: errorMessage ?? this.errorMessage,
      );

  bool get isLoading =>
      step == PaymentStep.creatingBooking ||
      step == PaymentStep.initializingPayment;
}

// ── Notifier ─────────────────────────────────────────────────────────────────

class PaymentFlowNotifier extends AutoDisposeNotifier<PaymentFlowState> {
  bool _polling = false;
  int _pollCount = 0;
  static const _maxPolls = 60; // 5 min a 5s por intento

  @override
  PaymentFlowState build() {
    // Detener polling cuando el provider sea descartado
    ref.onDispose(() => _polling = false);
    return const PaymentFlowState();
  }

  // ── Flujo principal ───────────────────────────────────────────────────────

  Future<void> startFlow(String eventId) async {
    final dio = ref.read(dioProvider);

    // ─ Paso 1: crear reserva ──────────────────────────────────────────────
    state = state.copyWith(step: PaymentStep.creatingBooking, errorMessage: null);
    String bookingId;
    try {
      final res = await dio.post('/events/bookings/', data: {'event_id': eventId});
      bookingId = res.data['id'] as String;
    } on DioException catch (e) {
      state = state.copyWith(
        step: PaymentStep.failed,
        errorMessage: _parseDioError(e),
      );
      return;
    } catch (_) {
      state = state.copyWith(
        step: PaymentStep.failed,
        errorMessage: 'Error al crear la reserva. Intenta nuevamente.',
      );
      return;
    }

    // ─ Paso 2: inicializar pago en Flow ───────────────────────────────────
    state = state.copyWith(
      step: PaymentStep.initializingPayment,
      bookingId: bookingId,
    );
    String paymentUrl, token;
    try {
      final res = await dio.post(
        '/payments/init/',
        data: {'booking_id': bookingId, 'provider': 'flow'},
      );
      final payment = PaymentInitModel.fromJson(
        res.data as Map<String, dynamic>,
      );
      paymentUrl = payment.paymentUrl;
      token = payment.token;
    } on DioException catch (e) {
      state = state.copyWith(
        step: PaymentStep.failed,
        errorMessage: _parseDioError(e),
      );
      return;
    } catch (_) {
      state = state.copyWith(
        step: PaymentStep.failed,
        errorMessage: 'Error al inicializar el pago.',
      );
      return;
    }

    // ─ Paso 3: abrir browser y comenzar polling ───────────────────────────
    state = state.copyWith(
      step: PaymentStep.awaitingPayment,
      token: token,
      paymentUrl: paymentUrl,
    );
    await _launchUrl(paymentUrl);
    _startPolling();
  }

  // ── Acciones desde la UI ──────────────────────────────────────────────────

  Future<void> reopenBrowser() async {
    final url = state.paymentUrl;
    if (url != null) await _launchUrl(url);
  }

  Future<void> checkNow() async {
    if (state.step != PaymentStep.awaitingPayment) return;
    await _checkStatus();
  }

  void reset() {
    _polling = false;
    state = const PaymentFlowState();
  }

  // ── Polling interno ───────────────────────────────────────────────────────

  void _startPolling() {
    if (_polling) return;
    _polling = true;
    _pollCount = 0;
    _pollLoop(); // fire-and-forget intencional
  }

  Future<void> _pollLoop() async {
    while (_polling &&
        state.step == PaymentStep.awaitingPayment &&
        _pollCount < _maxPolls) {
      await Future.delayed(const Duration(seconds: 5));
      if (!_polling || state.step != PaymentStep.awaitingPayment) break;
      await _checkStatus();
      _pollCount++;
    }
    _polling = false;
  }

  Future<void> _checkStatus() async {
    final token = state.token;
    if (token == null) return;
    try {
      final dio = ref.read(dioProvider);
      final res = await dio.get(
        '/payments/status/',
        queryParameters: {'token': token},
      );
      final status = PaymentStatusModel.fromJson(
        res.data as Map<String, dynamic>,
      );
      if (status.isPaid) {
        _polling = false;
        state = state.copyWith(step: PaymentStep.paid);
      } else if (status.isFailed) {
        _polling = false;
        state = state.copyWith(
          step: PaymentStep.failed,
          errorMessage: 'Pago rechazado o anulado por Flow.',
        );
      }
    } catch (_) {
      // Ignorar errores de polling: se reintenta automáticamente
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Future<void> _launchUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      // Si no se puede abrir, el usuario usa el botón "Abrir Flow"
    }
  }

  String _parseDioError(DioException e) {
    final data = e.response?.data;
    if (data is Map) {
      if (data['detail'] != null) return data['detail'].toString();
      for (final key in ['booking_id', 'event_id', 'non_field_errors']) {
        final val = data[key];
        if (val is List && val.isNotEmpty) return val.first.toString();
      }
    }
    return 'Error ${e.response?.statusCode ?? 'de red'}. Intenta nuevamente.';
  }
}

// ── Provider ─────────────────────────────────────────────────────────────────

final paymentFlowProvider =
    NotifierProvider.autoDispose<PaymentFlowNotifier, PaymentFlowState>(
  PaymentFlowNotifier.new,
);
