class BookingModel {
  final String id;
  final String status;
  final String? paymentStatus;
  final bool checkedIn;
  final String createdAt;

  const BookingModel({
    required this.id,
    required this.status,
    this.paymentStatus,
    required this.checkedIn,
    required this.createdAt,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) => BookingModel(
        id: json['id'] as String,
        status: json['status'] as String,
        paymentStatus: json['payment_status'] as String?,
        checkedIn: json['checked_in'] as bool? ?? false,
        createdAt: json['created_at'] as String,
      );
}
