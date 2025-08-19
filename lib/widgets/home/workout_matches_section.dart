import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';

class WorkoutMatchesSection extends StatefulWidget {
  const WorkoutMatchesSection({super.key});

  @override
  State<WorkoutMatchesSection> createState() => _WorkoutMatchesSectionState();
}

class _WorkoutMatchesSectionState extends State<WorkoutMatchesSection> {
  List<Map<String, dynamic>> _matches = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadMatches();
  }

  Future<void> _loadMatches() async {
    setState(() => _isLoading = true);
    
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final result = await apiService.getDiscovery();
      
      if (result.success && result.data != null) {
        setState(() {
          _matches = result.data!;
        });
      } else {
        // Fallback to mock data
        setState(() {
          _matches = _getMockMatches();
        });
      }
    } catch (e) {
      // Fallback to mock data
      setState(() {
        _matches = _getMockMatches();
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleConnect(int userId) async {
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final result = await apiService.performMatchAction(
        userId: userId,
        action: 'like',
      );
      
      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Connection request sent!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to send connection request'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Network error occurred'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

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
                  colors: [Colors.pink.shade400, Colors.purple.shade400],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.people,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Workout Matches',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () {
                // Navigate to full matches screen
              },
              child: const Text('See All'),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Find your perfect workout buddy',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 16),
        
        SizedBox(
          height: 240,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _matches.length,
                  itemBuilder: (context, index) {
                    return _buildMatchCard(_matches[index]);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildMatchCard(Map<String, dynamic> match) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 16),
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
        children: [
          // Profile Section
          Container(
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: match['gradient'],
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.white.withValues(alpha: 0.3),
                        child: CircleAvatar(
                          radius: 25,
                          backgroundImage: NetworkImage(match['avatar']),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        match['name'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${match['compatibility']}%',
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
          ),
          
          // Info Section
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 12,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        match['location'],
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Icon(
                      Icons.fitness_center,
                      size: 12,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        match['interests'].join(', '),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 32,
                  child: OutlinedButton(
                    onPressed: () {
                      _handleConnect(match['id'] ?? 0);
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      side: BorderSide(color: AppTheme.primaryColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: Text(
                      'Connect',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getMockMatches() {
    return [
      {
        'id': 1,
        'name': 'Sarah M.',
        'avatar': 'https://i.pravatar.cc/150?img=1',
        'location': '2.1 km away',
        'interests': ['Running', 'Yoga'],
        'compatibility': 92,
        'gradient': [Colors.pink.shade400, Colors.purple.shade400],
      },
      {
        'id': 2,
        'name': 'Mike R.',
        'avatar': 'https://i.pravatar.cc/150?img=2',
        'location': '1.8 km away',
        'interests': ['Cycling', 'Swimming'],
        'compatibility': 88,
        'gradient': [Colors.blue.shade400, Colors.cyan.shade400],
      },
      {
        'id': 3,
        'name': 'Emma K.',
        'avatar': 'https://i.pravatar.cc/150?img=3',
        'location': '3.2 km away',
        'interests': ['Hiking', 'Running'],
        'compatibility': 85,
        'gradient': [Colors.green.shade400, Colors.teal.shade400],
      },
      {
        'id': 4,
        'name': 'Alex D.',
        'avatar': 'https://i.pravatar.cc/150?img=4',
        'location': '2.7 km away',
        'interests': ['Strength', 'Boxing'],
        'compatibility': 79,
        'gradient': [Colors.orange.shade400, Colors.red.shade400],
      },
    ];
  }
}