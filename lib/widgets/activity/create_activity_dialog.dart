import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import '../../providers/fitness_provider.dart';
import '../../utils/distance_calculator.dart';
import '../../utils/logger.dart';

class CreateActivityDialog extends StatefulWidget {
  const CreateActivityDialog({super.key});

  @override
  State<CreateActivityDialog> createState() => _CreateActivityDialogState();
}

class _CreateActivityDialogState extends State<CreateActivityDialog> {
  final _formKey = GlobalKey<FormState>();
  final _activityTypeController = TextEditingController();
  final _durationController = TextEditingController();
  final _startLocationController = TextEditingController();
  final _endLocationController = TextEditingController();

  String _selectedActivityType = 'Running';
  double? _calculatedDistance;
  int? _estimatedCalories;
  Position? _startPosition;
  Position? _endPosition;
  bool _isCalculating = false;

  final List<String> _activityTypes = [
    'Running',
    'Walking',
    'Cycling',
    'Hiking',
    'Swimming',
    'Yoga',
    'Strength Training',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    _activityTypeController.text = _selectedActivityType;
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      final permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied || 
          permission == LocationPermission.deniedForever) {
        AppLogger.warning('Location permission denied', 'CreateActivity');
        return;
      }

      final position = await Geolocator.getCurrentPosition();
      final addresses = await placemarkFromCoordinates(
        position.latitude, 
        position.longitude
      );
      
      if (addresses.isNotEmpty) {
        final address = addresses.first;
        final locationString = '${address.street}, ${address.locality}';
        _startLocationController.text = locationString;
        _startPosition = position;
      }
    } catch (e) {
      AppLogger.error('Error getting current location', 'CreateActivity', e);
    }
  }

  Future<void> _geocodeLocation(String address, bool isStart) async {
    try {
      setState(() => _isCalculating = true);
      
      final locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        final location = locations.first;
        final position = Position(
          latitude: location.latitude,
          longitude: location.longitude,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          altitudeAccuracy: 0,
          heading: 0,
          headingAccuracy: 0,
          speed: 0,
          speedAccuracy: 0,
        );

        if (isStart) {
          _startPosition = position;
        } else {
          _endPosition = position;
        }

        _calculateDistance();
      }
    } catch (e) {
      AppLogger.error('Error geocoding location', 'CreateActivity', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not find location: $address')),
        );
      }
    } finally {
      setState(() => _isCalculating = false);
    }
  }

  void _calculateDistance() {
    if (_startPosition != null && _endPosition != null) {
      final distance = DistanceCalculator.calculateDistance(
        _startPosition!.latitude,
        _startPosition!.longitude,
        _endPosition!.latitude,
        _endPosition!.longitude,
      );

      setState(() {
        _calculatedDistance = distance;
        _updateEstimatedCalories();
      });
    }
  }

  void _updateEstimatedCalories() {
    final duration = int.tryParse(_durationController.text);
    if (duration != null) {
      setState(() {
        _estimatedCalories = DistanceCalculator.estimateCalories(
          activityType: _selectedActivityType,
          durationMinutes: duration,
          distanceKm: _calculatedDistance,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Plan Your Activity'),
      content: SizedBox(
        width: double.maxFinite,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Activity Type Dropdown
                DropdownButtonFormField<String>(
                  value: _selectedActivityType,
                  decoration: const InputDecoration(
                    labelText: 'Activity Type',
                    prefixIcon: Icon(Icons.fitness_center),
                  ),
                  items: _activityTypes.map((type) {
                    return DropdownMenuItem(value: type, child: Text(type));
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedActivityType = value!;
                      _activityTypeController.text = value;
                      _updateEstimatedCalories();
                    });
                  },
                  validator: (value) => value == null ? 'Please select an activity type' : null,
                ),
                const SizedBox(height: 16),

                // Duration
                TextFormField(
                  controller: _durationController,
                  decoration: const InputDecoration(
                    labelText: 'Duration (minutes)',
                    prefixIcon: Icon(Icons.timer),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (_) => _updateEstimatedCalories(),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter duration';
                    }
                    if (int.tryParse(value) == null || int.parse(value) <= 0) {
                      return 'Please enter a valid duration';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Start Location
                TextFormField(
                  controller: _startLocationController,
                  decoration: InputDecoration(
                    labelText: 'Start Location',
                    prefixIcon: const Icon(Icons.my_location),
                    suffixIcon: _isCalculating 
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : IconButton(
                            icon: const Icon(Icons.search),
                            onPressed: () {
                              if (_startLocationController.text.isNotEmpty) {
                                _geocodeLocation(_startLocationController.text, true);
                              }
                            },
                          ),
                  ),
                  onFieldSubmitted: (value) => _geocodeLocation(value, true),
                ),
                const SizedBox(height: 16),

                // End Location
                TextFormField(
                  controller: _endLocationController,
                  decoration: InputDecoration(
                    labelText: 'End Location (Optional)',
                    prefixIcon: const Icon(Icons.location_on),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: () {
                        if (_endLocationController.text.isNotEmpty) {
                          _geocodeLocation(_endLocationController.text, false);
                        }
                      },
                    ),
                  ),
                  onFieldSubmitted: (value) => _geocodeLocation(value, false),
                ),

                if (_calculatedDistance != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.straighten, color: Colors.blue),
                            const SizedBox(width: 8),
                            Text(
                              'Distance: ${DistanceCalculator.formatDistance(_calculatedDistance!)}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        if (_estimatedCalories != null) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.local_fire_department, color: Colors.orange),
                              const SizedBox(width: 8),
                              Text('Estimated: $_estimatedCalories calories'),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        Consumer<FitnessProvider>(
          builder: (context, fitnessProvider, child) {
            return ElevatedButton(
              onPressed: fitnessProvider.isLoading
                  ? null
                  : () async {
                      if (_formKey.currentState!.validate()) {
                        final success = await fitnessProvider.createActivity(
                          activityType: _selectedActivityType,
                          durationMinutes: int.parse(_durationController.text),
                          distanceKm: _calculatedDistance,
                          caloriesBurned: _estimatedCalories,
                          startLocation: _startLocationController.text.isNotEmpty 
                              ? _startLocationController.text 
                              : null,
                          endLocation: _endLocationController.text.isNotEmpty 
                              ? _endLocationController.text 
                              : null,
                          startLatitude: _startPosition?.latitude,
                          startLongitude: _startPosition?.longitude,
                          endLatitude: _endPosition?.latitude,
                          endLongitude: _endPosition?.longitude,
                        );

                        if (success && context.mounted) {
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Activity added successfully!')),
                          );
                        } else if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(fitnessProvider.errorMessage ?? 'Failed to add activity'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
              child: fitnessProvider.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Create Activity'),
            );
          },
        ),
      ],
    );
  }

  @override
  void dispose() {
    _activityTypeController.dispose();
    _durationController.dispose();
    _startLocationController.dispose();
    _endLocationController.dispose();
    super.dispose();
  }
}