import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/route.dart' as route_model;
import '../widgets/route_map_widget.dart';
import '../services/live_activity_service.dart';
import '../services/gps_tracking_service.dart';

class LiveTrackingScreen extends StatefulWidget {
  final route_model.Route? selectedRoute;
  final List<int>? linkedGoalIds;

  const LiveTrackingScreen({
    super.key,
    this.selectedRoute,
    this.linkedGoalIds,
  });

  @override
  State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen> {
  late LiveActivityService _liveActivityService;
  late GPSTrackingService _gpsService;
  bool _isStarted = false;

  @override
  void initState() {
    super.initState();
    _liveActivityService = LiveActivityService();
    _gpsService = GPSTrackingService();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.selectedRoute?.name ?? 'Live Tracking'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Map Section
          Expanded(
            flex: 2,
            child: RouteMapWidget(
              route: widget.selectedRoute,
              enableLiveTracking: true,
              height: double.infinity,
            ),
          ),
          
          // Metrics Dashboard
          Expanded(
            flex: 1,
            child: _buildMetricsDashboard(),
          ),
        ],
      ),
      
      // Control Panel
      bottomSheet: _buildControlPanel(),
    );
  }

  Widget _buildMetricsDashboard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Consumer<LiveActivityService>(
        builder: (context, service, child) {
          if (!service.isLiveActivityActive) {
            return _buildPreActivityInfo();
          }

          final metrics = service.getCurrentLiveMetrics();
          return _buildLiveMetrics(metrics);
        },
      ),
    );
  }

  Widget _buildPreActivityInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ready to Start',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        
        const SizedBox(height: 16),
        
        if (widget.selectedRoute != null) ...[
          _buildInfoRow('Route', widget.selectedRoute!.name),
          _buildInfoRow('Distance', widget.selectedRoute!.formattedDistance),
          _buildInfoRow('Estimated Time', widget.selectedRoute!.formattedEstimatedDuration),
          _buildInfoRow('Difficulty', widget.selectedRoute!.difficultyDescription),
        ] else ...[
          const Text(
            'Free workout - no route selected',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
        
        if (widget.linkedGoalIds?.isNotEmpty == true) ...[
          const SizedBox(height: 12),
          Text(
            'Linked to ${widget.linkedGoalIds!.length} goal(s)',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.blue,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLiveMetrics(Map<String, dynamic> metrics) {
    final distance = metrics['distance'] as double? ?? 0.0;
    final duration = metrics['duration'] as int? ?? 0;
    final currentSpeed = metrics['current_speed'] as double? ?? 0.0;
    final averageSpeed = metrics['average_speed'] as double? ?? 0.0;
    final currentPace = metrics['current_pace'] as double? ?? 0.0;
    final averagePace = metrics['average_pace'] as double? ?? 0.0;

    return Column(
      children: [
        // Status indicator
        Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'LIVE TRACKING',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const Spacer(),
            Text(
              _formatDuration(duration),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 20),
        
        // Main metrics grid
        Expanded(
          child: GridView.count(
            crossAxisCount: 2,
            childAspectRatio: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildMetricCard(
                'Distance',
                '${distance.toStringAsFixed(2)} km',
                Icons.straighten,
                Colors.blue,
              ),
              _buildMetricCard(
                'Current Speed',
                '${currentSpeed.toStringAsFixed(1)} km/h',
                Icons.speed,
                Colors.green,
              ),
              _buildMetricCard(
                'Avg Speed',
                '${averageSpeed.toStringAsFixed(1)} km/h',
                Icons.trending_up,
                Colors.orange,
              ),
              _buildMetricCard(
                'Current Pace',
                '${currentPace.toStringAsFixed(1)} min/km',
                Icons.timer,
                Colors.purple,
              ),
            ],
          ),
        ),
        
        // Progress indicator (if route selected)
        if (widget.selectedRoute != null) ...[
          const SizedBox(height: 12),
          _buildProgressIndicator(distance),
        ],
      ],
    );
  }

  Widget _buildMetricCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator(double currentDistance) {
    if (widget.selectedRoute == null) return const SizedBox.shrink();
    
    final progress = (currentDistance / widget.selectedRoute!.distanceKm).clamp(0.0, 1.0);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Route Progress',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '${(progress * 100).toStringAsFixed(0)}%',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.grey.shade300,
          valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
        ),
      ],
    );
  }

  Widget _buildControlPanel() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Consumer<LiveActivityService>(
          builder: (context, service, child) {
            return Row(
              children: [
                if (service.isLiveActivityActive) ...[
                  // Pause/Resume button
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _gpsService.isPaused ? _resumeActivity : _pauseActivity,
                      icon: Icon(_gpsService.isPaused ? Icons.play_arrow : Icons.pause),
                      label: Text(_gpsService.isPaused ? 'Resume' : 'Pause'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _gpsService.isPaused ? Colors.green : Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 12),
                  
                  // Stop button
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _stopActivity,
                      icon: const Icon(Icons.stop),
                      label: const Text('Finish'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  // Start button
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _startActivity,
                      icon: const Icon(Icons.play_arrow),
                      label: Text(widget.selectedRoute != null ? 'Start Route' : 'Start Activity'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(int seconds) {
    final duration = Duration(seconds: seconds);
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final secs = duration.inSeconds % 60;
    
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
  }

  Future<void> _startActivity() async {
    final success = await _liveActivityService.startLiveActivity(
      activityType: widget.selectedRoute?.activityTypes.first ?? 'running',
      activityName: widget.selectedRoute?.name ?? 'Free Workout',
      linkedGoalIds: widget.linkedGoalIds ?? [],
    );

    if (success) {
      setState(() {
        _isStarted = true;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Activity started! GPS tracking is now active.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to start activity. Check GPS permissions.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pauseActivity() async {
    await _liveActivityService.pauseLiveActivity();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Activity paused'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<void> _resumeActivity() async {
    await _liveActivityService.resumeLiveActivity();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Activity resumed'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _stopActivity() async {
    // Show confirmation dialog
    final shouldStop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Finish Activity'),
        content: const Text('Are you sure you want to finish this activity? Your progress will be saved.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Finish'),
          ),
        ],
      ),
    );

    if (shouldStop == true) {
      final completedActivity = await _liveActivityService.completeLiveActivity();
      
      if (completedActivity != null && mounted) {
        // Navigate back with success message
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Activity completed: ${completedActivity.name}'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save activity'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    // Clean up if activity is still running
    if (_liveActivityService.isLiveActivityActive) {
      _liveActivityService.forceStop();
    }
    super.dispose();
  }
}