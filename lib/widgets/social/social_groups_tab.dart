import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class SocialGroupsTab extends StatelessWidget {
  const SocialGroupsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildMyGroups(),
        const SizedBox(height: 24),
        _buildDiscoverGroups(),
      ],
    );
  }

  Widget _buildMyGroups() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'My Groups',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () {},
              child: const Text('Manage'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ..._getMyGroups().map((group) => _buildGroupCard(group, true)),
      ],
    );
  }

  Widget _buildDiscoverGroups() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Discover Groups',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ..._getDiscoverGroups().map((group) => _buildGroupCard(group, false)),
      ],
    );
  }

  Widget _buildGroupCard(Map<String, dynamic> group, bool isMember) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
          // Group Header
          Container(
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: group['gradient'],
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              group['icon'],
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const Spacer(),
                          if (group['isPrivate'] == true)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.lock,
                                    size: 12,
                                    color: Colors.white,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Private',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        group['name'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${group['members']} members',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Group Info
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  group['description'],
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                
                // Group Stats
                Row(
                  children: [
                    _buildGroupStat(
                      Icons.trending_up,
                      '${group['weeklyActivities']}',
                      'This week',
                    ),
                    const SizedBox(width: 20),
                    _buildGroupStat(
                      Icons.chat_bubble_outline,
                      '${group['messages']}',
                      'Messages',
                    ),
                    const SizedBox(width: 20),
                    _buildGroupStat(
                      Icons.event,
                      '${group['events']}',
                      'Events',
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Member Avatars
                Row(
                  children: [
                    SizedBox(
                      height: 40,
                      child: Stack(
                        children: [
                          for (int i = 0; i < (group['memberAvatars'] as List).length && i < 4; i++)
                            Positioned(
                              left: i * 25.0,
                              child: CircleAvatar(
                                radius: 20,
                                backgroundColor: Colors.white,
                                child: CircleAvatar(
                                  radius: 18,
                                  backgroundImage: NetworkImage(group['memberAvatars'][i]),
                                ),
                              ),
                            ),
                          if ((group['memberAvatars'] as List).length > 4)
                            Positioned(
                              left: 4 * 25.0,
                              child: CircleAvatar(
                                radius: 20,
                                backgroundColor: Colors.grey.shade300,
                                child: Text(
                                  '+${(group['memberAvatars'] as List).length - 4}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    if (isMember)
                      OutlinedButton(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: AppTheme.primaryColor),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'View Group',
                          style: TextStyle(color: AppTheme.primaryColor),
                        ),
                      )
                    else
                      ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Join Group'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupStat(IconData icon, String value, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.grey.shade600,
        ),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
        ),
      ],
    );
  }

  List<Map<String, dynamic>> _getMyGroups() {
    return [
      {
        'name': 'Morning Runners',
        'description': 'Early birds who love to start the day with a run. Join us for daily 6 AM runs in Central Park!',
        'members': 156,
        'weeklyActivities': 45,
        'messages': 23,
        'events': 3,
        'icon': Icons.directions_run,
        'isPrivate': false,
        'gradient': [Colors.orange.shade400, Colors.red.shade400],
        'memberAvatars': [
          'https://i.pravatar.cc/150?img=1',
          'https://i.pravatar.cc/150?img=2',
          'https://i.pravatar.cc/150?img=3',
          'https://i.pravatar.cc/150?img=4',
          'https://i.pravatar.cc/150?img=5',
        ],
      },
      {
        'name': 'Weekend Warriors',
        'description': 'Intense weekend workouts for those who want to make the most of their free time.',
        'members': 89,
        'weeklyActivities': 28,
        'messages': 15,
        'events': 2,
        'icon': Icons.fitness_center,
        'isPrivate': true,
        'gradient': [Colors.purple.shade400, Colors.indigo.shade400],
        'memberAvatars': [
          'https://i.pravatar.cc/150?img=6',
          'https://i.pravatar.cc/150?img=7',
          'https://i.pravatar.cc/150?img=8',
        ],
      },
    ];
  }

  List<Map<String, dynamic>> _getDiscoverGroups() {
    return [
      {
        'name': 'Cycling Enthusiasts',
        'description': 'Join fellow cyclists for scenic rides and competitive challenges around the city.',
        'members': 234,
        'weeklyActivities': 67,
        'messages': 42,
        'events': 5,
        'icon': Icons.directions_bike,
        'isPrivate': false,
        'gradient': [Colors.blue.shade400, Colors.cyan.shade400],
        'memberAvatars': [
          'https://i.pravatar.cc/150?img=9',
          'https://i.pravatar.cc/150?img=10',
          'https://i.pravatar.cc/150?img=11',
          'https://i.pravatar.cc/150?img=12',
          'https://i.pravatar.cc/150?img=13',
          'https://i.pravatar.cc/150?img=14',
        ],
      },
      {
        'name': 'Yoga & Mindfulness',
        'description': 'Find your inner peace with daily yoga sessions and mindfulness practices.',
        'members': 178,
        'weeklyActivities': 52,
        'messages': 31,
        'events': 4,
        'icon': Icons.self_improvement,
        'isPrivate': false,
        'gradient': [Colors.green.shade400, Colors.teal.shade400],
        'memberAvatars': [
          'https://i.pravatar.cc/150?img=15',
          'https://i.pravatar.cc/150?img=16',
          'https://i.pravatar.cc/150?img=17',
          'https://i.pravatar.cc/150?img=18',
        ],
      },
    ];
  }
}