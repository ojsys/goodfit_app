import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class ActivityPreferencesScreen extends StatefulWidget {
  const ActivityPreferencesScreen({super.key});

  @override
  State<ActivityPreferencesScreen> createState() => _ActivityPreferencesScreenState();
}

class _ActivityPreferencesScreenState extends State<ActivityPreferencesScreen> {
  final List<String> selectedActivities = [];
  
  final List<Map<String, dynamic>> activities = [
    {'name': 'Running', 'icon': Icons.directions_run},
    {'name': 'Cycling', 'icon': Icons.directions_bike},
    {'name': 'Strength', 'icon': Icons.fitness_center},
    {'name': 'Yoga', 'icon': Icons.self_improvement},
    {'name': 'Hiking', 'icon': Icons.terrain},
    {'name': 'More', 'icon': Icons.add},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LinearProgressIndicator(
                value: 0.75,
                backgroundColor: Colors.grey.shade300,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange),
              ),
              const SizedBox(height: 40),
              const Text(
                'What moves you?',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Select your interests (min. of 3)',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 40),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.2,
                  ),
                  itemCount: activities.length,
                  itemBuilder: (context, index) {
                    final activity = activities[index];
                    final isSelected = selectedActivities.contains(activity['name']);
                    
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            selectedActivities.remove(activity['name']);
                          } else {
                            selectedActivities.add(activity['name']);
                          }
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
                            width: isSelected ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          color: isSelected ? AppTheme.primaryColor.withValues(alpha: 0.1) : Colors.white,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              activity['icon'],
                              size: 40,
                              color: isSelected ? AppTheme.primaryColor : Colors.grey,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              activity['name'],
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: isSelected ? AppTheme.primaryColor : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: selectedActivities.length >= 3 
                      ? () => Navigator.pushNamed(context, '/photo-upload')
                      : null,
                  child: const Text('Continue'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}