import 'package:flutter/material.dart';

class RouteFilterSheet extends StatefulWidget {
  final RouteFilters initialFilters;
  final Function(RouteFilters) onApplyFilters;

  const RouteFilterSheet({
    super.key,
    required this.initialFilters,
    required this.onApplyFilters,
  });

  @override
  State<RouteFilterSheet> createState() => _RouteFilterSheetState();
}

class _RouteFilterSheetState extends State<RouteFilterSheet> {
  late RouteFilters _filters;

  @override
  void initState() {
    super.initState();
    _filters = widget.initialFilters.copyWith();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Text(
                'Filter Routes',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: _resetFilters,
                child: const Text('Reset'),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Activity Type
          _buildSectionTitle('Activity Type'),
          const SizedBox(height: 8),
          _buildActivityTypeChips(),
          
          const SizedBox(height: 20),
          
          // Distance Range
          _buildSectionTitle('Distance'),
          const SizedBox(height: 8),
          _buildDistanceSlider(),
          
          const SizedBox(height: 20),
          
          // Difficulty Level
          _buildSectionTitle('Difficulty'),
          const SizedBox(height: 8),
          _buildDifficultySelector(),
          
          const SizedBox(height: 20),
          
          // Surface Type
          _buildSectionTitle('Surface Type'),
          const SizedBox(height: 8),
          _buildSurfaceTypeChips(),
          
          const SizedBox(height: 20),
          
          // Ratings Filter
          _buildSectionTitle('Minimum Rating'),
          const SizedBox(height: 8),
          _buildRatingFilter(),
          
          const SizedBox(height: 30),
          
          // Apply Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _applyFilters,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Apply Filters',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          
          // Add bottom padding for safe area
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildActivityTypeChips() {
    final activityTypes = ['Running', 'Cycling', 'Walking', 'Hiking'];
    
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: activityTypes.map((type) {
        final isSelected = _filters.activityType == type.toLowerCase();
        return FilterChip(
          label: Text(type),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              _filters = _filters.copyWith(
                activityType: selected ? type.toLowerCase() : null,
              );
            });
          },
          selectedColor: Colors.blue.withOpacity(0.2),
          checkmarkColor: Colors.blue,
        );
      }).toList(),
    );
  }

  Widget _buildDistanceSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('${_filters.minDistance.toStringAsFixed(0)} km'),
            Text('${_filters.maxDistance.toStringAsFixed(0)} km'),
          ],
        ),
        RangeSlider(
          values: RangeValues(_filters.minDistance, _filters.maxDistance),
          min: 0,
          max: 50,
          divisions: 50,
          labels: RangeLabels(
            '${_filters.minDistance.toStringAsFixed(0)} km',
            '${_filters.maxDistance.toStringAsFixed(0)} km',
          ),
          onChanged: (RangeValues values) {
            setState(() {
              _filters = _filters.copyWith(
                minDistance: values.start,
                maxDistance: values.end,
              );
            });
          },
        ),
      ],
    );
  }

  Widget _buildDifficultySelector() {
    final difficulties = [
      {'value': 1, 'label': 'Beginner', 'color': Colors.green},
      {'value': 2, 'label': 'Easy', 'color': Colors.lightGreen},
      {'value': 3, 'label': 'Moderate', 'color': Colors.orange},
      {'value': 4, 'label': 'Hard', 'color': Colors.deepOrange},
      {'value': 5, 'label': 'Expert', 'color': Colors.red},
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: difficulties.map((diff) {
        final value = diff['value'] as int;
        final label = diff['label'] as String;
        final color = diff['color'] as Color;
        final isSelected = _filters.difficulty == value;
        
        return FilterChip(
          label: Text(label),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              _filters = _filters.copyWith(
                difficulty: selected ? value : null,
              );
            });
          },
          selectedColor: color.withOpacity(0.2),
          checkmarkColor: color,
        );
      }).toList(),
    );
  }

  Widget _buildSurfaceTypeChips() {
    final surfaceTypes = ['Road', 'Trail', 'Track', 'Gravel', 'Mixed'];
    
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: surfaceTypes.map((type) {
        final isSelected = _filters.surfaceType == type.toLowerCase();
        return FilterChip(
          label: Text(type),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              _filters = _filters.copyWith(
                surfaceType: selected ? type.toLowerCase() : null,
              );
            });
          },
          selectedColor: Colors.green.withOpacity(0.2),
          checkmarkColor: Colors.green,
        );
      }).toList(),
    );
  }

  Widget _buildRatingFilter() {
    return Row(
      children: List.generate(5, (index) {
        final rating = index + 1;
        final isSelected = _filters.minRating >= rating;
        
        return GestureDetector(
          onTap: () {
            setState(() {
              _filters = _filters.copyWith(
                minRating: isSelected && rating == _filters.minRating ? 0 : rating,
              );
            });
          },
          child: Container(
            margin: const EdgeInsets.only(right: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isSelected ? Icons.star : Icons.star_border,
                  color: isSelected ? Colors.amber : Colors.grey,
                  size: 28,
                ),
                if (index == 4) // Show rating text after last star
                  const SizedBox(width: 8),
                if (index == 4 && _filters.minRating > 0)
                  Text(
                    '${_filters.minRating}.0+',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
        );
      }),
    );
  }

  void _resetFilters() {
    setState(() {
      _filters = RouteFilters();
    });
  }

  void _applyFilters() {
    widget.onApplyFilters(_filters);
    Navigator.of(context).pop();
  }
}

class RouteFilters {
  final String? activityType;
  final double minDistance;
  final double maxDistance;
  final int? difficulty;
  final String? surfaceType;
  final int minRating;
  final double? nearbyRadius; // km
  final double? nearbyLat;
  final double? nearbyLng;

  const RouteFilters({
    this.activityType,
    this.minDistance = 0,
    this.maxDistance = 50,
    this.difficulty,
    this.surfaceType,
    this.minRating = 0,
    this.nearbyRadius,
    this.nearbyLat,
    this.nearbyLng,
  });

  RouteFilters copyWith({
    String? activityType,
    double? minDistance,
    double? maxDistance,
    int? difficulty,
    String? surfaceType,
    int? minRating,
    double? nearbyRadius,
    double? nearbyLat,
    double? nearbyLng,
  }) {
    return RouteFilters(
      activityType: activityType ?? this.activityType,
      minDistance: minDistance ?? this.minDistance,
      maxDistance: maxDistance ?? this.maxDistance,
      difficulty: difficulty ?? this.difficulty,
      surfaceType: surfaceType ?? this.surfaceType,
      minRating: minRating ?? this.minRating,
      nearbyRadius: nearbyRadius ?? this.nearbyRadius,
      nearbyLat: nearbyLat ?? this.nearbyLat,
      nearbyLng: nearbyLng ?? this.nearbyLng,
    );
  }

  Map<String, dynamic> toQueryParams() {
    final params = <String, dynamic>{};
    
    if (activityType != null) params['activity_type'] = activityType;
    if (difficulty != null) params['difficulty'] = difficulty;
    if (surfaceType != null) params['surface_type'] = surfaceType;
    if (minRating > 0) params['min_rating'] = minRating;
    if (maxDistance < 50) params['max_distance'] = maxDistance * 1000; // Convert to meters
    if (nearbyLat != null && nearbyLng != null && nearbyRadius != null) {
      params['lat'] = nearbyLat;
      params['lng'] = nearbyLng;
      params['radius'] = nearbyRadius;
    }
    
    return params;
  }

  bool get hasActiveFilters {
    return activityType != null ||
           difficulty != null ||
           surfaceType != null ||
           minRating > 0 ||
           minDistance > 0 ||
           maxDistance < 50 ||
           (nearbyLat != null && nearbyLng != null);
  }

  @override
  String toString() {
    return 'RouteFilters(activityType: $activityType, distance: $minDistance-${maxDistance}km, difficulty: $difficulty, surface: $surfaceType, minRating: $minRating)';
  }
}