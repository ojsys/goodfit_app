import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../models/route.dart' as route_model;
import '../services/map_service.dart';
import '../services/live_activity_service.dart';

class RouteMapWidget extends StatefulWidget {
  final route_model.Route? route;
  final bool enableLiveTracking;
  final bool showUserLocation;
  final double height;
  final VoidCallback? onMapCreated;
  final Function(LatLng)? onMapTap;

  const RouteMapWidget({
    super.key,
    this.route,
    this.enableLiveTracking = false,
    this.showUserLocation = true,
    this.height = 300,
    this.onMapCreated,
    this.onMapTap,
  });

  @override
  State<RouteMapWidget> createState() => _RouteMapWidgetState();
}

class _RouteMapWidgetState extends State<RouteMapWidget> {
  GoogleMapController? _controller;
  late MapService _mapService;

  @override
  void initState() {
    super.initState();
    _mapService = MapService();
    
    // Display route if provided
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.route != null) {
        _mapService.displayRoute(widget.route!);
      }
      
      // Start live tracking if enabled
      if (widget.enableLiveTracking) {
        _startLiveTracking();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            // Google Map
            Consumer<MapService>(
              builder: (context, mapService, child) {
                return GoogleMap(
                  onMapCreated: _onMapCreated,
                  onTap: widget.onMapTap,
                  initialCameraPosition: CameraPosition(
                    target: mapService.currentCenter,
                    zoom: mapService.currentZoom,
                  ),
                  markers: mapService.markers,
                  polylines: mapService.polylines,
                  circles: mapService.circles,
                  myLocationEnabled: widget.showUserLocation,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  mapToolbarEnabled: false,
                  buildingsEnabled: true,
                  trafficEnabled: false,
                );
              },
            ),
            
            // Control buttons overlay
            if (widget.enableLiveTracking || widget.showUserLocation)
              Positioned(
                top: 8,
                right: 8,
                child: Column(
                  children: [
                    // Current location button
                    if (widget.showUserLocation)
                      _buildControlButton(
                        icon: Icons.my_location,
                        onTap: _mapService.moveToCurrentLocation,
                        tooltip: 'Go to current location',
                      ),
                    
                    const SizedBox(height: 8),
                    
                    // Live tracking toggle
                    if (widget.enableLiveTracking)
                      Consumer<LiveActivityService>(
                        builder: (context, liveActivityService, child) {
                          final isActive = liveActivityService.isLiveActivityActive;
                          return _buildControlButton(
                            icon: isActive ? Icons.stop : Icons.play_arrow,
                            onTap: isActive ? _stopLiveTracking : _startLiveTracking,
                            tooltip: isActive ? 'Stop tracking' : 'Start tracking',
                            backgroundColor: isActive ? Colors.red : Colors.green,
                          );
                        },
                      ),
                  ],
                ),
              ),
            
            // Route info overlay
            if (widget.route != null)
              Positioned(
                bottom: 8,
                left: 8,
                right: 8,
                child: _buildRouteInfoCard(),
              ),
            
            // Live tracking stats overlay
            if (widget.enableLiveTracking)
              Positioned(
                top: 8,
                left: 8,
                child: Consumer<LiveActivityService>(
                  builder: (context, liveActivityService, child) {
                    if (!liveActivityService.isLiveActivityActive) {
                      return const SizedBox.shrink();
                    }
                    
                    final metrics = liveActivityService.getCurrentLiveMetrics();
                    return _buildLiveStatsCard(metrics);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onTap,
    required String tooltip,
    Color? backgroundColor,
  }) {
    return Material(
      color: backgroundColor ?? Colors.white,
      elevation: 4,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: backgroundColor != null ? Colors.white : Colors.black87,
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildRouteInfoCard() {
    if (widget.route == null) return const SizedBox.shrink();
    
    final route = widget.route!;
    
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    route.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getDifficultyColor(route.difficultyLevel),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getDifficultyText(route.difficultyLevel),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            Row(
              children: [
                _buildInfoChip(
                  icon: Icons.straighten,
                  label: route.formattedDistance,
                ),
                const SizedBox(width: 8),
                _buildInfoChip(
                  icon: Icons.terrain,
                  label: route.formattedElevationGain,
                ),
                const SizedBox(width: 8),
                _buildInfoChip(
                  icon: Icons.access_time,
                  label: route.formattedEstimatedDuration,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveStatsCard(Map<String, dynamic> metrics) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.circle, color: Colors.red, size: 8),
                const SizedBox(width: 4),
                const Text(
                  'LIVE',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 4),
            
            Text(
              '${(metrics['distance'] as double? ?? 0).toStringAsFixed(2)} km',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            
            Text(
              _formatDuration(metrics['duration'] as int? ?? 0),
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade600),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
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

  void _onMapCreated(GoogleMapController controller) {
    _controller = controller;
    _mapService.setMapController(controller);
    widget.onMapCreated?.call();
  }

  void _startLiveTracking() async {
    final success = await _mapService.startLiveTracking();
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Live tracking started'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _stopLiveTracking() async {
    await _mapService.stopLiveTracking();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Live tracking stopped'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}