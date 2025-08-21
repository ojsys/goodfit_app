import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/route.dart' as route_model;
import '../widgets/route_map_widget.dart';
import '../services/live_activity_service.dart';
import '../screens/live_tracking_screen.dart';

class RouteDetailsScreen extends StatefulWidget {
  final route_model.Route route;

  const RouteDetailsScreen({
    super.key,
    required this.route,
  });

  @override
  State<RouteDetailsScreen> createState() => _RouteDetailsScreenState();
}

class _RouteDetailsScreenState extends State<RouteDetailsScreen> {
  int _selectedRating = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar with Route Map
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: Colors.white,
            foregroundColor: Colors.black87,
            flexibleSpace: FlexibleSpaceBar(
              background: RouteMapWidget(
                route: widget.route,
                height: 300,
                showUserLocation: true,
              ),
            ),
          ),
          
          // Route Details Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Route Title and Basic Info
                  _buildRouteHeader(),
                  
                  const SizedBox(height: 20),
                  
                  // Key Metrics
                  _buildKeyMetrics(),
                  
                  const SizedBox(height: 24),
                  
                  // Description
                  if (widget.route.description.isNotEmpty) ...[
                    _buildSectionTitle('Description'),
                    const SizedBox(height: 8),
                    Text(
                      widget.route.description,
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  
                  // Route Details
                  _buildSectionTitle('Route Details'),
                  const SizedBox(height: 12),
                  _buildRouteDetails(),
                  
                  const SizedBox(height: 24),
                  
                  // Ratings and Reviews
                  _buildSectionTitle('Ratings'),
                  const SizedBox(height: 12),
                  _buildRatingsSection(),
                  
                  const SizedBox(height: 24),
                  
                  // Rate This Route
                  _buildSectionTitle('Rate This Route'),
                  const SizedBox(height: 12),
                  _buildRateRoute(),
                  
                  const SizedBox(height: 100), // Space for bottom buttons
                ],
              ),
            ),
          ),
        ],
      ),
      
      // Bottom Action Buttons
      bottomSheet: _buildBottomActions(),
    );
  }

  Widget _buildRouteHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                widget.route.name,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            _buildDifficultyBadge(),
          ],
        ),
        
        const SizedBox(height: 12),
        
        // Location info
        if (widget.route.startLocationName.isNotEmpty || 
            widget.route.endLocationName.isNotEmpty) ...[
          Row(
            children: [
              const Icon(Icons.location_on, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  _buildLocationText(),
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        
        // Activity types and surface
        _buildRouteTypeChips(),
      ],
    );
  }

  Widget _buildKeyMetrics() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMetricItem(
                icon: Icons.straighten,
                label: 'Distance',
                value: widget.route.formattedDistance,
                color: Colors.blue,
              ),
              _buildMetricItem(
                icon: Icons.terrain,
                label: 'Elevation',
                value: widget.route.formattedElevationGain,
                color: Colors.orange,
              ),
              _buildMetricItem(
                icon: Icons.access_time,
                label: 'Est. Time',
                value: widget.route.formattedEstimatedDuration,
                color: Colors.green,
              ),
            ],
          ),
          
          if (widget.route.averageRating > 0) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMetricItem(
                  icon: Icons.star,
                  label: 'Rating',
                  value: widget.route.averageRating.toStringAsFixed(1),
                  color: Colors.amber,
                ),
                _buildMetricItem(
                  icon: Icons.people,
                  label: 'Used',
                  value: '${widget.route.timesUsed} times',
                  color: Colors.purple,
                ),
                _buildMetricItem(
                  icon: Icons.reviews,
                  label: 'Reviews',
                  value: '${widget.route.totalRatings}',
                  color: Colors.teal,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildRouteDetails() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildDetailRow('Surface Type', _formatSurfaceType(widget.route.surfaceType)),
          _buildDetailRow('Difficulty', widget.route.difficultyDescription),
          _buildDetailRow('Elevation Profile', widget.route.elevationProfile),
          if (widget.route.averagePace != null)
            _buildDetailRow('Average Pace', '${widget.route.averagePace!.toStringAsFixed(1)} min/km'),
          _buildDetailRow('Safety Rating', _buildStars(widget.route.safetyRating)),
          _buildDetailRow('Scenic Rating', _buildStars(widget.route.scenicRating)),
          _buildDetailRow('Created', _formatDate(widget.route.createdAt)),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: value is Widget 
                ? value 
                : Text(
                    value.toString(),
                    style: const TextStyle(fontSize: 16),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                widget.route.averageRating.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: List.generate(5, (index) {
                      return Icon(
                        index < widget.route.averageRating.floor() 
                            ? Icons.star 
                            : Icons.star_border,
                        color: Colors.amber,
                        size: 20,
                      );
                    }),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${widget.route.totalRatings} reviews',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          if (widget.route.totalRatings > 0) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            // Rating distribution would go here
            const Text('Rating distribution coming soon...'),
          ],
        ],
      ),
    );
  }

  Widget _buildRateRoute() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'How would you rate this route?',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: List.generate(5, (index) {
              final rating = index + 1;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedRating = rating;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  margin: const EdgeInsets.only(right: 8),
                  child: Icon(
                    _selectedRating >= rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 32,
                  ),
                ),
              );
            }),
          ),
          if (_selectedRating > 0) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitRating,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text('Submit ${_selectedRating}-Star Rating'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
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
        child: Row(
          children: [
            // Favorite button
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                onPressed: _toggleFavorite,
                icon: const Icon(Icons.favorite_border),
                color: Colors.grey.shade600,
              ),
            ),
            
            const SizedBox(width: 12),
            
            // Start Activity button
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _startActivity,
                icon: const Icon(Icons.play_arrow),
                label: const Text('Start Activity'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDifficultyBadge() {
    final color = _getDifficultyColor(widget.route.difficultyLevel);
    final text = _getDifficultyText(widget.route.difficultyLevel);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildRouteTypeChips() {
    final chips = <Widget>[];
    
    // Add activity types
    for (final activityType in widget.route.activityTypes.take(3)) {
      chips.add(_buildTypeChip(activityType, Colors.blue));
    }
    
    // Add surface type
    if (widget.route.surfaceType.isNotEmpty) {
      chips.add(_buildTypeChip(_formatSurfaceType(widget.route.surfaceType), Colors.green));
    }
    
    if (chips.isEmpty) return const SizedBox.shrink();
    
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: chips,
    );
  }

  Widget _buildTypeChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildStars(int rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          index < rating ? Icons.star : Icons.star_border,
          color: Colors.amber,
          size: 16,
        );
      }),
    );
  }

  String _buildLocationText() {
    if (widget.route.startLocationName.isNotEmpty && widget.route.endLocationName.isNotEmpty) {
      return '${widget.route.startLocationName} → ${widget.route.endLocationName}';
    } else if (widget.route.startLocationName.isNotEmpty) {
      return 'Starts at ${widget.route.startLocationName}';
    } else if (widget.route.endLocationName.isNotEmpty) {
      return 'Ends at ${widget.route.endLocationName}';
    }
    return '';
  }

  String _formatSurfaceType(String surfaceType) {
    return surfaceType.split('_').map((word) => 
        word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1)
    ).join(' ');
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Color _getDifficultyColor(int? difficulty) {
    switch (difficulty) {
      case 1: return Colors.green;
      case 2: return Colors.lightGreen;
      case 3: return Colors.orange;
      case 4: return Colors.deepOrange;
      case 5: return Colors.red;
      default: return Colors.grey;
    }
  }

  String _getDifficultyText(int? difficulty) {
    switch (difficulty) {
      case 1: return 'Beginner';
      case 2: return 'Easy';
      case 3: return 'Moderate';
      case 4: return 'Hard';
      case 5: return 'Expert';
      default: return 'Unknown';
    }
  }

  void _startActivity() {
    // Navigate to live tracking with this route
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LiveTrackingScreen(
          selectedRoute: widget.route,
        ),
      ),
    );
  }

  void _toggleFavorite() {
    // TODO: Implement favorite functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Favorite feature coming soon for ${widget.route.name}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _submitRating() {
    // TODO: Implement rating submission
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Rating submitted: $_selectedRating stars'),
        backgroundColor: Colors.green,
      ),
    );
    
    setState(() {
      _selectedRating = 0;
    });
  }
}