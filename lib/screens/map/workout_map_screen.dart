import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/map_painter.dart';

class WorkoutMapScreen extends StatefulWidget {
  const WorkoutMapScreen({super.key});

  @override
  State<WorkoutMapScreen> createState() => _WorkoutMapScreenState();
}

class _WorkoutMapScreenState extends State<WorkoutMapScreen> {
  bool isWorkoutActive = false;
  String workoutTime = "00:00";
  
  final List<bool> weeklyProgress = [true, true, false, true, false, false, false];
  final List<String> weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('A Good Fit'),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {},
          ),
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.grey.shade300,
            child: const Icon(Icons.person, size: 20),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              color: Colors.grey.shade100,
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                    ),
                    child: CustomPaint(
                      painter: MapPainter(),
                      size: Size.infinite,
                    ),
                  ),
                  Positioned(
                    right: 16,
                    top: 100,
                    child: Column(
                      children: [
                        FloatingActionButton.small(
                          onPressed: () {},
                          backgroundColor: Colors.white,
                          child: const Icon(Icons.add, color: Colors.black),
                        ),
                        const SizedBox(height: 8),
                        FloatingActionButton.small(
                          onPressed: () {},
                          backgroundColor: Colors.white,
                          child: const Icon(Icons.remove, color: Colors.black),
                        ),
                        const SizedBox(height: 16),
                        FloatingActionButton.small(
                          onPressed: () {},
                          backgroundColor: Colors.white,
                          child: const Icon(Icons.my_location, color: Colors.black),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatColumn('3.2', 'Miles'),
                    _buildStatColumn('28:45', 'Duration'),
                    _buildStatColumn('8\'54"', 'Pace'),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  'Workout Streak',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(7, (index) {
                    final isCompleted = weeklyProgress[index];
                    final isToday = index == 3;
                    
                    return Column(
                      children: [
                        Text(
                          weekDays[index],
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isCompleted 
                                ? AppTheme.primaryColor
                                : isToday 
                                    ? Colors.orange
                                    : Colors.grey.shade300,
                          ),
                          child: Icon(
                            isCompleted 
                                ? Icons.check
                                : isToday 
                                    ? Icons.fitness_center
                                    : Icons.close,
                            size: 16,
                            color: isCompleted || isToday ? Colors.white : Colors.grey,
                          ),
                        ),
                      ],
                    );
                  }),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            isWorkoutActive = !isWorkoutActive;
                          });
                        },
                        icon: Icon(isWorkoutActive ? Icons.pause : Icons.play_arrow),
                        label: Text(isWorkoutActive ? 'Pause Workout' : 'Start Workout'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.share),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.grey.shade100,
                        padding: const EdgeInsets.all(16),
                      ),
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

  Widget _buildStatColumn(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}