import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/route.dart' as route_model;
import 'route_service.dart';
import 'api_service.dart';

class OfflineRouteService extends ChangeNotifier {
  static final OfflineRouteService _instance = OfflineRouteService._internal();
  factory OfflineRouteService() => _instance;
  OfflineRouteService._internal();

  final RouteService _routeService = RouteService();
  final ApiService _apiService = ApiService();

  // Cache management
  final Map<String, CachedRoute> _cachedRoutes = {};
  final Map<String, OfflineMapTile> _cachedTiles = {};
  
  // Cache settings
  static const int maxCachedRoutes = 50;
  static const int maxCachedTiles = 1000;
  static const Duration cacheExpiry = Duration(days: 7);
  
  // Storage paths
  String? _cacheDirectory;
  bool _isInitialized = false;

  // Getters
  List<CachedRoute> get cachedRoutes => _cachedRoutes.values.toList();
  bool get isInitialized => _isInitialized;
  int get cachedRoutesCount => _cachedRoutes.length;
  int get cachedTilesCount => _cachedTiles.length;

  /// Initialize offline service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final documentsDir = await getApplicationDocumentsDirectory();
      _cacheDirectory = '${documentsDir.path}/route_cache';
      
      // Create cache directory
      final cacheDir = Directory(_cacheDirectory!);
      if (!await cacheDir.exists()) {
        await cacheDir.create(recursive: true);
      }
      
      // Load existing cache
      await _loadCacheIndex();
      
      // Clean expired cache
      await _cleanExpiredCache();
      
      _isInitialized = true;
      notifyListeners();
      
      debugPrint('Offline route service initialized with ${_cachedRoutes.length} cached routes');
      
    } catch (e) {
      debugPrint('Error initializing offline route service: $e');
    }
  }

  /// Cache a route for offline use
  Future<bool> cacheRoute(route_model.Route route) async {
    if (!_isInitialized) await initialize();
    
    try {
      // Check if already cached
      if (_cachedRoutes.containsKey(route.id)) {
        // Update access time
        _cachedRoutes[route.id]!.lastAccessed = DateTime.now();
        await _saveCacheIndex();
        return true;
      }
      
      // Create cached route
      final cachedRoute = CachedRoute(
        route: route,
        cachedAt: DateTime.now(),
        lastAccessed: DateTime.now(),
        offlineMapTiles: [],
        estimatedSize: _estimateRouteSize(route),
      );
      
      // Cache route data
      final routeFile = File('${_cacheDirectory!}/route_${route.id}.json');
      await routeFile.writeAsString(jsonEncode(route.toJson()));
      
      // Cache map tiles for the route
      if (route.coordinates != null) {
        await _cacheMapTilesForRoute(route, cachedRoute);
      }
      
      // Add to cache
      _cachedRoutes[route.id] = cachedRoute;
      
      // Manage cache size
      await _manageCacheSize();
      
      // Save cache index
      await _saveCacheIndex();
      
      notifyListeners();
      return true;
      
    } catch (e) {
      debugPrint('Error caching route ${route.id}: $e');
      return false;
    }
  }

  /// Get cached route
  Future<route_model.Route?> getCachedRoute(String routeId) async {
    if (!_isInitialized) await initialize();
    
    final cachedRoute = _cachedRoutes[routeId];
    if (cachedRoute == null) return null;
    
    try {
      // Update access time
      cachedRoute.lastAccessed = DateTime.now();
      await _saveCacheIndex();
      
      // Load route from cache
      final routeFile = File('${_cacheDirectory!}/route_$routeId.json');
      if (!await routeFile.exists()) {
        // Cache entry exists but file doesn't - clean up
        _cachedRoutes.remove(routeId);
        await _saveCacheIndex();
        return null;
      }
      
      final routeJson = jsonDecode(await routeFile.readAsString());
      return route_model.Route.fromJson(routeJson);
      
    } catch (e) {
      debugPrint('Error loading cached route $routeId: $e');
      return null;
    }
  }

  /// Check if route is cached
  bool isRouteCached(String routeId) {
    return _cachedRoutes.containsKey(routeId);
  }

  /// Remove route from cache
  Future<bool> removeFromCache(String routeId) async {
    if (!_isInitialized) return false;
    
    try {
      final cachedRoute = _cachedRoutes[routeId];
      if (cachedRoute == null) return false;
      
      // Remove route file
      final routeFile = File('${_cacheDirectory!}/route_$routeId.json');
      if (await routeFile.exists()) {
        await routeFile.delete();
      }
      
      // Remove map tiles
      for (final tileId in cachedRoute.offlineMapTiles) {
        await _removeMapTile(tileId);
      }
      
      // Remove from cache
      _cachedRoutes.remove(routeId);
      
      // Save cache index
      await _saveCacheIndex();
      
      notifyListeners();
      return true;
      
    } catch (e) {
      debugPrint('Error removing route $routeId from cache: $e');
      return false;
    }
  }

  /// Cache map tiles for a route
  Future<void> _cacheMapTilesForRoute(route_model.Route route, CachedRoute cachedRoute) async {
    if (route.coordinates == null || route.coordinates!.isEmpty) return;
    
    final bounds = _calculateRouteBounds(route.coordinates!);
    final zoomLevels = [12, 13, 14, 15]; // Cache multiple zoom levels
    
    for (final zoom in zoomLevels) {
      final tiles = _getTilesInBounds(bounds, zoom);
      
      for (final tile in tiles) {
        final tileId = '${tile.x}_${tile.y}_$zoom';
        
        // Skip if already cached
        if (_cachedTiles.containsKey(tileId)) {
          cachedRoute.offlineMapTiles.add(tileId);
          continue;
        }
        
        try {
          // Download tile (this would typically use Google Maps Static API or similar)
          final tileData = await _downloadMapTile(tile.x, tile.y, zoom);
          
          if (tileData != null) {
            // Save tile to disk
            final tileFile = File('${_cacheDirectory!}/tile_$tileId.png');
            await tileFile.writeAsBytes(tileData);
            
            // Add to cache
            _cachedTiles[tileId] = OfflineMapTile(
              x: tile.x,
              y: tile.y,
              zoom: zoom,
              filePath: tileFile.path,
              cachedAt: DateTime.now(),
              size: tileData.length,
            );
            
            cachedRoute.offlineMapTiles.add(tileId);
          }
        } catch (e) {
          debugPrint('Error caching tile $tileId: $e');
        }
        
        // Respect rate limits
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }
  }

  /// Download map tile (placeholder implementation)
  Future<List<int>?> _downloadMapTile(int x, int y, int zoom) async {
    try {
      // This is a placeholder - in a real app you'd use Google Maps Static API
      // or another tile service with proper authentication
      final url = 'https://tile.openstreetmap.org/$zoom/$x/$y.png';
      
      final response = await _apiService.get(url);
      if (response.success) {
        // Return mock data for now
        return List<int>.generate(1024, (i) => i % 256);
      }
      
      return null;
    } catch (e) {
      debugPrint('Error downloading tile: $e');
      return null;
    }
  }

  /// Calculate route bounds
  RouteBounds _calculateRouteBounds(List<LatLng> coordinates) {
    double minLat = coordinates.first.latitude;
    double maxLat = coordinates.first.latitude;
    double minLng = coordinates.first.longitude;
    double maxLng = coordinates.first.longitude;
    
    for (final point in coordinates) {
      minLat = math.min(minLat, point.latitude);
      maxLat = math.max(maxLat, point.latitude);
      minLng = math.min(minLng, point.longitude);
      maxLng = math.max(maxLng, point.longitude);
    }
    
    // Add padding
    const padding = 0.01; // ~1km
    return RouteBounds(
      minLatitude: minLat - padding,
      maxLatitude: maxLat + padding,
      minLongitude: minLng - padding,
      maxLongitude: maxLng + padding,
    );
  }

  /// Get tiles within bounds
  List<MapTileCoordinate> _getTilesInBounds(RouteBounds bounds, int zoom) {
    final tiles = <MapTileCoordinate>[];
    
    final minTileX = _lonToTileX(bounds.minLongitude, zoom);
    final maxTileX = _lonToTileX(bounds.maxLongitude, zoom);
    final minTileY = _latToTileY(bounds.maxLatitude, zoom);
    final maxTileY = _latToTileY(bounds.minLatitude, zoom);
    
    for (int x = minTileX; x <= maxTileX; x++) {
      for (int y = minTileY; y <= maxTileY; y++) {
        tiles.add(MapTileCoordinate(x: x, y: y));
      }
    }
    
    return tiles;
  }

  /// Convert longitude to tile X coordinate
  int _lonToTileX(double lon, int zoom) {
    return ((lon + 180.0) / 360.0 * (1 << zoom)).floor();
  }

  /// Convert latitude to tile Y coordinate
  int _latToTileY(double lat, int zoom) {
    final latRad = lat * math.pi / 180.0;
    return ((1.0 - math.log(math.tan(latRad) + 1.0 / math.cos(latRad)) / math.pi) / 2.0 * (1 << zoom)).floor();
  }

  /// Estimate route cache size
  int _estimateRouteSize(route_model.Route route) {
    // Rough estimation in bytes
    int size = 10240; // Base route data ~10KB
    
    if (route.coordinates != null) {
      size += route.coordinates!.length * 50; // ~50 bytes per coordinate
    }
    
    // Estimate map tiles (assuming 20KB per tile, ~100 tiles per route)
    size += 100 * 20480;
    
    return size;
  }

  /// Manage cache size
  Future<void> _manageCacheSize() async {
    if (_cachedRoutes.length <= maxCachedRoutes) return;
    
    // Sort by last accessed time
    final sortedRoutes = _cachedRoutes.values.toList()
      ..sort((a, b) => a.lastAccessed.compareTo(b.lastAccessed));
    
    // Remove oldest routes
    final routesToRemove = sortedRoutes.take(_cachedRoutes.length - maxCachedRoutes);
    
    for (final route in routesToRemove) {
      await removeFromCache(route.route.id);
    }
  }

  /// Clean expired cache
  Future<void> _cleanExpiredCache() async {
    final now = DateTime.now();
    final expiredRoutes = <String>[];
    
    for (final entry in _cachedRoutes.entries) {
      if (now.difference(entry.value.cachedAt) > cacheExpiry) {
        expiredRoutes.add(entry.key);
      }
    }
    
    for (final routeId in expiredRoutes) {
      await removeFromCache(routeId);
    }
  }

  /// Remove map tile
  Future<void> _removeMapTile(String tileId) async {
    final tile = _cachedTiles[tileId];
    if (tile == null) return;
    
    try {
      final tileFile = File(tile.filePath);
      if (await tileFile.exists()) {
        await tileFile.delete();
      }
      
      _cachedTiles.remove(tileId);
    } catch (e) {
      debugPrint('Error removing tile $tileId: $e');
    }
  }

  /// Load cache index
  Future<void> _loadCacheIndex() async {
    try {
      final indexFile = File('${_cacheDirectory!}/cache_index.json');
      if (!await indexFile.exists()) return;
      
      final indexData = jsonDecode(await indexFile.readAsString());
      
      // Load cached routes
      if (indexData['routes'] != null) {
        for (final routeData in indexData['routes']) {
          final cachedRoute = CachedRoute.fromJson(routeData);
          _cachedRoutes[cachedRoute.route.id] = cachedRoute;
        }
      }
      
      // Load cached tiles
      if (indexData['tiles'] != null) {
        for (final tileData in indexData['tiles']) {
          final tile = OfflineMapTile.fromJson(tileData);
          final tileId = '${tile.x}_${tile.y}_${tile.zoom}';
          _cachedTiles[tileId] = tile;
        }
      }
      
    } catch (e) {
      debugPrint('Error loading cache index: $e');
    }
  }

  /// Save cache index
  Future<void> _saveCacheIndex() async {
    try {
      final indexFile = File('${_cacheDirectory!}/cache_index.json');
      
      final indexData = {
        'routes': _cachedRoutes.values.map((r) => r.toJson()).toList(),
        'tiles': _cachedTiles.values.map((t) => t.toJson()).toList(),
        'last_updated': DateTime.now().toIso8601String(),
      };
      
      await indexFile.writeAsString(jsonEncode(indexData));
      
    } catch (e) {
      debugPrint('Error saving cache index: $e');
    }
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheStatistics() {
    int totalSize = 0;
    for (final route in _cachedRoutes.values) {
      totalSize += route.estimatedSize;
    }
    
    return {
      'cached_routes': _cachedRoutes.length,
      'cached_tiles': _cachedTiles.length,
      'total_size_mb': (totalSize / 1024 / 1024).toStringAsFixed(2),
      'cache_directory': _cacheDirectory,
    };
  }

  /// Clear all cache
  Future<void> clearCache() async {
    if (!_isInitialized) return;
    
    try {
      // Remove all files
      final cacheDir = Directory(_cacheDirectory!);
      if (await cacheDir.exists()) {
        await cacheDir.delete(recursive: true);
        await cacheDir.create();
      }
      
      // Clear memory cache
      _cachedRoutes.clear();
      _cachedTiles.clear();
      
      notifyListeners();
      
    } catch (e) {
      debugPrint('Error clearing cache: $e');
    }
  }
}

class CachedRoute {
  final route_model.Route route;
  final DateTime cachedAt;
  DateTime lastAccessed;
  final List<String> offlineMapTiles;
  final int estimatedSize;

  CachedRoute({
    required this.route,
    required this.cachedAt,
    required this.lastAccessed,
    required this.offlineMapTiles,
    required this.estimatedSize,
  });

  factory CachedRoute.fromJson(Map<String, dynamic> json) {
    return CachedRoute(
      route: route_model.Route.fromJson(json['route']),
      cachedAt: DateTime.parse(json['cached_at']),
      lastAccessed: DateTime.parse(json['last_accessed']),
      offlineMapTiles: List<String>.from(json['offline_map_tiles'] ?? []),
      estimatedSize: json['estimated_size'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'route': route.toJson(),
      'cached_at': cachedAt.toIso8601String(),
      'last_accessed': lastAccessed.toIso8601String(),
      'offline_map_tiles': offlineMapTiles,
      'estimated_size': estimatedSize,
    };
  }
}

class OfflineMapTile {
  final int x;
  final int y;
  final int zoom;
  final String filePath;
  final DateTime cachedAt;
  final int size;

  const OfflineMapTile({
    required this.x,
    required this.y,
    required this.zoom,
    required this.filePath,
    required this.cachedAt,
    required this.size,
  });

  factory OfflineMapTile.fromJson(Map<String, dynamic> json) {
    return OfflineMapTile(
      x: json['x'] ?? 0,
      y: json['y'] ?? 0,
      zoom: json['zoom'] ?? 0,
      filePath: json['file_path'] ?? '',
      cachedAt: DateTime.parse(json['cached_at']),
      size: json['size'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'x': x,
      'y': y,
      'zoom': zoom,
      'file_path': filePath,
      'cached_at': cachedAt.toIso8601String(),
      'size': size,
    };
  }
}

class RouteBounds {
  final double minLatitude;
  final double maxLatitude;
  final double minLongitude;
  final double maxLongitude;

  const RouteBounds({
    required this.minLatitude,
    required this.maxLatitude,
    required this.minLongitude,
    required this.maxLongitude,
  });
}

class MapTileCoordinate {
  final int x;
  final int y;

  const MapTileCoordinate({
    required this.x,
    required this.y,
  });
}