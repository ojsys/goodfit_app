import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../models/route.dart' as route_model;
import '../services/map_service.dart';
import '../services/route_tracking_service.dart';
import '../services/gps_tracking_service.dart';

class EnhancedRouteMap extends StatefulWidget {
  final route_model.Route? route;
  final bool enableRouteTracking;
  final bool showHeatmap;
  final double height;
  final Function(RouteTrackingAnalytics)? onTrackingComplete;

  const EnhancedRouteMap({
    super.key,
    this.route,
    this.enableRouteTracking = false,
    this.showHeatmap = false,
    this.height = 400,
    this.onTrackingComplete,
  });

  @override
  State<EnhancedRouteMap> createState() => _EnhancedRouteMapState();
}

class _EnhancedRouteMapState extends State<EnhancedRouteMap> {
  GoogleMapController? _controller;
  late MapService _mapService;
  late RouteTrackingService _routeTrackingService;
  late GPSTrackingService _gpsService;

  @override
  void initState() {
    super.initState();
    _mapService = MapService();
    _routeTrackingService = RouteTrackingService();
    _gpsService = GPSTrackingService();
    
    // Start route tracking if enabled
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.enableRouteTracking && widget.route != null) {
        _startRouteTracking();
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
            Consumer3<MapService, RouteTrackingService, GPSTrackingService>(
              builder: (context, mapService, trackingService, gpsService, child) {
                return GoogleMap(
                  onMapCreated: _onMapCreated,
                  initialCameraPosition: CameraPosition(
                    target: mapService.currentCenter,
                    zoom: mapService.currentZoom,
                  ),
                  markers: _buildMarkers(mapService, trackingService),
                  polylines: _buildPolylines(mapService, trackingService),
                  circles: _buildCircles(trackingService),
                  myLocationEnabled: false, // We handle location manually
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  mapToolbarEnabled: false,
                  buildingsEnabled: true,
                  trafficEnabled: false,
                );
              },
            ),
            
            // Tracking controls overlay
            if (widget.enableRouteTracking)
              Positioned(
                top: 16,
                right: 16,
                child: _buildTrackingControls(),
              ),
            
            // Route info overlay
            if (widget.route != null && !widget.enableRouteTracking)
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: _buildRouteInfoCard(),
              ),
            
            // Real-time metrics overlay (only when tracking)
            if (widget.enableRouteTracking)
              Positioned(
                top: 16,
                left: 16,
                child: _buildMetricsOverlay(),
              ),
          ],
        ),
      ),
    );
  }

  Set<Marker> _buildMarkers(MapService mapService, RouteTrackingService trackingService) {
    final markers = <Marker>{};
    
    // Add base map markers
    markers.addAll(mapService.markers);
    
    // Add route tracking specific markers
    if (trackingService.currentRoute != null) {
      // Next waypoint marker
      if (trackingService.nextWaypoint != null) {
        markers.add(
          Marker(
            markerId: const MarkerId('next_waypoint'),
            position: trackingService.nextWaypoint!,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
            infoWindow: InfoWindow(
              title: 'Next Waypoint',
              snippet: '${trackingService.distanceToNextWaypoint.toStringAsFixed(0)}m away',
            ),
          ),
        );
      }
      
      // Current position with status color
      if (_gpsService.currentPosition != null) {
        final position = LatLng(
          _gpsService.currentPosition!.latitude,
          _gpsService.currentPosition!.longitude,
        );
        
        markers.add(
          Marker(
            markerId: const MarkerId('current_position_tracking'),
            position: position,
            icon: BitmapDescriptor.defaultMarkerWithHue(
              trackingService.isOffRoute ? BitmapDescriptor.hueRed : BitmapDescriptor.hueBlue,
            ),
            infoWindow: InfoWindow(
              title: trackingService.isOffRoute ? 'Off Route' : 'On Route',
              snippet: 'Distance from route: ${trackingService.distanceFromRoute.toStringAsFixed(0)}m',
            ),
          ),
        );
      }
    }
    
    return markers;
  }

  Set<Polyline> _buildPolylines(MapService mapService, RouteTrackingService trackingService) {
    final polylines = <Polyline>{};
    
    // Add base map polylines
    polylines.addAll(mapService.polylines);
    
    if (trackingService.currentRoute != null) {
      // Original route polyline (dashed)
      if (trackingService.routePoints.isNotEmpty) {
        polylines.add(
          Polyline(
            polylineId: const PolylineId('original_route'),
            points: trackingService.routePoints,
            color: Colors.blue.withOpacity(0.6),
            width: 4,
            patterns: [PatternItem.dash(10), PatternItem.gap(5)],
          ),
        );
      }
      
      // User's actual path
      if (trackingService.userTrackingPoints.isNotEmpty) {
        polylines.add(
          Polyline(
            polylineId: const PolylineId('user_tracking_path'),
            points: trackingService.userTrackingPoints,
            color: trackingService.isOffRoute ? Colors.red : Colors.green,
            width: 6,
            patterns: [],
          ),
        );
      }
      
      // Completed route sections (different color)
      if (trackingService.currentRouteSegment > 0 && trackingService.routePoints.isNotEmpty) {
        final completedPoints = trackingService.routePoints
            .take(trackingService.currentRouteSegment + 1)
            .toList();
        
        polylines.add(
          Polyline(
            polylineId: const PolylineId('completed_route'),
            points: completedPoints,
            color: Colors.green.withOpacity(0.8),
            width: 3,
          ),
        );
      }
    }
    
    return polylines;
  }

  Set<Circle> _buildCircles(RouteTrackingService trackingService) {
    final circles = <Circle>{};
    
    // Add deviation indicator circle
    if (trackingService.isOffRoute && _gpsService.currentPosition != null) {
      final position = LatLng(
        _gpsService.currentPosition!.latitude,
        _gpsService.currentPosition!.longitude,
      );
      
      circles.add(
        Circle(
          circleId: const CircleId('deviation_zone'),
          center: position,
          radius: trackingService.distanceFromRoute,
          fillColor: Colors.red.withOpacity(0.1),
          strokeColor: Colors.red,
          strokeWidth: 2,
        ),
      );
    }
    
    // Add waypoint radius circle
    if (trackingService.nextWaypoint != null) {
      circles.add(
        Circle(
          circleId: const CircleId('waypoint_radius'),
          center: trackingService.nextWaypoint!,
          radius: 20, // waypoint radius
          fillColor: Colors.yellow.withOpacity(0.1),
          strokeColor: Colors.yellow,
          strokeWidth: 1,
        ),
      );
    }
    
    return circles;
  }

  Widget _buildTrackingControls() {
    return Consumer<RouteTrackingService>(
      builder: (context, trackingService, child) {
        return Column(
          children: [
            _buildControlButton(
              icon: Icons.center_focus_strong,
              onTap: _centerOnUser,
              tooltip: 'Center on current position',
            ),
            const SizedBox(height: 8),
            _buildControlButton(
              icon: Icons.layers,
              onTap: _toggleHeatmap,
              tooltip: 'Toggle heatmap',
              isActive: widget.showHeatmap,
            ),
          ],
        );
      },
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onTap,
    required String tooltip,
    bool isActive = false,
  }) {
    return Material(
      color: isActive ? Colors.blue : Colors.white,
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
            color: isActive ? Colors.white : Colors.black87,
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildRouteInfoCard() {
    if (widget.route == null) return const SizedBox.shrink();
    
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.route!.name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildInfoChip(
                  icon: Icons.straighten,
                  label: widget.route!.formattedDistance,
                ),
                const SizedBox(width: 8),
                _buildInfoChip(
                  icon: Icons.terrain,
                  label: widget.route!.formattedElevationGain,
                ),
                const SizedBox(width: 8),
                _buildInfoChip(
                  icon: Icons.access_time,
                  label: widget.route!.formattedEstimatedDuration,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsOverlay() {
    return Consumer<RouteTrackingService>(
      builder: (context, trackingService, child) {
        if (trackingService.currentRoute == null) {
          return const SizedBox.shrink();
        }

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
                    Icon(
                      trackingService.isOffRoute ? Icons.warning : Icons.navigation,
                      color: trackingService.isOffRoute ? Colors.red : Colors.green,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      trackingService.isOffRoute ? 'OFF ROUTE' : 'ON ROUTE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: trackingService.isOffRoute ? Colors.red : Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${(trackingService.routeCompletion * 100).toStringAsFixed(0)}% complete',
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 2),
                LinearProgressIndicator(
                  value: trackingService.routeCompletion,
                  backgroundColor: Colors.grey.shade300,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    trackingService.isOffRoute ? Colors.red : Colors.green,
                  ),
                  minHeight: 3,
                ),
              ],
            ),
          ),
        );
      },
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

  void _onMapCreated(GoogleMapController controller) {
    _controller = controller;
    _mapService.setMapController(controller);
    
    // Display route if provided
    if (widget.route != null) {
      _mapService.displayRoute(widget.route!);
    }
  }

  Future<void> _startRouteTracking() async {
    if (widget.route == null) return;
    
    final success = await _routeTrackingService.startRouteTracking(widget.route!);
    if (!success) {
      debugPrint('Failed to start route tracking');
    }
  }

  void _centerOnUser() async {
    if (_gpsService.currentPosition != null) {
      await _mapService.updateCamera(
        LatLng(
          _gpsService.currentPosition!.latitude,
          _gpsService.currentPosition!.longitude,
        ),
        zoom: 17.0,
      );
    }
  }

  void _toggleHeatmap() {
    // TODO: Implement heatmap toggle
    debugPrint('Heatmap toggle - feature coming soon');
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}