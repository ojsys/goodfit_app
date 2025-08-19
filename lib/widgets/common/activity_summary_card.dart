import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/fitness_provider.dart';
import '../activity/create_activity_dialog.dart';

class ActivitySummaryCard extends StatefulWidget {
  const ActivitySummaryCard({super.key});

  @override
  State<ActivitySummaryCard> createState() => _ActivitySummaryCardState();
}

class _ActivitySummaryCardState extends State<ActivitySummaryCard> {
  @override
  void initState() {
    super.initState();
    // Load fitness data when the widget is created
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final fitnessProvider = Provider.of<FitnessProvider>(context, listen: false);
      fitnessProvider.loadActivities();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FitnessProvider>(
      builder: (context, fitnessProvider, child) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Today's Activity",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      if (fitnessProvider.isLoading)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: () => _showEnhancedActivityDialog(context),
                        child: const Text(
                          'Add Activity',
                          style: TextStyle(color: AppTheme.primaryColor),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (fitnessProvider.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    fitnessProvider.errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildActivityStat(
                    _formatNumber(fitnessProvider.todaysSteps),
                    'Steps',
                    Icons.directions_walk,
                  ),
                  _buildActivityStat(
                    fitnessProvider.averageHeartRate.toString(),
                    'BPM',
                    Icons.favorite,
                  ),
                  _buildActivityStat(
                    fitnessProvider.todaysMinutes.toString(),
                    'Minutes',
                    Icons.access_time,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActivityStat(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.primaryColor, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}k';
    }
    return number.toString();
  }

  void _showEnhancedActivityDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) => const CreateActivityDialog(),
    );
  }

}