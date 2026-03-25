/// Respuesta de POST /api/v1/payments/init/
class PaymentInitModel {
  final String paymentId;
  final String paymentUrl;
  final String token;

  const PaymentInitModel({
    required this.paymentId,
    required this.paymentUrl,
    required this.token,
  });

  factory PaymentInitModel.fromJson(Map<String, dynamic> json) =>
      PaymentInitModel(
        paymentId: json['payment_id'] as String,
        paymentUrl: json['payment_url'] as String,
        token: json['token'] as String,
      );
}

/// Respuesta de GET /api/v1/payments/status/?token=<token>
class PaymentStatusModel {
  final String status;        // "pending" | "paid" | "failed"
  final String bookingStatus; // "pending" | "confirmed"
  final String? paidAt;

  const PaymentStatusModel({
    required this.status,
    required this.bookingStatus,
    this.paidAt,
  });

  factory PaymentStatusModel.fromJson(Map<String, dynamic> json) =>
      PaymentStatusModel(
        status: json['status'] as String,
        bookingStatus: json['booking_status'] as String? ?? 'pending',
        paidAt: json['paid_at'] as String?,
      );

  bool get isPaid => status == 'paid';
  bool get isFailed => status == 'failed';
}
