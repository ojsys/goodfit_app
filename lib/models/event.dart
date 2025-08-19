class Event {
  final int id;
  final String title;
  final String description;
  final DateTime dateTime;
  final String? location;
  final String? activityType;
  final int organizerId;
  final String? organizerName;
  final int attendeeCount;
  final bool isAttending;

  Event({
    required this.id,
    required this.title,
    required this.description,
    required this.dateTime,
    this.location,
    this.activityType,
    required this.organizerId,
    this.organizerName,
    required this.attendeeCount,
    required this.isAttending,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      dateTime: DateTime.parse(json['date_time']),
      location: json['location'],
      activityType: json['activity_type'],
      organizerId: json['organizer_id'] ?? json['organizer']?['id'],
      organizerName: json['organizer_name'] ?? json['organizer']?['name'],
      attendeeCount: json['attendee_count'] ?? 0,
      isAttending: json['is_attending'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'date_time': dateTime.toIso8601String(),
      'location': location,
      'activity_type': activityType,
      'organizer_id': organizerId,
      'organizer_name': organizerName,
      'attendee_count': attendeeCount,
      'is_attending': isAttending,
    };
  }
}