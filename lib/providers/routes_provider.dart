import 'package:flutter/material.dart';
import '../models/fitness_route.dart';
import '../services/api_service.dart';
import '../utils/logger.dart';

class RoutesProvider with ChangeNotifier {
  final ApiService _apiService;
  static const String _logTag = 'RoutesProvider';

  List<FitnessRoute> _routes = [];
  List<FitnessRoute> _nearbyRoutes = [];
  List<FitnessRoute> _popularRoutes = [];
  bool _isLoading = false;
  String? _error;

  RoutesProvider({required ApiService apiService}) : _apiService = apiService;

  List<FitnessRoute> get routes => _routes;
  List<FitnessRoute> get nearbyRoutes => _nearbyRoutes;
  List<FitnessRoute> get popularRoutes => _popularRoutes;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadRoutes() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final routeData = await _apiService.getRoutes();
      
      if (routeData.success && routeData.data != null) {
        _routes = (routeData.data as List)
            .map((json) => FitnessRoute.fromJson(json))
            .toList();
        AppLogger.info('Loaded ${_routes.length} routes successfully', _logTag);
      } else {
        AppLogger.warning('Failed to load routes from API, using empty list', _logTag);
        _routes = [];
      }
    } catch (e) {
      AppLogger.error('Error loading routes: $e', _logTag);
      _error = 'Failed to load routes';
      _routes = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadNearbyRoutes(double latitude, double longitude, {double? radius}) async {
    try {
      final nearbyData = await _apiService.getNearbyRoutes(
        latitude: latitude,
        longitude: longitude,
        radius: radius,
      );
      
      if (nearbyData.success && nearbyData.data != null) {
        _nearbyRoutes = (nearbyData.data as List)
            .map((json) => FitnessRoute.fromJson(json))
            .toList();
        AppLogger.info('Loaded ${_nearbyRoutes.length} nearby routes', _logTag);
        notifyListeners();
      }
    } catch (e) {
      AppLogger.error('Error loading nearby routes: $e', _logTag);
      _nearbyRoutes = [];
      notifyListeners();
    }
  }

  Future<void> loadPopularRoutes() async {
    try {
      final popularData = await _apiService.getPopularRoutes();
      
      if (popularData.success && popularData.data != null) {
        _popularRoutes = (popularData.data as List)
            .map((json) => FitnessRoute.fromJson(json))
            .toList();
        AppLogger.info('Loaded ${_popularRoutes.length} popular routes', _logTag);
        notifyListeners();
      }
    } catch (e) {
      AppLogger.error('Error loading popular routes: $e', _logTag);
      _popularRoutes = [];
      notifyListeners();
    }
  }

  Future<bool> createRoute(FitnessRoute route) async {
    try {
      final result = await _apiService.createRoute(route.toJson());
      
      if (result.success) {
        AppLogger.info('Route created successfully', _logTag);
        await loadRoutes(); // Refresh routes list
        return true;
      } else {
        AppLogger.warning('Failed to create route: ${result.error}', _logTag);
        _error = result.error ?? 'Failed to create route';
        notifyListeners();
        return false;
      }
    } catch (e) {
      AppLogger.error('Error creating route: $e', _logTag);
      _error = 'Failed to create route';
      notifyListeners();
      return false;
    }
  }

  List<FitnessRoute> getRoutesByActivityType(String activityType) {
    return _routes.where((route) => 
        route.activityType.toLowerCase() == activityType.toLowerCase()).toList();
  }

  List<FitnessRoute> getRoutesByDifficulty(String difficulty) {
    return _routes.where((route) => 
        route.difficulty.toLowerCase() == difficulty.toLowerCase()).toList();
  }

  List<FitnessRoute> getFavoriteRoutes() {
    return _routes.where((route) => route.isFavorite).toList();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}