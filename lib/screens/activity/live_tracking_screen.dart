import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:location/location.dart';
import 'dart:async';
import '../../providers/fitness_provider.dart';
import '../../providers/goals_provider.dart';
import '../../models/fitness_activity.dart';
import '../../theme/app_theme.dart';
import '../../utils/distance_calculator.dart';
import '../../utils/logger.dart';

class LiveTrackingScreen extends StatefulWidget {
  const LiveTrackingScreen({super.key});

  @override
  State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen> {
  Map<String, dynamic> _activityData = {};
  
  // Tracking state
  bool _isTracking = false;
  bool _isPaused = false;
  DateTime? _startTime;
  DateTime? _pausedTime;
  Duration _elapsedTime = Duration.zero;
  Timer? _timer;
  
  // Location tracking
  final Location _location = Location();
  StreamSubscription<LocationData>? _locationSubscription;
  List<LocationData> _locationPoints = [];
  LocationData? _currentLocation;
  double _totalDistance = 0.0;
  
  // Metrics
  int _currentCalories = 0;
  double _averageSpeed = 0.0;
  double _currentSpeed = 0.0;

  @override
  void initState() {
    super.initState();
    
    // Get activity data from route arguments
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        setState(() {
          _activityData = args;
        });
        AppLogger.info('Live tracking started for: ${_activityData['activityName']}', 'LiveTracking');
      } else {
        AppLogger.warning('No activity data provided to live tracking screen', 'LiveTracking');
        // Set default values
        setState(() {
          _activityData = {
            'activityType': 'Running',
            'activityName': 'Live Activity',
            'estimatedDuration': 30,
            'linkedGoalIds': <int>[],
          };
        });
      }
    });
  }

  @override
  void dispose() {
    _stopTracking();
    _timer?.cancel();
    _locationSubscription?.cancel();
    super.dispose();
  }

  Future<void> _startTracking() async {
    try {
      // Check location permissions
      bool serviceEnabled = await _location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await _location.requestService();
        if (!serviceEnabled) {
          _showError('Location services are required for tracking');
          return;
        }
      }

      PermissionStatus permissionGranted = await _location.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await _location.requestPermission();
        if (permissionGranted != PermissionStatus.granted) {
          _showError('Location permission is required for tracking');
          return;
        }
      }

      setState(() {
        _isTracking = true;
        _startTime = DateTime.now();
      });

      // Start timer
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!_isPaused) {
          setState(() {
            _elapsedTime = DateTime.now().difference(_startTime!);
            _updateMetrics();
          });
        }
      });

      // Start location tracking
      _locationSubscription = _location.onLocationChanged.listen((LocationData locationData) {
        if (!_isPaused && locationData.latitude != null && locationData.longitude != null) {
          _updateLocation(locationData);
        }
      });

      AppLogger.info('Live tracking started', 'LiveTracking');
      
    } catch (e) {
      AppLogger.error('Error starting tracking: $e', 'LiveTracking');
      _showError('Failed to start tracking');
    }
  }

  void _updateLocation(LocationData newLocation) {
    setState(() {
      if (_currentLocation != null && 
          _currentLocation!.latitude != null && 
          _currentLocation!.longitude != null &&
          newLocation.latitude != null && 
          newLocation!.longitude != null) {
        
        double distance = DistanceCalculator.calculateDistance(
          _currentLocation!.latitude!,
          _currentLocation!.longitude!,
          newLocation.latitude!,
          newLocation.longitude!,
        );
        
        _totalDistance += distance;
        
        // Calculate current speed (km/h)
        if (newLocation.speed != null && newLocation.speed! >= 0) {
          _currentSpeed = newLocation.speed! * 3.6; // m/s to km/h
        }
      }
      
      _currentLocation = newLocation;
      _locationPoints.add(newLocation);
    });
  }

  void _updateMetrics() {
    if (_elapsedTime.inSeconds > 0) {
      // Calculate average speed
      _averageSpeed = (_totalDistance / _elapsedTime.inHours);
      
      // Estimate calories based on activity type and duration
      _currentCalories = DistanceCalculator.estimateCalories(
        activityType: _activityData['activityType'] ?? 'Running',
        durationMinutes: _elapsedTime.inMinutes,
        distanceKm: _totalDistance,
      );
    }
  }

  void _pauseTracking() {
    setState(() {
      _isPaused = true;
      _pausedTime = DateTime.now();
    });
    AppLogger.info('Tracking paused', 'LiveTracking');
  }

  void _resumeTracking() {
    setState(() {
      _isPaused = false;
      if (_pausedTime != null && _startTime != null) {
        // Adjust start time to account for pause duration
        _startTime = _startTime!.add(DateTime.now().difference(_pausedTime!));
      }
      _pausedTime = null;
    });
    AppLogger.info('Tracking resumed', 'LiveTracking');
  }

  void _stopTracking() {
    _timer?.cancel();
    _locationSubscription?.cancel();
    setState(() {
      _isTracking = false;
      _isPaused = false;
    });
    AppLogger.info('Tracking stopped', 'LiveTracking');
  }

  Future<void> _finishActivity() async {
    _stopTracking();
    
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final fitnessProvider = Provider.of<FitnessProvider>(context, listen: false);
      
      // Create completed activity
      final success = await fitnessProvider.createActivity(
        activityType: _activityData['activityType'],
        durationMinutes: _elapsedTime.inMinutes,
        distanceKm: _totalDistance,
        caloriesBurned: _currentCalories,
        activityName: _activityData['activityName'],
        startLocation: _activityData['startLocation'],
        endLocation: 'Current Location', // TODO: Get actual end location
        startLatitude: _activityData['startLatitude'],
        startLongitude: _activityData['startLongitude'],
        endLatitude: _currentLocation?.latitude,
        endLongitude: _currentLocation?.longitude,
        linkedGoalIds: List<int>.from(_activityData['linkedGoalIds'] ?? []),
      );

      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        
        if (success) {
          // Update goal progress if goals are linked
          if (_activityData['linkedGoalIds'] != null && 
              (_activityData['linkedGoalIds'] as List).isNotEmpty) {
            final goalsProvider = Provider.of<GoalsProvider>(context, listen: false);
            
            final completedActivity = FitnessActivity(
              id: 0,
              activityType: _activityData['activityType'],
              name: _activityData['activityName'],
              durationMinutes: _elapsedTime.inMinutes,
              distanceKm: _totalDistance,
              caloriesBurned: _currentCalories,
              startTime: _startTime!,
              endTime: DateTime.now(),
              startLocation: _activityData['startLocation'],
              startLatitude: _activityData['startLatitude'],
              startLongitude: _activityData['startLongitude'],
              endLatitude: _currentLocation?.latitude,
              endLongitude: _currentLocation?.longitude,
              linkedGoalIds: List<int>.from(_activityData['linkedGoalIds']),
              isCompleted: true,
            );
            
            try {
              await goalsProvider.updateGoalProgress(completedActivity);
              AppLogger.info('Updated progress for linked goals', 'LiveTracking');
            } catch (e) {
              AppLogger.error('Failed to update goal progress: $e', 'LiveTracking');
            }
          }
          
          Navigator.of(context).popUntil((route) => route.settings.name == '/home');
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Activity "${_activityData['activityName']}" completed successfully!'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          _showError('Failed to save activity');
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        _showError('Error saving activity: $e');
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return '${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildTrackingInterface()),
            _buildControlButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              if (_isTracking) {
                _showStopConfirmation();
              } else {
                Navigator.of(context).pop();
              }
            },
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  _activityData['activityName']?.toString() ?? 'Live Tracking',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _activityData['activityType']?.toString() ?? 'Activity',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _isTracking 
                  ? (_isPaused ? Colors.orange : Colors.green)
                  : Colors.grey,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _isTracking ? (_isPaused ? 'PAUSED' : 'LIVE') : 'READY',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackingInterface() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Main time display
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.primaryColor.withValues(alpha: 0.2),
                  AppTheme.primaryColor.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppTheme.primaryColor.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              children: [
                Text(
                  _formatDuration(_elapsedTime),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
                const Text(
                  'ELAPSED TIME',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Metrics grid
          Row(
            children: [
              Expanded(child: _buildMetricCard('Distance', '${_totalDistance.toStringAsFixed(2)} km', Icons.straighten)),
              const SizedBox(width: 12),
              Expanded(child: _buildMetricCard('Calories', '$_currentCalories cal', Icons.local_fire_department)),
            ],
          ),
          
          const SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(child: _buildMetricCard('Avg Speed', '${_averageSpeed.toStringAsFixed(1)} km/h', Icons.speed)),
              const SizedBox(width: 12),
              Expanded(child: _buildMetricCard('Current', '${_currentSpeed.toStringAsFixed(1)} km/h', Icons.navigation)),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Location info
          if (_currentLocation != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Text(
                    'GPS STATUS',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.gps_fixed,
                        color: _currentLocation!.accuracy! < 10 ? Colors.green : Colors.orange,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Accuracy: ${_currentLocation!.accuracy?.toStringAsFixed(0)}m',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
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

  Widget _buildMetricCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: Colors.white70,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButtons() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          if (!_isTracking)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _startTracking,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 4,
                ),
                icon: const Icon(Icons.play_arrow, size: 24),
                label: const Text(
                  'START TRACKING',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isPaused ? _resumeTracking : _pauseTracking,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isPaused ? Colors.green : Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    icon: Icon(_isPaused ? Icons.play_arrow : Icons.pause, size: 20),
                    label: Text(_isPaused ? 'RESUME' : 'PAUSE'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _finishActivity,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    icon: const Icon(Icons.stop, size: 20),
                    label: const Text('FINISH'),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  void _showStopConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Stop Tracking?'),
        content: const Text('Are you sure you want to stop tracking? Your progress will be lost if you don\'t finish the activity.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Stop', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}