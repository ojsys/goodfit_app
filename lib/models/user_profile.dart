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
  final String? datingIntentions;
  final String? phoneNumber;
  
  // Fitness profile fields
  final String? activityLevel;
  final List<String>? fitnessGoals;
  final List<String>? favoriteActivities;
  final int? workoutFrequency;
  final String? preferredWorkoutTime;
  final String? gymMembership;
  final String? injuriesLimitations;

  // Privacy settings
  final bool? showProfilePublicly;
  final bool? showFitnessData;
  final bool? showLocation;
  final bool? showOnlineStatus;
  final bool? allowMessagesFromStrangers;
  final bool? showInDiscovery;
  final bool? shareWorkoutData;
  final bool? showAge;
  final bool? showDistance;

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
    this.datingIntentions,
    this.phoneNumber,
    // Fitness profile
    this.activityLevel,
    this.fitnessGoals,
    this.favoriteActivities,
    this.workoutFrequency,
    this.preferredWorkoutTime,
    this.gymMembership,
    this.injuriesLimitations,
    // Privacy settings
    this.showProfilePublicly,
    this.showFitnessData,
    this.showLocation,
    this.showOnlineStatus,
    this.allowMessagesFromStrangers,
    this.showInDiscovery,
    this.shareWorkoutData,
    this.showAge,
    this.showDistance,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] ?? 0,
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
      datingIntentions: json['dating_intentions'],
      phoneNumber: json['phone_number'],
      // Fitness profile
      activityLevel: json['activity_level'],
      fitnessGoals: json['fitness_goals'] != null 
          ? List<String>.from(json['fitness_goals']) 
          : null,
      favoriteActivities: json['favorite_activities'] != null 
          ? List<String>.from(json['favorite_activities']) 
          : null,
      workoutFrequency: json['workout_frequency'],
      preferredWorkoutTime: json['preferred_workout_time'],
      gymMembership: json['gym_membership'],
      injuriesLimitations: json['injuries_limitations'],
      // Privacy settings
      showProfilePublicly: json['show_profile_publicly'],
      showFitnessData: json['show_fitness_data'],
      showLocation: json['show_location'],
      showOnlineStatus: json['show_online_status'],
      allowMessagesFromStrangers: json['allow_messages_from_strangers'],
      showInDiscovery: json['show_in_discovery'],
      shareWorkoutData: json['share_workout_data'],
      showAge: json['show_age'],
      showDistance: json['show_distance'],
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
      'birth_date': birthDate?.toIso8601String().split('T')[0],
      'gender': gender,
      'interests': interests,
      'dating_intentions': datingIntentions,
      'phone_number': phoneNumber,
      // Fitness profile
      'activity_level': activityLevel,
      'fitness_goals': fitnessGoals,
      'favorite_activities': favoriteActivities,
      'workout_frequency': workoutFrequency,
      'preferred_workout_time': preferredWorkoutTime,
      'gym_membership': gymMembership,
      'injuries_limitations': injuriesLimitations,
      // Privacy settings
      'show_profile_publicly': showProfilePublicly,
      'show_fitness_data': showFitnessData,
      'show_location': showLocation,
      'show_online_status': showOnlineStatus,
      'allow_messages_from_strangers': allowMessagesFromStrangers,
      'show_in_discovery': showInDiscovery,
      'share_workout_data': shareWorkoutData,
      'show_age': showAge,
      'show_distance': showDistance,
    };
  }
}