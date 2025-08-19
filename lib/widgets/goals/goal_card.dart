import 'package:flutter/material.dart';
import '../../models/fitness_goal.dart';
import '../../theme/app_theme.dart';

class GoalCard extends StatelessWidget {
  final FitnessGoal goal;

  const GoalCard({super.key, required this.goal});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 12),
              _buildDescription(),
              const SizedBox(height: 16),
              _buildProgressBar(),
              const SizedBox(height: 12),
              _buildProgressDetails(),
              const SizedBox(height: 12),
              _buildTimeInfo(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _getGoalTypeColor().withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getGoalTypeIcon(),
            color: _getGoalTypeColor(),
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                goal.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              _buildStatusChip(),
            ],
          ),
        ),
        if (goal.isCompleted)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle,
                  size: 16,
                  color: Colors.green.shade700,
                ),
                const SizedBox(width: 4),
                Text(
                  'Completed',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildDescription() {
    return Text(
      goal.description,
      style: TextStyle(
        fontSize: 14,
        color: Colors.grey.shade600,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildProgressBar() {
    final progress = goal.progressPercentage / 100;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progress',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '${goal.progressPercentage.toInt()}%',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.grey.shade200,
          valueColor: AlwaysStoppedAnimation<Color>(_getProgressColor()),
          minHeight: 8,
        ),
      ],
    );
  }

  Widget _buildProgressDetails() {
    return Row(
      children: [
        Expanded(
          child: _buildProgressStat(
            label: 'Current',
            value: _formatValue(goal.currentProgress),
            icon: Icons.trending_up,
          ),
        ),
        Expanded(
          child: _buildProgressStat(
            label: 'Target',
            value: _formatValue(goal.targetValue),
            icon: Icons.flag,
          ),
        ),
        Expanded(
          child: _buildProgressStat(
            label: 'Remaining',
            value: _formatValue(goal.targetValue - goal.currentProgress),
            icon: Icons.schedule,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressStat({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.grey.shade600,
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
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildTimeInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.calendar_today,
            size: 16,
            color: Colors.grey.shade600,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _getTimeInfoText(),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          if (goal.daysRemaining > 0 && !goal.isCompleted)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getDaysRemainingColor().withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${goal.daysRemaining} days left',
                style: TextStyle(
                  fontSize: 12,
                  color: _getDaysRemainingColor(),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusChip() {
    String status;
    Color color;
    
    if (goal.isCompleted) {
      status = 'Completed';
      color = Colors.green;
    } else if (goal.isActive) {
      status = 'Active';
      color = AppTheme.primaryColor;
    } else {
      status = 'Inactive';
      color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  IconData _getGoalTypeIcon() {
    switch (goal.goalType.toLowerCase()) {
      case 'distance':
        return Icons.straighten;
      case 'duration':
        return Icons.timer;
      case 'calories':
        return Icons.local_fire_department;
      case 'frequency':
        return Icons.repeat;
      default:
        return Icons.flag;
    }
  }

  Color _getGoalTypeColor() {
    switch (goal.goalType.toLowerCase()) {
      case 'distance':
        return Colors.blue;
      case 'duration':
        return Colors.green;
      case 'calories':
        return Colors.orange;
      case 'frequency':
        return Colors.purple;
      default:
        return AppTheme.primaryColor;
    }
  }

  Color _getProgressColor() {
    if (goal.isCompleted) return Colors.green;
    
    final progress = goal.progressPercentage;
    if (progress >= 80) return Colors.green;
    if (progress >= 50) return Colors.orange;
    return Colors.red;
  }

  Color _getDaysRemainingColor() {
    final days = goal.daysRemaining;
    if (days <= 3) return Colors.red;
    if (days <= 7) return Colors.orange;
    return Colors.green;
  }

  String _formatValue(double value) {
    switch (goal.goalType.toLowerCase()) {
      case 'distance':
        return '${value.toStringAsFixed(1)} ${goal.unit}';
      case 'duration':
        return '${value.toInt()} ${goal.unit}';
      case 'calories':
        return '${value.toInt()} ${goal.unit}';
      case 'frequency':
        return '${value.toInt()} ${goal.unit}';
      default:
        return '${value.toStringAsFixed(1)} ${goal.unit}';
    }
  }

  String _getTimeInfoText() {
    final startDate = goal.startDate;
    final endDate = goal.endDate;
    final now = DateTime.now();
    
    if (goal.isCompleted && goal.completedDate != null) {
      return 'Completed on ${_formatDate(goal.completedDate!)}';
    }
    
    if (now.isBefore(startDate)) {
      return 'Starts on ${_formatDate(startDate)}';
    }
    
    if (now.isAfter(endDate)) {
      return 'Expired on ${_formatDate(endDate)}';
    }
    
    return 'Started ${_formatDate(startDate)} • Ends ${_formatDate(endDate)}';
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}