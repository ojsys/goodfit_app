import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import '../models/route.dart' as route_model;
import 'gps_tracking_service.dart';

class MapService extends ChangeNotifier {
  static final MapService _instance = MapService._internal();
  factory MapService() => _instance;
  MapService._internal();

  GoogleMapController? _mapController;
  final GPSTrackingService _gpsService = GPSTrackingService();
  
  // Map state
  LatLng _currentCenter = const LatLng(37.7749, -122.4194); // Default: San Francisco
  double _currentZoom = 14.0;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  final Set<Circle> _circles = {};
  
  // Live tracking state
  bool _isTrackingLive = false;
  StreamSubscription<Position>? _liveTrackingSubscription;
  final List<LatLng> _liveTrackingPoints = [];
  Polyline? _liveTrackingPolyline;
  
  // Route display state
  route_model.Route? _selectedRoute;
  Polyline? _routePolyline;
  
  // Getters
  LatLng get currentCenter => _currentCenter;
  double get currentZoom => _currentZoom;
  Set<Marker> get markers => Set.unmodifiable(_markers);
  Set<Polyline> get polylines => Set.unmodifiable(_polylines);
  Set<Circle> get circles => Set.unmodifiable(_circles);
  bool get isTrackingLive => _isTrackingLive;
  route_model.Route? get selectedRoute => _selectedRoute;
  List<LatLng> get liveTrackingPoints => List.unmodifiable(_liveTrackingPoints);

  /// Initialize the map controller
  void setMapController(GoogleMapController controller) {
    _mapController = controller;
  }

  /// Update map camera position
  Future<void> updateCamera(LatLng center, {double? zoom}) async {
    _currentCenter = center;
    if (zoom != null) _currentZoom = zoom;
    
    if (_mapController != null) {
      await _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: center, zoom: zoom ?? _currentZoom),
        ),
      );
    }
    notifyListeners();
  }

  /// Move to user's current location
  Future<bool> moveToCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition();
      final userLocation = LatLng(position.latitude, position.longitude);
      
      await updateCamera(userLocation, zoom: 16.0);
      
      // Add current location marker
      await _addCurrentLocationMarker(userLocation);
      
      return true;
    } catch (e) {
      debugPrint('Error getting current location: $e');
      return false;
    }
  }

  /// Display a route on the map
  Future<void> displayRoute(route_model.Route route) async {
    _selectedRoute = route;
    _clearRouteDisplay();
    
    try {
      // Decode polyline and create route polyline
      List<LatLng> routePoints = [];
      
      if (route.coordinates != null && route.coordinates!.isNotEmpty) {
        routePoints = route.coordinates!;
      } else if (route.polyline.isNotEmpty) {
        routePoints = await _decodePolyline(route.polyline);
      }
      
      if (routePoints.isNotEmpty) {
        // Create route polyline
        _routePolyline = Polyline(
          polylineId: const PolylineId('selected_route'),
          points: routePoints,
          color: Colors.blue,
          width: 4,
          patterns: [],
        );
        _polylines.add(_routePolyline!);
        
        // Add start and end markers
        await _addRouteMarkers(route, routePoints);
        
        // Fit map to route bounds
        await _fitMapToPoints(routePoints);
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error displaying route: $e');
    }
  }

  /// Start live tracking with map updates
  Future<bool> startLiveTracking() async {
    if (_isTrackingLive) return true;
    
    try {
      final started = await _gpsService.startTracking();
      if (!started) return false;
      
      _isTrackingLive = true;
      _liveTrackingPoints.clear();
      _clearLiveTrackingDisplay();
      
      // Listen to GPS updates
      _liveTrackingSubscription = _gpsService.trackingPoints.isNotEmpty 
          ? Stream.periodic(const Duration(seconds: 2))
              .map((_) => _gpsService.trackingPoints.last)
              .listen(_updateLiveTracking)
          : null;
      
      // Initial position update
      if (_gpsService.currentPosition != null) {
        _updateLiveTracking(_gpsService.currentPosition!);
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error starting live tracking: $e');
      return false;
    }
  }

  /// Stop live tracking
  Future<void> stopLiveTracking() async {
    _isTrackingLive = false;
    await _liveTrackingSubscription?.cancel();
    _liveTrackingSubscription = null;
    
    // Keep the final tracking polyline for review
    if (_liveTrackingPoints.isNotEmpty) {
      _liveTrackingPolyline = Polyline(
        polylineId: const PolylineId('completed_live_track'),
        points: _liveTrackingPoints,
        color: Colors.green,
        width: 4,
      );
      _polylines.add(_liveTrackingPolyline!);
    }
    
    notifyListeners();
  }

  /// Update live tracking with new position
  void _updateLiveTracking(Position position) {
    if (!_isTrackingLive) return;
    
    final newPoint = LatLng(position.latitude, position.longitude);
    _liveTrackingPoints.add(newPoint);
    
    // Update live tracking polyline
    if (_liveTrackingPoints.length > 1) {
      _polylines.removeWhere((p) => p.polylineId.value == 'live_tracking');
      
      _liveTrackingPolyline = Polyline(
        polylineId: const PolylineId('live_tracking'),
        points: _liveTrackingPoints,
        color: Colors.red,
        width: 4,
      );
      _polylines.add(_liveTrackingPolyline!);
    }
    
    // Update current position marker
    _addCurrentLocationMarker(newPoint, isLiveTracking: true);
    
    // Keep map centered on current position
    updateCamera(newPoint, zoom: 17.0);
  }

  /// Add current location marker
  Future<void> _addCurrentLocationMarker(LatLng location, {bool isLiveTracking = false}) async {
    _markers.removeWhere((m) => m.markerId.value == 'current_location');
    
    final BitmapDescriptor icon = isLiveTracking 
        ? await _createCustomMarkerIcon(Colors.red, 'LIVE')
        : BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
    
    _markers.add(
      Marker(
        markerId: const MarkerId('current_location'),
        position: location,
        icon: icon,
        infoWindow: InfoWindow(
          title: isLiveTracking ? 'Live Tracking' : 'Current Location',
          snippet: 'Lat: ${location.latitude.toStringAsFixed(6)}, Lng: ${location.longitude.toStringAsFixed(6)}',
        ),
      ),
    );
  }

  /// Add route start and end markers
  Future<void> _addRouteMarkers(route_model.Route route, List<LatLng> routePoints) async {
    if (routePoints.isEmpty) return;
    
    // Start marker
    _markers.add(
      Marker(
        markerId: const MarkerId('route_start'),
        position: routePoints.first,
        icon: await _createCustomMarkerIcon(Colors.green, 'START'),
        infoWindow: InfoWindow(
          title: 'Start: ${route.name}',
          snippet: route.startLocationName.isNotEmpty ? route.startLocationName : 'Route starting point',
        ),
      ),
    );
    
    // End marker
    if (routePoints.length > 1) {
      _markers.add(
        Marker(
          markerId: const MarkerId('route_end'),
          position: routePoints.last,
          icon: await _createCustomMarkerIcon(Colors.red, 'END'),
          infoWindow: InfoWindow(
            title: 'End: ${route.name}',
            snippet: route.endLocationName.isNotEmpty ? route.endLocationName : 'Route ending point',
          ),
        ),
      );
    }
  }

  /// Create custom marker icon
  Future<BitmapDescriptor> _createCustomMarkerIcon(Color color, String text) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    final Paint paint = Paint()..color = color;
    const double size = 100.0;

    // Draw circle
    canvas.drawCircle(const Offset(size / 2, size / 2), size / 2, paint);

    // Draw text
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas, 
      Offset(
        (size - textPainter.width) / 2, 
        (size - textPainter.height) / 2
      ),
    );

    final ui.Image image = await pictureRecorder.endRecording().toImage(
      size.toInt(), 
      size.toInt(),
    );
    final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final Uint8List uint8List = byteData!.buffer.asUint8List();

    return BitmapDescriptor.bytes(uint8List);
  }

  /// Decode Google polyline
  Future<List<LatLng>> _decodePolyline(String polyline) async {
    try {
      final PolylinePoints polylinePoints = PolylinePoints();
      final List<PointLatLng> result = polylinePoints.decodePolyline(polyline);
      
      return result.map((point) => LatLng(point.latitude, point.longitude)).toList();
    } catch (e) {
      debugPrint('Error decoding polyline: $e');
      return [];
    }
  }

  /// Fit map to show all points
  Future<void> _fitMapToPoints(List<LatLng> points) async {
    if (points.isEmpty || _mapController == null) return;
    
    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;
    
    for (final point in points) {
      minLat = math.min(minLat, point.latitude);
      maxLat = math.max(maxLat, point.latitude);
      minLng = math.min(minLng, point.longitude);
      maxLng = math.max(maxLng, point.longitude);
    }
    
    await _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        100.0, // padding
      ),
    );
  }

  /// Clear route display
  void _clearRouteDisplay() {
    _polylines.removeWhere((p) => p.polylineId.value == 'selected_route');
    _markers.removeWhere((m) => 
        m.markerId.value == 'route_start' || 
        m.markerId.value == 'route_end'
    );
    _routePolyline = null;
  }

  /// Clear live tracking display
  void _clearLiveTrackingDisplay() {
    _polylines.removeWhere((p) => 
        p.polylineId.value == 'live_tracking' || 
        p.polylineId.value == 'completed_live_track'
    );
    _liveTrackingPolyline = null;
  }

  /// Clear all map overlays
  void clearMap() {
    _markers.clear();
    _polylines.clear();
    _circles.clear();
    _selectedRoute = null;
    _liveTrackingPoints.clear();
    _routePolyline = null;
    _liveTrackingPolyline = null;
    notifyListeners();
  }

  /// Add a custom marker
  void addMarker(Marker marker) {
    _markers.add(marker);
    notifyListeners();
  }

  /// Remove a marker
  void removeMarker(String markerId) {
    _markers.removeWhere((m) => m.markerId.value == markerId);
    notifyListeners();
  }

  /// Add a polyline
  void addPolyline(Polyline polyline) {
    _polylines.add(polyline);
    notifyListeners();
  }

  /// Remove a polyline
  void removePolyline(String polylineId) {
    _polylines.removeWhere((p) => p.polylineId.value == polylineId);
    notifyListeners();
  }

  /// Get distance between two points
  double getDistanceBetween(LatLng point1, LatLng point2) {
    return Geolocator.distanceBetween(
      point1.latitude, 
      point1.longitude, 
      point2.latitude, 
      point2.longitude,
    );
  }

  @override
  void dispose() {
    _liveTrackingSubscription?.cancel();
    super.dispose();
  }
}
