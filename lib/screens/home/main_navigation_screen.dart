import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/unified_create_modal.dart';
import '../../providers/auth_provider.dart';
import '../../providers/fitness_provider.dart';
import '../profile/edit_profile_screen.dart';
import 'home_tab.dart';
import '../routes/routes_discovery_screen.dart';
import '../goals/goals_screen.dart';
import '../social/community_screen.dart';
import '../map/workout_map_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeTab(),
    const RoutesDiscoveryScreen(),
    const GoalsScreen(),
    const CommunityScreen(),
    const ProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      floatingActionButton: FloatingActionButton(
        onPressed: _showUnifiedCreateModal,
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(child: _buildBottomNavItem(Icons.home, 'Home', 0)),
                Expanded(child: _buildBottomNavItem(Icons.route, 'Routes', 1)),
                Expanded(child: _buildBottomNavItem(Icons.flag, 'Goals', 2)),
                Expanded(child: _buildBottomNavItem(Icons.people, 'Social', 3)),
                Expanded(child: _buildBottomNavItem(Icons.person, 'Profile', 4)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavItem(IconData icon, String label, int index) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? AppTheme.primaryColor : Colors.grey,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppTheme.primaryColor : Colors.grey,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showUnifiedCreateModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const UnifiedCreateModal(),
    );
  }

}

class MapTab extends StatelessWidget {
  const MapTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const WorkoutMapScreen();
  }
}

class EventsTab extends StatelessWidget {
  const EventsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Events'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: const Center(
        child: Text(
          'Events Tab\nComing Soon!',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            color: Colors.grey,
          ),
        ),
      ),
    );
  }
}

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, FitnessProvider>(
      builder: (context, authProvider, fitnessProvider, child) {
        final user = authProvider.user;
        final userProfile = authProvider.userProfile;
        
        return Scaffold(
          backgroundColor: Colors.grey.shade50,
          body: CustomScrollView(
            slivers: [
              _buildProfileHeader(context, user, userProfile),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStatsSection(fitnessProvider),
                      const SizedBox(height: 24),
                      _buildProfileSection(context, userProfile),
                      const SizedBox(height: 24),
                      _buildSettingsSection(context, authProvider),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProfileHeader(BuildContext context, user, userProfile) {
    return SliverAppBar(
      expandedHeight: 220,
      floating: false,
      pinned: true,
      backgroundColor: AppTheme.primaryColor,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.primaryColor,
                AppTheme.primaryColor.withValues(alpha: 0.8),
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    child: user != null
                        ? Text(
                            '${user.firstName[0]}${user.lastName[0]}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 40,
                          ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    user != null ? '${user.firstName} ${user.lastName}' : 'User',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.email ?? '',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsSection(FitnessProvider fitnessProvider) {
    final totalActivities = fitnessProvider.activities.length;
    final totalDistance = fitnessProvider.activities.fold<double>(
      0.0,
      (sum, activity) => sum + (activity.distanceKm ?? 0.0),
    );
    final totalDuration = fitnessProvider.activities.fold<int>(
      0,
      (sum, activity) => sum + activity.durationMinutes,
    );
    final totalCalories = fitnessProvider.activities.fold<int>(
      0,
      (sum, activity) => sum + (activity.caloriesBurned ?? 0),
    );

    // Calculate this week's stats
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final thisWeekActivities = fitnessProvider.activities.where((activity) {
      return activity.startTime.isAfter(weekStart);
    }).toList();

    return Column(
      children: [
        // Overall Stats Card
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.primaryColor.withValues(alpha: 0.1),
                  AppTheme.primaryColor.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.assessment, color: AppTheme.primaryColor, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Lifetime Stats',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(child: _buildStatItem('Activities', '$totalActivities', Icons.fitness_center, Colors.blue)),
                    Expanded(child: _buildStatItem('Distance', '${totalDistance.toStringAsFixed(1)} km', Icons.straighten, Colors.green)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildStatItem('Time', '${(totalDuration / 60).toStringAsFixed(1)} hrs', Icons.timer, Colors.orange)),
                    Expanded(child: _buildStatItem('Calories', '$totalCalories cal', Icons.local_fire_department, Colors.red)),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        
        // This Week's Progress Card
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.purple.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.trending_up, color: Colors.purple, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'This Week',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.purple.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${thisWeekActivities.length} workouts',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.purple,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildWeeklyProgress(thisWeekActivities),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildWeeklyProgress(List thisWeekActivities) {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: List.generate(7, (index) {
        final day = weekStart.add(Duration(days: index));
        final dayActivities = thisWeekActivities.where((activity) {
          final activityDate = activity.startTime;
          return activityDate.year == day.year &&
                 activityDate.month == day.month &&
                 activityDate.day == day.day;
        }).length;
        
        final isToday = day.day == now.day && day.month == now.month;
        final hasActivity = dayActivities > 0;
        
        return Column(
          children: [
            Text(
              days[index],
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isToday ? Colors.purple : Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: hasActivity 
                    ? Colors.purple 
                    : (isToday ? Colors.purple.withValues(alpha: 0.3) : Colors.grey.shade200),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: hasActivity
                    ? Text(
                        dayActivities.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : (isToday
                        ? const Icon(Icons.today, color: Colors.purple, size: 16)
                        : null),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildProfileSection(BuildContext context, userProfile) {
    return Column(
      children: [
        // About Me Card
        if (userProfile?.bio != null) ...[
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'About Me',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    userProfile?.bio ?? '',
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Personal Details Card
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.teal.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.person_outline, color: Colors.teal, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Personal Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => _navigateToEditProfile(context),
                      child: const Text('Edit'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildDetailGrid([
                  if (userProfile?.birthDate != null)
                    _buildDetailItem(
                      'Age',
                      '${DateTime.now().year - (userProfile?.birthDate?.year ?? DateTime.now().year)} years old',
                      Icons.cake_outlined,
                    ),
                  if (userProfile?.gender != null)
                    _buildDetailItem(
                      'Gender',
                      _getGenderDisplay(userProfile?.gender ?? ''),
                      Icons.person,
                    ),
                  _buildDetailItem(
                    'Email',
                    userProfile?.email ?? 'Not provided',
                    Icons.email_outlined,
                  ),
                  _buildDetailItem(
                    'Verified',
                    userProfile?.isVerified == true ? 'Yes' : 'No',
                    userProfile?.isVerified == true ? Icons.verified : Icons.pending,
                  ),
                ]),
              ],
            ),
          ),
        ),

        // Interests Card
        if (userProfile?.interests.isNotEmpty ?? false) ...[
          const SizedBox(height: 16),
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.pink.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.favorite_outline, color: Colors.pink, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Interests',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => _navigateToEditProfile(context),
                        child: const Text('Edit'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: (userProfile?.interests ?? []).map<Widget>((interest) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.pink.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.pink.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          interest.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.pink,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
        ],

        // Fitness Profile Section
        const SizedBox(height: 16),
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.fitness_center, color: Colors.orange, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Fitness Profile',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const EditProfileScreen(initialTabIndex: 1),
                        ),
                      ),
                      child: const Text('Edit'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildFitnessDetails(userProfile),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailGrid(List<Widget> children) {
    if (children.isEmpty) {
      return const Text(
        'No additional information available.',
        style: TextStyle(color: Colors.grey),
      );
    }

    return Column(
      children: [
        for (int i = 0; i < children.length; i += 2)
          Padding(
            padding: EdgeInsets.only(bottom: i + 2 < children.length ? 12 : 0),
            child: Row(
              children: [
                Expanded(child: children[i]),
                if (i + 1 < children.length) ...[
                  const SizedBox(width: 16),
                  Expanded(child: children[i + 1]),
                ] else
                  const Expanded(child: SizedBox()),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildDetailItem(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.teal, size: 20),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _getGenderDisplay(String gender) {
    switch (gender.toUpperCase()) {
      case 'M':
        return 'Male';
      case 'F':
        return 'Female';
      case 'NB':
        return 'Non-binary';
      case 'O':
        return 'Other';
      case 'P':
        return 'Prefer not to say';
      default:
        return gender;
    }
  }

  Widget _buildFitnessDetails(userProfile) {
    final hasFitnessData = userProfile?.activityLevel != null ||
        (userProfile?.fitnessGoals?.isNotEmpty ?? false) ||
        (userProfile?.favoriteActivities?.isNotEmpty ?? false) ||
        userProfile?.workoutFrequency != null;

    if (!hasFitnessData) {
      return Column(
        children: [
          Icon(
            Icons.fitness_center,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 12),
          const Text(
            'No Fitness Data Available',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Update your fitness profile to see your preferences here',
            style: TextStyle(
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    return _buildDetailGrid([
      if (userProfile?.activityLevel != null)
        _buildDetailItem(
          'Activity Level',
          _getActivityLevelDisplay(userProfile?.activityLevel ?? ''),
          Icons.trending_up,
        ),
      if (userProfile?.workoutFrequency != null)
        _buildDetailItem(
          'Workout Frequency',
          '${userProfile?.workoutFrequency ?? 0} times/week',
          Icons.schedule,
        ),
      if (userProfile?.preferredWorkoutTime != null)
        _buildDetailItem(
          'Preferred Time',
          _getWorkoutTimeDisplay(userProfile?.preferredWorkoutTime ?? ''),
          Icons.access_time,
        ),
      if (userProfile?.gymMembership != null && (userProfile?.gymMembership?.isNotEmpty ?? false))
        _buildDetailItem(
          'Gym',
          userProfile?.gymMembership ?? '',
          Icons.fitness_center,
        ),
      if (userProfile?.fitnessGoals?.isNotEmpty ?? false)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.flag_outlined, color: Colors.orange, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Fitness Goals',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: (userProfile?.fitnessGoals ?? []).map<Widget>((goal) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      goal.replaceAll('_', ' ').toUpperCase(),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: Colors.orange,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      if (userProfile?.favoriteActivities?.isNotEmpty ?? false)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.sports, color: Colors.blue, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Favorite Activities',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: (userProfile?.favoriteActivities ?? []).map<Widget>((activity) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      activity.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: Colors.blue,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
    ]);
  }

  String _getActivityLevelDisplay(String level) {
    switch (level.toLowerCase()) {
      case 'sedentary':
        return 'Sedentary';
      case 'lightly_active':
        return 'Lightly Active';
      case 'moderately_active':
        return 'Moderately Active';
      case 'very_active':
        return 'Very Active';
      case 'extremely_active':
        return 'Extremely Active';
      default:
        return level.replaceAll('_', ' ');
    }
  }

  String _getWorkoutTimeDisplay(String time) {
    switch (time.toLowerCase()) {
      case 'early_morning':
        return 'Early Morning';
      case 'morning':
        return 'Morning';
      case 'afternoon':
        return 'Afternoon';
      case 'evening':
        return 'Evening';
      case 'night':
        return 'Night';
      case 'flexible':
        return 'Flexible';
      default:
        return time.replaceAll('_', ' ');
    }
  }

  void _navigateToEditProfile(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const EditProfileScreen(),
      ),
    );
  }

  Widget _buildSettingsSection(BuildContext context, AuthProvider authProvider) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Settings',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildSettingsItem(
              'Edit Profile',
              'Update your personal information',
              Icons.edit_outlined,
              () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const EditProfileScreen(),
                  ),
                );
              },
            ),
            const Divider(height: 32),
            _buildSettingsItem(
              'Privacy Settings',
              'Manage your privacy preferences',
              Icons.privacy_tip_outlined,
              () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const EditProfileScreen(initialTabIndex: 2),
                  ),
                );
              },
            ),
            const Divider(height: 32),
            _buildSettingsItem(
              'Logout',
              'Sign out of your account',
              Icons.logout,
              () async {
                final result = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Logout'),
                    content: const Text('Are you sure you want to logout?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('Logout'),
                      ),
                    ],
                  ),
                );

                if (result == true) {
                  await authProvider.logout();
                  if (context.mounted) {
                    Navigator.pushNamedAndRemoveUntil(context, '/welcome', (route) => false);
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsItem(String title, String subtitle, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: AppTheme.primaryColor, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }
}