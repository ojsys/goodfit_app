import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/route.dart' as route_model;
import 'api_service.dart';

class RouteService extends ChangeNotifier {
  static final RouteService _instance = RouteService._internal();
  factory RouteService() => _instance;
  RouteService._internal();

  final ApiService _apiService = ApiService();
  
  // Cache
  List<route_model.Route> _routes = [];
  Map<String, route_model.Route> _routeCache = {};
  bool _isLoading = false;
  String? _error;

  // Getters
  List<route_model.Route> get routes => List.unmodifiable(_routes);
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Fetch all routes
  Future<List<route_model.Route>> fetchRoutes({
    String? activityType,
    double? maxDistance,
    int? difficulty,
    bool publicOnly = true,
  }) async {
    _setLoading(true);
    
    try {
      final queryParams = <String, dynamic>{};
      if (activityType != null) queryParams['activity_type'] = activityType;
      if (maxDistance != null) queryParams['max_distance'] = maxDistance;
      if (difficulty != null) queryParams['difficulty'] = difficulty;
      if (publicOnly) queryParams['is_public'] = true;

      final response = await _apiService.get('/fitness/routes/${_buildQueryString(queryParams)}');
      
      if (response.success && response.data != null) {
        final results = response.data!['results'] as List<dynamic>? ?? [];
        _routes = results.map((json) => route_model.Route.fromJson(json)).toList();
        
        // Update cache
        for (final route in _routes) {
          _routeCache[route.id] = route;
        }
        
        _setError(null);
        notifyListeners();
        return _routes;
      } else {
        throw Exception(response.error ?? 'Failed to fetch routes');
      }
    } catch (e) {
      _setError(e.toString());
      debugPrint('Error fetching routes: $e');
      return [];
    } finally {
      _setLoading(false);
    }
  }

  /// Get a specific route by ID
  Future<route_model.Route?> getRoute(String routeId) async {
    // Check cache first
    if (_routeCache.containsKey(routeId)) {
      return _routeCache[routeId];
    }

    try {
      final response = await _apiService.get('/fitness/routes/$routeId/');
      
      if (response.success && response.data != null) {
        final route = route_model.Route.fromJson(response.data);
        _routeCache[routeId] = route;
        return route;
      } else {
        debugPrint('Failed to fetch route $routeId: ${response.error}');
        return null;
      }
    } catch (e) {
      debugPrint('Error fetching route $routeId: $e');
      return null;
    }
  }

  /// Search routes by name or location
  Future<List<route_model.Route>> searchRoutes(String query) async {
    if (query.trim().isEmpty) return [];
    
    try {
      final response = await _apiService.get('/fitness/routes/search/${_buildQueryString({'q': query})}');
      
      if (response.success && response.data != null) {
        final results = response.data!['results'] as List<dynamic>? ?? [];
        final routes = results.map((json) => route_model.Route.fromJson(json)).toList();
        
        // Update cache
        for (final route in routes) {
          _routeCache[route.id] = route;
        }
        
        return routes;
      } else {
        throw Exception(response.error ?? 'Search failed');
      }
    } catch (e) {
      debugPrint('Error searching routes: $e');
      return [];
    }
  }

  /// Get routes near a location
  Future<List<route_model.Route>> getRoutesNearLocation({
    required double latitude,
    required double longitude,
    double radiusKm = 10,
    String? activityType,
    int? difficulty,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'lat': latitude,
        'lng': longitude,
        'radius': radiusKm,
      };
      
      if (activityType != null) queryParams['activity_type'] = activityType;
      if (difficulty != null) queryParams['difficulty'] = difficulty;

      final response = await _apiService.get('/fitness/routes/nearby/${_buildQueryString(queryParams)}');
      
      if (response.success && response.data != null) {
        final results = response.data!['results'] as List<dynamic>? ?? [];
        final routes = results.map((json) => route_model.Route.fromJson(json)).toList();
        
        // Update cache
        for (final route in routes) {
          _routeCache[route.id] = route;
        }
        
        return routes;
      } else {
        throw Exception(response.error ?? 'Failed to fetch nearby routes');
      }
    } catch (e) {
      debugPrint('Error fetching nearby routes: $e');
      return [];
    }
  }

  /// Create a new route
  Future<route_model.Route?> createRoute({
    required String name,
    required String description,
    required List<Map<String, double>> coordinates, // [{lat, lng}, ...]
    required double distance,
    double elevationGain = 0,
    double elevationLoss = 0,
    String surfaceType = 'road',
    int? difficultyLevel,
    List<String> activityTypes = const [],
    int safetyRating = 3,
    int scenicRating = 3,
    bool isPublic = true,
  }) async {
    try {
      final routeData = {
        'name': name,
        'description': description,
        'coordinates_json': coordinates,
        'distance': distance,
        'elevation_gain': elevationGain,
        'elevation_loss': elevationLoss,
        'surface_type': surfaceType,
        'difficulty_level': difficultyLevel,
        'activity_types': activityTypes,
        'safety_rating': safetyRating,
        'scenic_rating': scenicRating,
        'is_public': isPublic,
        // Start and end locations (from coordinates)
        if (coordinates.isNotEmpty) ...{
          'start_latitude': coordinates.first['lat'],
          'start_longitude': coordinates.first['lng'],
          'end_latitude': coordinates.last['lat'],
          'end_longitude': coordinates.last['lng'],
        }
      };

      final response = await _apiService.post('/fitness/routes/', routeData);
      
      if (response.success && response.data != null) {
        final route = route_model.Route.fromJson(response.data);
        _routeCache[route.id] = route;
        
        // Add to local list if it matches our current filter
        _routes.insert(0, route);
        notifyListeners();
        
        return route;
      } else {
        throw Exception(response.error ?? 'Failed to create route');
      }
    } catch (e) {
      debugPrint('Error creating route: $e');
      return null;
    }
  }

  /// Update route rating
  Future<bool> rateRoute(String routeId, int rating) async {
    if (rating < 1 || rating > 5) return false;
    
    try {
      final response = await _apiService.post(
        '/fitness/routes/$routeId/rate/',
        {'rating': rating},
      );
      
      if (response.success) {
        // Update cached route if available
        if (_routeCache.containsKey(routeId)) {
          final updatedRoute = await getRoute(routeId);
          if (updatedRoute != null) {
            _routeCache[routeId] = updatedRoute;
            notifyListeners();
          }
        }
        return true;
      }
      
      return false;
    } catch (e) {
      debugPrint('Error rating route: $e');
      return false;
    }
  }

  /// Get popular routes
  Future<List<route_model.Route>> getPopularRoutes({
    String? activityType,
    int limit = 10,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'ordering': '-times_used,-average_rating',
        'limit': limit,
      };
      
      if (activityType != null) queryParams['activity_type'] = activityType;

      final response = await _apiService.get(
        '/fitness/routes/',
        queryParams: queryParams,
      );
      
      if (response.success && response.data != null) {
        final routes = (response.data['results'] as List<dynamic>)
            .map((json) => route_model.Route.fromJson(json))
            .toList();
        
        // Update cache
        for (final route in routes) {
          _routeCache[route.id] = route;
        }
        
        return routes;
      } else {
        throw Exception(response.error ?? 'Failed to fetch popular routes');
      }
    } catch (e) {
      debugPrint('Error fetching popular routes: $e');
      return [];
    }
  }

  /// Get recently created routes
  Future<List<route_model.Route>> getRecentRoutes({
    String? activityType,
    int limit = 10,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'ordering': '-created_at',
        'limit': limit,
      };
      
      if (activityType != null) queryParams['activity_type'] = activityType;

      final response = await _apiService.get(
        '/fitness/routes/',
        queryParams: queryParams,
      );
      
      if (response.success && response.data != null) {
        final routes = (response.data['results'] as List<dynamic>)
            .map((json) => route_model.Route.fromJson(json))
            .toList();
        
        // Update cache
        for (final route in routes) {
          _routeCache[route.id] = route;
        }
        
        return routes;
      } else {
        throw Exception(response.error ?? 'Failed to fetch recent routes');
      }
    } catch (e) {
      debugPrint('Error fetching recent routes: $e');
      return [];
    }
  }

  /// Get user's created routes
  Future<List<route_model.Route>> getUserRoutes() async {
    try {
      final response = await _apiService.get('/fitness/routes/my-routes/');
      
      if (response.success && response.data != null) {
        final routes = (response.data['results'] as List<dynamic>)
            .map((json) => route_model.Route.fromJson(json))
            .toList();
        
        // Update cache
        for (final route in routes) {
          _routeCache[route.id] = route;
        }
        
        return routes;
      } else {
        throw Exception(response.error ?? 'Failed to fetch user routes');
      }
    } catch (e) {
      debugPrint('Error fetching user routes: $e');
      return [];
    }
  }

  /// Clear cache
  void clearCache() {
    _routes.clear();
    _routeCache.clear();
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    if (loading) _setError(null);
  }

  void _setError(String? error) {
    _error = error;
  }

  /// Build query string from parameters
  String _buildQueryString(Map<String, dynamic> params) {
    if (params.isEmpty) return '';
    
    final query = params.entries
        .where((entry) => entry.value != null)
        .map((entry) => '${Uri.encodeComponent(entry.key)}=${Uri.encodeComponent(entry.value.toString())}')
        .join('&');
    
    return query.isNotEmpty ? '?$query' : '';
  }
}