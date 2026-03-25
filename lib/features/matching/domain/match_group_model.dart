class MatchMemberModel {
  final String userId;
  final String name;
  final String industry;
  final String stage;
  final String lookingFor;
  final String? mbti;

  const MatchMemberModel({
    required this.userId,
    required this.name,
    required this.industry,
    required this.stage,
    required this.lookingFor,
    this.mbti,
  });

  factory MatchMemberModel.fromJson(Map<String, dynamic> json) =>
      MatchMemberModel(
        userId: json['user_id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        industry: json['industry'] as String? ?? '',
        stage: json['stage'] as String? ?? '',
        lookingFor: json['looking_for'] as String? ?? '',
        mbti: (json['mbti'] as String?)?.isNotEmpty == true
            ? json['mbti'] as String
            : null,
      );
}

class MatchGroupModel {
  final String id;
  final int? tableNumber;
  final String eventDate;
  final String eventTime;
  final String restaurantName;
  final String restaurantAddress;
  final List<MatchMemberModel> members;

  const MatchGroupModel({
    required this.id,
    this.tableNumber,
    required this.eventDate,
    required this.eventTime,
    required this.restaurantName,
    required this.restaurantAddress,
    required this.members,
  });

  factory MatchGroupModel.fromJson(Map<String, dynamic> json) =>
      MatchGroupModel(
        id: json['id'] as String,
        tableNumber: json['table_number'] as int?,
        eventDate: json['event_date'] as String? ?? '',
        eventTime: json['event_time'] as String? ?? '',
        restaurantName: json['restaurant_name'] as String? ?? '',
        restaurantAddress: json['restaurant_address'] as String? ?? '',
        members: (json['members'] as List<dynamic>? ?? [])
            .map((e) => MatchMemberModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
