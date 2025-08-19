class User {
  final int id;
  final String email;
  final String firstName;
  final String lastName;
  final bool isVerified;

  User({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.isVerified,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      isVerified: json['is_verified'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'is_verified': isVerified,
    };
  }
}