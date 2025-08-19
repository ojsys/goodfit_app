class UserProfile {
  final int id;
  final String email;
  final String firstName;
  final String lastName;
  final bool isVerified;
  final String? bio;
  final DateTime? birthDate;
  final String? gender;
  final List<String> interests;

  UserProfile({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.isVerified,
    this.bio,
    this.birthDate,
    this.gender,
    this.interests = const [],
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      email: json['email'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      isVerified: json['is_verified'] ?? false,
      bio: json['bio'],
      birthDate: json['birth_date'] != null 
          ? DateTime.parse(json['birth_date']) 
          : null,
      gender: json['gender'],
      interests: List<String>.from(json['interests'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'is_verified': isVerified,
      'bio': bio,
      'birth_date': birthDate?.toIso8601String(),
      'gender': gender,
      'interests': interests,
    };
  }
}