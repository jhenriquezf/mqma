class EventModel {
  final String id;
  final String cityName;
  final String restaurantName;
  final String restaurantAddress;
  final String eventDate;
  final String eventTime;
  final int capacity;
  final int spotsLeft;
  final int priceCLP;
  final String status;
  final String type;
  final String? notes;

  const EventModel({
    required this.id, required this.cityName, required this.restaurantName,
    required this.restaurantAddress, required this.eventDate, required this.eventTime,
    required this.capacity, required this.spotsLeft, required this.priceCLP,
    required this.status, required this.type, this.notes,
  });

  factory EventModel.fromJson(Map<String, dynamic> json) => EventModel(
    id: json['id'] as String,
    cityName: json['city_name'] as String? ?? '',
    restaurantName: json['restaurant_name'] as String? ?? '',
    restaurantAddress: json['restaurant_address'] as String? ?? '',
    eventDate: json['event_date'] as String,
    eventTime: json['event_time'] as String,
    capacity: json['capacity'] as int? ?? 0,
    spotsLeft: json['spots_left'] as int? ?? 0,
    priceCLP: json['price_clp'] as int? ?? 0,
    status: json['status'] as String? ?? '',
    type: json['type'] as String? ?? 'dinner',
    notes: json['notes'] as String?,
  );
}
