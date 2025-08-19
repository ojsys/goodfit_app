import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class CommunityFeedTab extends StatelessWidget {
  const CommunityFeedTab({super.key});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        // Refresh feed
        await Future.delayed(const Duration(seconds: 1));
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _getMockFeedItems().length,
        itemBuilder: (context, index) {
          return _buildExpandedFeedItem(_getMockFeedItems()[index]);
        },
      ),
    );
  }

  Widget _buildExpandedFeedItem(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundImage: NetworkImage(item['userAvatar']),
                    ),
                    if (item['isOnline'] == true)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            border: Border.all(color: Colors.white, width: 2),
                            borderRadius: BorderRadius.circular(7),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            item['userName'],
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (item['isVerified'] == true) ...[
                            const SizedBox(width: 4),
                            Icon(
                              Icons.verified,
                              size: 16,
                              color: AppTheme.primaryColor,
                            ),
                          ],
                        ],
                      ),
                      Row(
                        children: [
                          Text(
                            item['timeAgo'],
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          if (item['location'] != null) ...[
                            const SizedBox(width: 8),
                            Icon(
                              Icons.location_on,
                              size: 12,
                              color: Colors.grey.shade600,
                            ),
                            Text(
                              item['location'],
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                PopupMenuButton(
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'report',
                      child: Row(
                        children: [
                          Icon(Icons.flag, size: 16),
                          SizedBox(width: 8),
                          Text('Report'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'hide',
                      child: Row(
                        children: [
                          Icon(Icons.visibility_off, size: 16),
                          SizedBox(width: 8),
                          Text('Hide'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Content
          if (item['description'] != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                item['description'],
                style: const TextStyle(fontSize: 15, height: 1.4),
              ),
            ),

          // Activity/Achievement Card
          if (item['type'] == 'activity' || item['type'] == 'achievement')
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _getTypeColor(item['type']).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _getTypeColor(item['type']).withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _getTypeColor(item['type']),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getTypeIcon(item['type'], item['activityType']),
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getTypeTitle(item),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _getTypeSubtitle(item),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        if (item['stats'] != null) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 12,
                            children: (item['stats'] as List<Map<String, dynamic>>)
                                .map((stat) => _buildStatChip(stat))
                                .toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (item['type'] == 'achievement')
                    Column(
                      children: [
                        Text(
                          '+${item['points']}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _getTypeColor(item['type']),
                          ),
                        ),
                        Text(
                          'points',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),

          // Photo if available
          if (item['photo'] != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                image: DecorationImage(
                  image: NetworkImage(item['photo']),
                  fit: BoxFit.cover,
                ),
              ),
            ),

          const SizedBox(height: 12),

          // Engagement Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                if (item['likes'] > 0) ...[
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.favorite,
                          size: 12,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${item['likes']}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                ],
                if (item['comments'] > 0) ...[
                  Text(
                    '${item['comments']} comments',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
                const Spacer(),
                Text(
                  '${item['shares'] ?? 0} shares',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 20),

          // Action Buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    icon: item['isLiked'] ? Icons.favorite : Icons.favorite_border,
                    label: 'Like',
                    color: item['isLiked'] ? Colors.red : Colors.grey.shade600,
                    onTap: () {},
                  ),
                ),
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.chat_bubble_outline,
                    label: 'Comment',
                    color: Colors.grey.shade600,
                    onTap: () {},
                  ),
                ),
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.share_outlined,
                    label: 'Share',
                    color: Colors.grey.shade600,
                    onTap: () {},
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(Map<String, dynamic> stat) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(stat['icon'], size: 14, color: stat['color']),
          const SizedBox(width: 4),
          Text(
            stat['value'],
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: stat['color'],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'activity':
        return AppTheme.primaryColor;
      case 'achievement':
        return Colors.amber.shade600;
      default:
        return Colors.grey;
    }
  }

  IconData _getTypeIcon(String type, String? activityType) {
    if (type == 'achievement') return Icons.emoji_events;
    
    switch (activityType?.toLowerCase()) {
      case 'running':
        return Icons.directions_run;
      case 'cycling':
        return Icons.directions_bike;
      case 'swimming':
        return Icons.pool;
      case 'hiking':
        return Icons.terrain;
      default:
        return Icons.fitness_center;
    }
  }

  String _getTypeTitle(Map<String, dynamic> item) {
    if (item['type'] == 'achievement') {
      return 'Achievement Unlocked!';
    }
    return '${item['activityType']} Workout';
  }

  String _getTypeSubtitle(Map<String, dynamic> item) {
    if (item['type'] == 'achievement') {
      return item['achievementName'] ?? 'New milestone reached';
    }
    return item['activityDescription'] ?? 'Completed workout';
  }

  List<Map<String, dynamic>> _getMockFeedItems() {
    return [
      {
        'userName': 'Sarah Martinez',
        'userAvatar': 'https://i.pravatar.cc/150?img=1',
        'timeAgo': '2 hours ago',
        'isOnline': true,
        'isVerified': true,
        'location': 'Central Park',
        'type': 'activity',
        'activityType': 'Running',
        'description': 'Amazing morning run! The weather was perfect and I felt so energized. Who else loves running in Central Park? 🏃‍♀️',
        'activityDescription': 'Morning run in Central Park',
        'stats': [
          {'icon': Icons.straighten, 'value': '5.2 km', 'color': Colors.blue},
          {'icon': Icons.timer, 'value': '28 min', 'color': Colors.green},
          {'icon': Icons.local_fire_department, 'value': '280 cal', 'color': Colors.orange},
        ],
        'likes': 24,
        'comments': 8,
        'shares': 3,
        'isLiked': true,
      },
      {
        'userName': 'Mike Rodriguez',
        'userAvatar': 'https://i.pravatar.cc/150?img=2',
        'timeAgo': '4 hours ago',
        'isOnline': false,
        'isVerified': false,
        'type': 'achievement',
        'achievementName': '10K Runner',
        'description': 'Finally hit my goal of running 10 times this month! Thank you to everyone who motivated me along the way 💪',
        'points': 250,
        'likes': 42,
        'comments': 15,
        'shares': 7,
        'isLiked': false,
      },
      {
        'userName': 'Emma Thompson',
        'userAvatar': 'https://i.pravatar.cc/150?img=3',
        'timeAgo': '6 hours ago',
        'isOnline': true,
        'isVerified': false,
        'location': 'Coastal Trail',
        'type': 'activity',
        'activityType': 'Cycling',
        'description': 'Epic bike ride along the coast today! The views were absolutely breathtaking 🌊',
        'activityDescription': 'Coastal cycling adventure',
        'photo': 'https://images.unsplash.com/photo-1558618411-fcd25c85cd64?w=400',
        'stats': [
          {'icon': Icons.straighten, 'value': '25 km', 'color': Colors.blue},
          {'icon': Icons.timer, 'value': '1h 15m', 'color': Colors.green},
          {'icon': Icons.trending_up, 'value': '450m', 'color': Colors.purple},
        ],
        'likes': 31,
        'comments': 12,
        'shares': 5,
        'isLiked': true,
      },
    ];
  }
}