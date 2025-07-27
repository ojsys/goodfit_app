import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class ActivityFeedSection extends StatelessWidget {
  const ActivityFeedSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Activity Feed',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildFeedItem(
          'Emma Watson',
          '2 hours ago',
          'Just completed my first 10K run! 🏃‍♀️\nFeeling amazing!',
          24,
          8,
        ),
        const SizedBox(height: 16),
        _buildFeedItem(
          'John Smith',
          '4 hours ago',
          'Looking for a cycling buddy this\nweekend! Anyone interested? 🚴‍♂️',
          16,
          12,
        ),
      ],
    );
  }

  Widget _buildFeedItem(String name, String time, String content, int likes, int comments) {
    return Container(
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
              CircleAvatar(
                radius: 20,
                backgroundColor: AppTheme.primaryColor,
                child: Text(
                  name[0],
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      time,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: const TextStyle(fontSize: 15),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Row(
                children: [
                  Icon(Icons.favorite_border, size: 18, color: Colors.grey.shade600),
                  const SizedBox(width: 6),
                  Text('$likes', style: TextStyle(color: Colors.grey.shade600)),
                ],
              ),
              const SizedBox(width: 20),
              Row(
                children: [
                  Icon(Icons.chat_bubble_outline, size: 18, color: Colors.grey.shade600),
                  const SizedBox(width: 6),
                  Text('$comments', style: TextStyle(color: Colors.grey.shade600)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}