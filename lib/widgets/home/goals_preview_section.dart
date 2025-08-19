import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/goals_provider.dart';
import '../../theme/app_theme.dart';
import '../common/unified_create_modal.dart';

class GoalsPreviewSection extends StatelessWidget {
  const GoalsPreviewSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GoalsProvider>(
      builder: (context, goalsProvider, child) {
        final activeGoals = goalsProvider.activeGoals.take(3).toList();
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Active Goals',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => _handleViewAllGoals(context, goalsProvider.activeGoals.isEmpty),
                  child: Text(goalsProvider.activeGoals.isEmpty ? 'Create Goal' : 'View All'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            if (activeGoals.isEmpty)
              _buildEmptyState(context)
            else
              ...activeGoals.map((goal) => _buildGoalPreviewCard(goal)),
          ],
        );
      },
    );
  }

  Widget _buildGoalPreviewCard(goal) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  _getGoalIcon(goal.goalType),
                  color: AppTheme.primaryColor,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  goal.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '${goal.progressPercentage.toInt()}%',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Progress Bar
          LinearProgressIndicator(
            value: goal.progressPercentage / 100,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
            minHeight: 6,
          ),
          
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                goal.progressDisplay,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              const Spacer(),
              if (goal.daysRemaining > 0)
                Text(
                  '${goal.daysRemaining} days left',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(
            Icons.flag_outlined,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 12),
          Text(
            'No active goals',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Set your first fitness goal!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _showCreateGoalModal(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            ),
            child: const Text('Create Goal'),
          ),
        ],
      ),
    );
  }

  IconData _getGoalIcon(String goalType) {
    switch (goalType.toLowerCase()) {
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

  void _showCreateGoalModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const UnifiedCreateModal(),
    );
  }

  void _handleViewAllGoals(BuildContext context, bool isEmpty) {
    if (isEmpty) {
      _showCreateGoalModal(context);
    } else {
      // Navigate to goals screen - implement when goals screen is ready
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Goals screen coming soon!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}