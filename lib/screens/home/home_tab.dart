import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/fitness_provider.dart';
import '../../providers/goals_provider.dart';
import '../../providers/routes_provider.dart';
import '../../providers/achievements_provider.dart';
import '../../providers/personal_records_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/todays_activities_section.dart';
import '../../widgets/home/quick_actions_section.dart';
import '../../widgets/home/fitness_overview_section.dart';
import '../../widgets/home/goals_preview_section.dart';
import '../../widgets/home/routes_preview_section.dart';
import '../../widgets/home/workout_matches_section.dart';
import '../../widgets/home/social_feed_section.dart';
import '../../theme/app_theme.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  @override
  void initState() {
    super.initState();
    // Defer initialization to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  Future<void> _initializeData() async {
    // Initialize all providers with data
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final fitnessProvider = Provider.of<FitnessProvider>(context, listen: false);
    final goalsProvider = Provider.of<GoalsProvider>(context, listen: false);
    final routesProvider = Provider.of<RoutesProvider>(context, listen: false);
    final achievementsProvider = Provider.of<AchievementsProvider>(context, listen: false);
    final recordsProvider = Provider.of<PersonalRecordsProvider>(context, listen: false);
    
    // Set current user in providers for user-specific filtering
    fitnessProvider.setCurrentUser(authProvider.user);
    goalsProvider.setCurrentUser(authProvider.user);
    
    await Future.wait([
      fitnessProvider.loadActivities(),
      goalsProvider.loadActiveGoals(),
      routesProvider.loadPopularRoutes(),
      achievementsProvider.loadRecentAchievements(),
      recordsProvider.loadPersonalRecords(),
    ]);
  }

  String _getTimeBasedGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 17) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }

  String _getPersonalizedGreeting(String? firstName) {
    final greeting = _getTimeBasedGreeting();
    if (firstName != null && firstName.isNotEmpty) {
      return '$greeting, $firstName!';
    }
    return '$greeting!';
  }

  void refreshData() {
    _initializeData();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // Update providers when auth state changes
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final fitnessProvider = Provider.of<FitnessProvider>(context, listen: false);
          final goalsProvider = Provider.of<GoalsProvider>(context, listen: false);
          fitnessProvider.setCurrentUser(authProvider.user);
          goalsProvider.setCurrentUser(authProvider.user);
        });

        return Scaffold(
          backgroundColor: Colors.grey.shade50,
          body: RefreshIndicator(
            onRefresh: _initializeData,
            child: CustomScrollView(
              slivers: [
                _buildAppBar(),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const QuickActionsSection(),
                        const SizedBox(height: 24),
                        const FitnessOverviewSection(),
                        const SizedBox(height: 24),
                        const TodaysActivitiesSection(),
                        const SizedBox(height: 24),
                        const GoalsPreviewSection(),
                        const SizedBox(height: 24),
                        const RoutesPreviewSection(),
                        const SizedBox(height: 24),
                        const WorkoutMatchesSection(),
                        const SizedBox(height: 24),
                        const SocialFeedSection(),
                        const SizedBox(height: 100), // Space for FAB
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 140,
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
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Consumer<AuthProvider>(
                              builder: (context, authProvider, child) {
                                return Text(
                                  _getPersonalizedGreeting(authProvider.user?.firstName),
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.8),
                                    fontSize: 16,
                                    height: 1.2,
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Ready for today\'s workout?',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                height: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      PopupMenuButton<String>(
                        onSelected: (value) async {
                          if (value == 'logout') {
                            final authProvider = Provider.of<AuthProvider>(context, listen: false);
                            await authProvider.logout();
                            if (mounted) {
                              Navigator.pushNamedAndRemoveUntil(context, '/welcome', (route) => false);
                            }
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'logout',
                            child: Row(
                              children: [
                                Icon(Icons.logout, size: 20),
                                SizedBox(width: 8),
                                Text('Logout'),
                              ],
                            ),
                          ),
                        ],
                        icon: const Icon(
                          Icons.more_vert,
                          color: Colors.white,
                        ),
                        constraints: const BoxConstraints(
                          minHeight: 40,
                          minWidth: 40,
                        ),
                        padding: const EdgeInsets.all(8),
                      ),
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        child: const Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}