import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/fitness_provider.dart';
import '../../providers/goals_provider.dart';
import '../../providers/achievements_provider.dart';
import '../../theme/app_theme.dart';

class FitnessOverviewSection extends StatelessWidget {
  const FitnessOverviewSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer3<FitnessProvider, GoalsProvider, AchievementsProvider>(
      builder: (context, fitnessProvider, goalsProvider, achievementsProvider, child) {
        final todaysActivities = fitnessProvider.todaysActivities;
        final activeGoals = goalsProvider.activeGoals;
        final totalPoints = achievementsProvider.totalPoints;
        
        // Calculate today's stats
        final todaysDistance = todaysActivities.fold<double>(
          0.0,
          (sum, activity) => sum + (activity.distanceKm ?? 0.0),
        );
        final todaysCalories = todaysActivities.fold<int>(
          0,
          (sum, activity) => sum + (activity.caloriesBurned ?? 0),
        );
        final todaysDuration = todaysActivities.fold<int>(
          0,
          (sum, activity) => sum + activity.durationMinutes,
        );

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
                      child: Icon(
                        Icons.dashboard,
                        color: AppTheme.primaryColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Today\'s Overview',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                
                // Stats Grid
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Activities',
                        todaysActivities.length.toString(),
                        Icons.fitness_center,
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'Distance',
                        '${todaysDistance.toStringAsFixed(1)} km',
                        Icons.straighten,
                        Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Duration',
                        '${todaysDuration} min',
                        Icons.timer,
                        Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'Calories',
                        '${todaysCalories} cal',
                        Icons.local_fire_department,
                        Colors.red,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 16),
                
                // Quick Info Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildQuickInfo(
                      'Active Goals',
                      activeGoals.length.toString(),
                      Icons.flag,
                    ),
                    _buildQuickInfo(
                      'Total Points',
                      totalPoints.toString(),
                      Icons.star,
                    ),
                    _buildQuickInfo(
                      'This Week',
                      '${todaysActivities.length * 3} activities', // Mock weekly data
                      Icons.calendar_today,
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

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickInfo(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: AppTheme.primaryColor,
          size: 20,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}