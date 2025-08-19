import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/goals_provider.dart';
import '../../providers/achievements_provider.dart';
import '../../theme/app_theme.dart';

class ProgressSummaryCard extends StatelessWidget {
  const ProgressSummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<GoalsProvider, AchievementsProvider>(
      builder: (context, goalsProvider, achievementsProvider, child) {
        final activeGoals = goalsProvider.activeGoals;
        final completedGoals = goalsProvider.completedGoals;
        final overallProgress = goalsProvider.getOverallProgress();
        final totalPoints = achievementsProvider.totalPoints;
        final unlockedAchievements = achievementsProvider.unlockedAchievements.length;

        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.primaryColor,
                  AppTheme.primaryColor.withValues(alpha: 0.8),
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
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.trending_up,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Your Progress',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Keep pushing your limits!',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Overall Progress Bar
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Overall Goals Progress',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '${overallProgress.toInt()}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: overallProgress / 100,
                      backgroundColor: Colors.white.withValues(alpha: 0.3),
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                      minHeight: 6,
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Stats Row
                Row(
                  children: [
                    Expanded(
                      child: _buildStatItem(
                        'Active Goals',
                        activeGoals.length.toString(),
                        Icons.flag,
                      ),
                    ),
                    Expanded(
                      child: _buildStatItem(
                        'Completed',
                        completedGoals.length.toString(),
                        Icons.check_circle,
                      ),
                    ),
                    Expanded(
                      child: _buildStatItem(
                        'Achievements',
                        unlockedAchievements.toString(),
                        Icons.emoji_events,
                      ),
                    ),
                    Expanded(
                      child: _buildStatItem(
                        'Points',
                        totalPoints.toString(),
                        Icons.star,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 20,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}