import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class LeaderboardTab extends StatelessWidget {
  const LeaderboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildPodium(),
        const SizedBox(height: 24),
        _buildLeaderboardList(),
      ],
    );
  }

  Widget _buildPodium() {
    final topThree = _getMockLeaderboard().take(3).toList();
    
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        children: [
          const Text(
            'This Week\'s Champions',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildPodiumPosition(topThree[1], 2, 120),
              _buildPodiumPosition(topThree[0], 1, 140),
              _buildPodiumPosition(topThree[2], 3, 100),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPodiumPosition(Map<String, dynamic> user, int position, double height) {
    Color medalColor;
    switch (position) {
      case 1:
        medalColor = Colors.amber;
        break;
      case 2:
        medalColor = Colors.grey.shade400;
        break;
      case 3:
        medalColor = Colors.brown.shade400;
        break;
      default:
        medalColor = Colors.grey;
    }

    return Column(
      children: [
        Stack(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundImage: NetworkImage(user['avatar']),
            ),
            Positioned(
              bottom: -5,
              right: -5,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: medalColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Text(
                  '$position',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          user['name'].split(' ')[0],
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          '${user['points']} pts',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 60,
          height: height,
          decoration: BoxDecoration(
            color: medalColor.withValues(alpha: 0.3),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          ),
        ),
      ],
    );
  }

  Widget _buildLeaderboardList() {
    return Container(
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
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text(
                  'Full Rankings',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'This Week',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ..._getMockLeaderboard().asMap().entries.map((entry) {
            final index = entry.key;
            final user = entry.value;
            final isCurrentUser = user['isCurrentUser'] == true;
            
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isCurrentUser 
                    ? AppTheme.primaryColor.withValues(alpha: 0.1)
                    : Colors.transparent,
                border: Border(
                  bottom: BorderSide(
                    color: Colors.grey.shade100,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: _getRankColor(index + 1),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: NetworkImage(user['avatar']),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              user['name'],
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isCurrentUser 
                                    ? AppTheme.primaryColor 
                                    : Colors.black,
                              ),
                            ),
                            if (isCurrentUser) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'You',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        Text(
                          '${user['activities']} activities this week',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${user['points']}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isCurrentUser 
                              ? AppTheme.primaryColor 
                              : Colors.black,
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
            );
          }),
        ],
      ),
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber;
      case 2:
        return Colors.grey.shade400;
      case 3:
        return Colors.brown.shade400;
      default:
        return AppTheme.primaryColor;
    }
  }

  List<Map<String, dynamic>> _getMockLeaderboard() {
    return [
      {
        'name': 'Emma Thompson',
        'avatar': 'https://i.pravatar.cc/150?img=3',
        'points': 1250,
        'activities': 8,
        'isCurrentUser': false,
      },
      {
        'name': 'Mike Rodriguez',
        'avatar': 'https://i.pravatar.cc/150?img=2',
        'points': 1180,
        'activities': 7,
        'isCurrentUser': false,
      },
      {
        'name': 'Sarah Martinez',
        'avatar': 'https://i.pravatar.cc/150?img=1',
        'points': 1050,
        'activities': 6,
        'isCurrentUser': false,
      },
      {
        'name': 'You',
        'avatar': 'https://i.pravatar.cc/150?img=5',
        'points': 920,
        'activities': 5,
        'isCurrentUser': true,
      },
      {
        'name': 'Alex Chen',
        'avatar': 'https://i.pravatar.cc/150?img=4',
        'points': 850,
        'activities': 4,
        'isCurrentUser': false,
      },
    ];
  }
}