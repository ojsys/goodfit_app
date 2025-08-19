import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class SocialFeedSection extends StatelessWidget {
  const SocialFeedSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.orange.shade400, Colors.red.shade400],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.dynamic_feed,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Activity Feed',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () {
                // Navigate to full feed
              },
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'See what your friends are up to',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 16),
        
        ..._getMockFeedItems().map((item) => _buildFeedItem(item)),
      ],
    );
  }

  Widget _buildFeedItem(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          // User Info Row
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: NetworkImage(item['userAvatar']),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['userName'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      item['timeAgo'],
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              if (item['type'] == 'achievement')
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.emoji_events,
                        size: 14,
                        color: Colors.amber.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Achievement',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.amber.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Activity Content
          if (item['type'] == 'activity') ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getActivityColor(item['activityType']).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _getActivityColor(item['activityType']).withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getActivityColor(item['activityType']),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getActivityIcon(item['activityType']),
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${item['activityType']} Workout',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          item['content'],
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ] else if (item['type'] == 'achievement') ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.amber.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade600,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.emoji_events,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Unlocked Achievement',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          item['content'],
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '+${item['points']} pts',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          const SizedBox(height: 12),
          
          // Engagement Row
          Row(
            children: [
              _buildEngagementButton(
                icon: item['isLiked'] ? Icons.favorite : Icons.favorite_border,
                label: '${item['likes']}',
                color: item['isLiked'] ? Colors.red : Colors.grey.shade600,
                onTap: () {
                  // Toggle like
                },
              ),
              const SizedBox(width: 16),
              _buildEngagementButton(
                icon: Icons.chat_bubble_outline,
                label: '${item['comments']}',
                color: Colors.grey.shade600,
                onTap: () {
                  // Show comments
                },
              ),
              const SizedBox(width: 16),
              _buildEngagementButton(
                icon: Icons.share_outlined,
                label: 'Share',
                color: Colors.grey.shade600,
                onTap: () {
                  // Share activity
                },
              ),
              const Spacer(),
              if (item['route'] != null)
                TextButton.icon(
                  onPressed: () {
                    // View route
                  },
                  icon: Icon(
                    Icons.route,
                    size: 16,
                    color: AppTheme.primaryColor,
                  ),
                  label: Text(
                    'View Route',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEngagementButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getActivityIcon(String activityType) {
    switch (activityType.toLowerCase()) {
      case 'running':
        return Icons.directions_run;
      case 'cycling':
        return Icons.directions_bike;
      case 'walking':
        return Icons.directions_walk;
      case 'swimming':
        return Icons.pool;
      case 'hiking':
        return Icons.terrain;
      case 'yoga':
        return Icons.self_improvement;
      case 'strength':
        return Icons.fitness_center;
      default:
        return Icons.sports;
    }
  }

  Color _getActivityColor(String activityType) {
    switch (activityType.toLowerCase()) {
      case 'running':
        return Colors.red;
      case 'cycling':
        return Colors.blue;
      case 'walking':
        return Colors.green;
      case 'swimming':
        return Colors.cyan;
      case 'hiking':
        return Colors.brown;
      case 'yoga':
        return Colors.purple;
      case 'strength':
        return Colors.orange;
      default:
        return AppTheme.primaryColor;
    }
  }

  List<Map<String, dynamic>> _getMockFeedItems() {
    return [
      {
        'userName': 'Sarah Martinez',
        'userAvatar': 'https://i.pravatar.cc/150?img=1',
        'timeAgo': '2 hours ago',
        'type': 'activity',
        'activityType': 'Running',
        'content': 'Completed a 5.2km morning run in Central Park',
        'likes': 12,
        'comments': 3,
        'isLiked': false,
        'route': 'Central Park Loop',
      },
      {
        'userName': 'Mike Rodriguez',
        'userAvatar': 'https://i.pravatar.cc/150?img=2',
        'timeAgo': '4 hours ago',
        'type': 'achievement',
        'content': '10K Runner - Completed 10 runs this month!',
        'likes': 24,
        'comments': 8,
        'isLiked': true,
        'points': 250,
      },
      {
        'userName': 'Emma Thompson',
        'userAvatar': 'https://i.pravatar.cc/150?img=3',
        'timeAgo': '6 hours ago',
        'type': 'activity',
        'activityType': 'Cycling',
        'content': 'Epic 25km bike ride along the coastal route',
        'likes': 18,
        'comments': 5,
        'isLiked': true,
        'route': 'Coastal Trail',
      },
      {
        'userName': 'Alex Chen',
        'userAvatar': 'https://i.pravatar.cc/150?img=4',
        'timeAgo': '1 day ago',
        'type': 'activity',
        'activityType': 'Hiking',
        'content': 'Summit conquered! 8km hike to Mountain Peak',
        'likes': 31,
        'comments': 12,
        'isLiked': false,
        'route': 'Mountain Trail',
      },
    ];
  }
}