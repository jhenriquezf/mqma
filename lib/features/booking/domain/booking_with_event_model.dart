class EventSummaryModel {
  final String id;
  final String eventDate;
  final String eventTime;
  final String? restaurantName;
  final String? restaurantAddress;
  final String cityName;
  final String typeDisplay;
  final int priceCLP;
  final String status;

  const EventSummaryModel({
    required this.id,
    required this.eventDate,
    required this.eventTime,
    this.restaurantName,
    this.restaurantAddress,
    required this.cityName,
    required this.typeDisplay,
    required this.priceCLP,
    required this.status,
  });

  factory EventSummaryModel.fromJson(Map<String, dynamic> json) =>
      EventSummaryModel(
        id: json['id'] as String,
        eventDate: json['event_date'] as String,
        eventTime: json['event_time'] as String,
        restaurantName: json['restaurant_name'] as String?,
        restaurantAddress: json['restaurant_address'] as String?,
        cityName: json['city_name'] as String? ?? '',
        typeDisplay: json['type_display'] as String? ?? '',
        priceCLP: (json['price_clp'] as num?)?.toInt() ?? 0,
        status: json['status'] as String,
      );
}

class BookingWithEventModel {
  final String id;
  final String status;
  final bool checkedIn;
  final String? paymentStatus;
  final String createdAt;
  final EventSummaryModel event;

  const BookingWithEventModel({
    required this.id,
    required this.status,
    required this.checkedIn,
    this.paymentStatus,
    required this.createdAt,
    required this.event,
  });

  factory BookingWithEventModel.fromJson(Map<String, dynamic> json) =>
      BookingWithEventModel(
        id: json['id'] as String,
        status: json['status'] as String,
        checkedIn: json['checked_in'] as bool? ?? false,
        paymentStatus: json['payment_status'] as String?,
        createdAt: json['created_at'] as String,
        event: EventSummaryModel.fromJson(
          json['event'] as Map<String, dynamic>,
        ),
      );
}
