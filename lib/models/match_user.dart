class MatchUser {
  final int id;
  final String firstName;
  final String lastName;
  final String? bio;
  final int? age;
  final String? profilePhoto;
  final List<String> interests;
  final String? location;
  final double? distance;
  final bool isMatch;

  MatchUser({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.bio,
    this.age,
    this.profilePhoto,
    this.interests = const [],
    this.location,
    this.distance,
    required this.isMatch,
  });

  String get fullName => '$firstName $lastName';

  factory MatchUser.fromJson(Map<String, dynamic> json) {
    return MatchUser(
      id: json['id'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      bio: json['bio'],
      age: json['age'],
      profilePhoto: json['profile_photo'],
      interests: List<String>.from(json['interests'] ?? []),
      location: json['location'],
      distance: json['distance']?.toDouble(),
      isMatch: json['is_match'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'bio': bio,
      'age': age,
      'profile_photo': profilePhoto,
      'interests': interests,
      'location': location,
      'distance': distance,
      'is_match': isMatch,
    };
  }
}