import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../models/route.dart' as route_model;
import '../services/route_service.dart';
import '../widgets/route_card.dart';
import '../widgets/route_filter_sheet.dart';
import 'route_details_screen.dart';

class RouteDiscoveryScreen extends StatefulWidget {
  const RouteDiscoveryScreen({super.key});

  @override
  State<RouteDiscoveryScreen> createState() => _RouteDiscoveryScreenState();
}

class _RouteDiscoveryScreenState extends State<RouteDiscoveryScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  late RouteService _routeService;
  
  final TextEditingController _searchController = TextEditingController();
  RouteFilters _currentFilters = const RouteFilters();
  
  List<route_model.Route> _allRoutes = [];
  List<route_model.Route> _popularRoutes = [];
  List<route_model.Route> _nearbyRoutes = [];
  List<route_model.Route> _recentRoutes = [];
  List<route_model.Route> _searchResults = [];
  
  bool _isLoading = false;
  bool _isSearching = false;
  Position? _userLocation;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _routeService = RouteService();
    _getCurrentLocation();
    _loadInitialData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover Routes'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(120),
          child: Column(
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search routes by name or location...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: _clearSearch,
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                        ),
                        onSubmitted: _performSearch,
                        onChanged: (value) {
                          setState(() {});
                          if (value.isEmpty) {
                            _clearSearch();
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Filter Button
                    Container(
                      decoration: BoxDecoration(
                        color: _currentFilters.hasActiveFilters 
                            ? Colors.blue 
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.tune,
                          color: _currentFilters.hasActiveFilters 
                              ? Colors.white 
                              : Colors.grey.shade600,
                        ),
                        onPressed: _showFilterSheet,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Tab Bar
              if (!_isSearching)
                TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  labelColor: Colors.blue,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: Colors.blue,
                  tabs: const [
                    Tab(text: 'All Routes'),
                    Tab(text: 'Popular'),
                    Tab(text: 'Nearby'),
                    Tab(text: 'Recent'),
                  ],
                ),
            ],
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isSearching) {
      return _buildSearchResults();
    }

    return TabBarView(
      controller: _tabController,
      children: [
        _buildRouteList(_allRoutes, 'No routes found'),
        _buildRouteList(_popularRoutes, 'No popular routes yet'),
        _buildRouteList(_nearbyRoutes, 'No nearby routes found'),
        _buildRouteList(_recentRoutes, 'No recent routes found'),
      ],
    );
  }

  Widget _buildRouteList(List<route_model.Route> routes, String emptyMessage) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (routes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.route,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _refreshCurrentTab,
              child: const Text('Refresh'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshCurrentTab,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 100),
        itemCount: routes.length,
        itemBuilder: (context, index) {
          final route = routes[index];
          return RouteCard(
            route: route,
            onTap: () => _navigateToRouteDetails(route),
            showFavoriteButton: true,
            onFavorite: () => _toggleFavorite(route),
          );
        },
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Searching routes...'),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty && _searchController.text.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No routes found for "${_searchController.text}"',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _clearSearch,
              child: const Text('Clear Search'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 100),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final route = _searchResults[index];
        return RouteCard(
          route: route,
          onTap: () => _navigateToRouteDetails(route),
          showFavoriteButton: true,
          onFavorite: () => _toggleFavorite(route),
        );
      },
    );
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load all tabs in parallel
      final results = await Future.wait([
        _routeService.fetchRoutes(),
        _routeService.getPopularRoutes(limit: 20),
        _userLocation != null 
            ? _routeService.getRoutesNearLocation(
                latitude: _userLocation!.latitude,
                longitude: _userLocation!.longitude,
                radiusKm: 25,
              )
            : Future.value(<route_model.Route>[]),
        _routeService.getRecentRoutes(limit: 20),
      ]);

      if (mounted) {
        setState(() {
          _allRoutes = results[0];
          _popularRoutes = results[1];
          _nearbyRoutes = results[2];
          _recentRoutes = results[3];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar('Failed to load routes: $e');
      }
    }
  }

  Future<void> _refreshCurrentTab() async {
    final currentIndex = _tabController.index;
    
    setState(() {
      _isLoading = true;
    });

    try {
      switch (currentIndex) {
        case 0:
          _allRoutes = await _routeService.fetchRoutes();
          break;
        case 1:
          _popularRoutes = await _routeService.getPopularRoutes(limit: 20);
          break;
        case 2:
          if (_userLocation != null) {
            _nearbyRoutes = await _routeService.getRoutesNearLocation(
              latitude: _userLocation!.latitude,
              longitude: _userLocation!.longitude,
              radiusKm: 25,
            );
          }
          break;
        case 3:
          _recentRoutes = await _routeService.getRecentRoutes(limit: 20);
          break;
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar('Failed to refresh: $e');
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _userLocation = position;
      });
    } catch (e) {
      debugPrint('Failed to get location: $e');
    }
  }

  void _performSearch(String query) async {
    if (query.trim().isEmpty) {
      _clearSearch();
      return;
    }

    setState(() {
      _isSearching = true;
      _isLoading = true;
    });

    try {
      final results = await _routeService.searchRoutes(query.trim());
      
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar('Search failed: $e');
      }
    }
  }

  void _clearSearch() {
    setState(() {
      _searchController.clear();
      _isSearching = false;
      _searchResults.clear();
    });
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RouteFilterSheet(
        initialFilters: _currentFilters,
        onApplyFilters: _applyFilters,
      ),
    );
  }

  void _applyFilters(RouteFilters filters) async {
    setState(() {
      _currentFilters = filters;
      _isLoading = true;
    });

    try {
      // Apply filters to current routes
      final filteredRoutes = await _routeService.fetchRoutes(
        activityType: filters.activityType,
        maxDistance: filters.maxDistance * 1000, // Convert to meters
        difficulty: filters.difficulty,
      );

      if (mounted) {
        setState(() {
          _allRoutes = filteredRoutes;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar('Failed to apply filters: $e');
      }
    }
  }

  void _navigateToRouteDetails(route_model.Route route) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RouteDetailsScreen(route: route),
      ),
    );
  }

  void _toggleFavorite(route_model.Route route) {
    // TODO: Implement favorite functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Favorite feature coming soon for ${route.name}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}