import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/goals_provider.dart';
import '../../providers/achievements_provider.dart';
import '../../providers/personal_records_provider.dart';
import '../../models/fitness_goal.dart';
import '../../theme/app_theme.dart';
import '../../widgets/goals/goal_card.dart';
import '../../widgets/goals/progress_summary_card.dart';
import '../../widgets/achievements/achievements_summary.dart';
import '../../widgets/records/records_summary.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _initializeScreen();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initializeScreen() async {
    final goalsProvider = Provider.of<GoalsProvider>(context, listen: false);
    final achievementsProvider = Provider.of<AchievementsProvider>(context, listen: false);
    final recordsProvider = Provider.of<PersonalRecordsProvider>(context, listen: false);
    
    await Future.wait([
      goalsProvider.loadGoals(),
      goalsProvider.loadActiveGoals(),
      achievementsProvider.loadAchievements(),
      achievementsProvider.loadUserAchievements(),
      achievementsProvider.loadRecentAchievements(),
      recordsProvider.loadPersonalRecords(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Goals & Progress'),
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppTheme.primaryColor,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Goals'),
            Tab(text: 'Achievements'),
            Tab(text: 'Records'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildGoalsTab(),
          _buildAchievementsTab(),
          _buildRecordsTab(),
        ],
      ),
      floatingActionButton: _tabController.index == 1
          ? FloatingActionButton(
              onPressed: _showCreateGoalDialog,
              backgroundColor: AppTheme.primaryColor,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ProgressSummaryCard(),
          const SizedBox(height: 24),
          const AchievementsSummary(),
          const SizedBox(height: 24),
          const RecordsSummary(),
          const SizedBox(height: 24),
          _buildRecentActivity(),
        ],
      ),
    );
  }

  Widget _buildGoalsTab() {
    return Consumer<GoalsProvider>(
      builder: (context, goalsProvider, child) {
        if (goalsProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (goalsProvider.error != null) {
          return _buildErrorState(goalsProvider.error!, goalsProvider.loadGoals);
        }

        return DefaultTabController(
          length: 3,
          child: Column(
            children: [
              Container(
                color: Colors.white,
                child: const TabBar(
                  labelColor: AppTheme.primaryColor,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: AppTheme.primaryColor,
                  tabs: [
                    Tab(text: 'Active'),
                    Tab(text: 'Completed'),
                    Tab(text: 'All'),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _buildGoalsList(goalsProvider.inProgressGoals),
                    _buildGoalsList(goalsProvider.completedGoals),
                    _buildGoalsList(goalsProvider.goals),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGoalsList(List<FitnessGoal> goals) {
    if (goals.isEmpty) {
      return _buildEmptyGoalsState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: goals.length,
      itemBuilder: (context, index) {
        return GoalCard(goal: goals[index]);
      },
    );
  }

  Widget _buildAchievementsTab() {
    return Consumer<AchievementsProvider>(
      builder: (context, achievementsProvider, child) {
        if (achievementsProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (achievementsProvider.error != null) {
          return _buildErrorState(
            achievementsProvider.error!, 
            achievementsProvider.loadAchievements,
          );
        }

        return DefaultTabController(
          length: 2,
          child: Column(
            children: [
              Container(
                color: Colors.white,
                child: const TabBar(
                  labelColor: AppTheme.primaryColor,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: AppTheme.primaryColor,
                  tabs: [
                    Tab(text: 'Unlocked'),
                    Tab(text: 'In Progress'),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _buildAchievementsList(achievementsProvider.unlockedAchievements),
                    _buildAchievementsList(achievementsProvider.inProgressAchievements),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAchievementsList(List achievements) {
    if (achievements.isEmpty) {
      return _buildEmptyAchievementsState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: achievements.length,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
              child: Icon(
                Icons.emoji_events,
                color: AppTheme.primaryColor,
              ),
            ),
            title: Text(achievements[index].title),
            subtitle: Text(achievements[index].description),
            trailing: achievements[index].isUnlocked
                ? const Icon(Icons.check_circle, color: Colors.green)
                : Text('${achievements[index].progressPercentage.toInt()}%'),
          ),
        );
      },
    );
  }

  Widget _buildRecordsTab() {
    return Consumer<PersonalRecordsProvider>(
      builder: (context, recordsProvider, child) {
        if (recordsProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (recordsProvider.error != null) {
          return _buildErrorState(
            recordsProvider.error!, 
            recordsProvider.loadPersonalRecords,
          );
        }

        final records = recordsProvider.personalRecords;

        if (records.isEmpty) {
          return _buildEmptyRecordsState();
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: records.length,
          itemBuilder: (context, index) {
            final record = records[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                  child: Icon(
                    Icons.military_tech,
                    color: AppTheme.primaryColor,
                  ),
                ),
                title: Text('${record.activityTypeDisplay} - ${record.recordTypeDisplay}'),
                subtitle: Text(record.valueDisplay),
                trailing: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      record.timeAgo,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    if (record.improvementDisplay != null)
                      Text(
                        record.improvementDisplay!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRecentActivity() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Activity',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Consumer<AchievementsProvider>(
              builder: (context, achievementsProvider, child) {
                final recentAchievements = achievementsProvider.recentAchievements;
                
                if (recentAchievements.isEmpty) {
                  return const Text('No recent achievements');
                }

                return Column(
                  children: recentAchievements.take(3).map((achievement) {
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.emoji_events, color: Colors.amber),
                      title: Text(achievement.title),
                      subtitle: Text('Unlocked ${achievement.unlockedDate != null ? _formatDate(achievement.unlockedDate!) : 'recently'}'),
                      trailing: Text('+${achievement.pointsValue} pts'),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyGoalsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.flag,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No goals yet',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first fitness goal!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _showCreateGoalDialog,
            child: const Text('Create Goal'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyAchievementsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.emoji_events,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No achievements yet',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Complete activities to unlock achievements!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyRecordsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.military_tech,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No personal records yet',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Complete activities to set personal records!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error, VoidCallback onRetry) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            error,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  void _showCreateGoalDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Goal'),
        content: const Text('Goal creation feature coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else {
      return 'Today';
    }
  }
}