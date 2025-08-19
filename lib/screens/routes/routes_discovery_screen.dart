import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:location/location.dart';
import '../../providers/routes_provider.dart';
import '../../models/fitness_route.dart';
import '../../widgets/routes/route_card.dart';
import '../../theme/app_theme.dart';
import '../../utils/logger.dart';

class RoutesDiscoveryScreen extends StatefulWidget {
  const RoutesDiscoveryScreen({super.key});

  @override
  State<RoutesDiscoveryScreen> createState() => _RoutesDiscoveryScreenState();
}

class _RoutesDiscoveryScreenState extends State<RoutesDiscoveryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Location _location = Location();
  LocationData? _currentLocation;
  String _selectedActivityType = 'All';
  String _selectedDifficulty = 'All';

  final List<String> _activityTypes = [
    'All',
    'Running',
    'Cycling',
    'Walking',
    'Hiking'
  ];

  final List<String> _difficulties = ['All', 'Easy', 'Moderate', 'Hard'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeScreen();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initializeScreen() async {
    final routesProvider = Provider.of<RoutesProvider>(context, listen: false);
    
    await _getCurrentLocation();
    await routesProvider.loadRoutes();
    await routesProvider.loadPopularRoutes();
    
    if (_currentLocation != null) {
      await routesProvider.loadNearbyRoutes(
        _currentLocation!.latitude!,
        _currentLocation!.longitude!,
      );
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await _location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await _location.requestService();
        if (!serviceEnabled) {
          AppLogger.warning('Location service not enabled', 'RoutesDiscovery');
          return;
        }
      }

      PermissionStatus permissionGranted = await _location.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await _location.requestPermission();
        if (permissionGranted != PermissionStatus.granted) {
          AppLogger.warning('Location permission denied', 'RoutesDiscovery');
          return;
        }
      }

      _currentLocation = await _location.getLocation();
      AppLogger.info('Current location obtained', 'RoutesDiscovery');
    } catch (e) {
      AppLogger.error('Error getting location: $e', 'RoutesDiscovery');
    }
  }

  List<FitnessRoute> _filterRoutes(List<FitnessRoute> routes) {
    return routes.where((route) {
      final matchesActivity = _selectedActivityType == 'All' ||
          route.activityType.toLowerCase() == _selectedActivityType.toLowerCase();
      final matchesDifficulty = _selectedDifficulty == 'All' ||
          route.difficulty.toLowerCase() == _selectedDifficulty.toLowerCase();
      return matchesActivity && matchesDifficulty;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover Routes'),
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppTheme.primaryColor,
          tabs: const [
            Tab(text: 'All Routes'),
            Tab(text: 'Nearby'),
            Tab(text: 'Popular'),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAllRoutesTab(),
                _buildNearbyRoutesTab(),
                _buildPopularRoutesTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateRouteDialog(),
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildFilterDropdown(
              label: 'Activity',
              value: _selectedActivityType,
              items: _activityTypes,
              onChanged: (value) => setState(() => _selectedActivityType = value!),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildFilterDropdown(
              label: 'Difficulty',
              value: _selectedDifficulty,
              items: _difficulties,
              onChanged: (value) => setState(() => _selectedDifficulty = value!),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: items.map((item) {
        return DropdownMenuItem(
          value: item,
          child: Text(item),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildAllRoutesTab() {
    return Consumer<RoutesProvider>(
      builder: (context, routesProvider, child) {
        if (routesProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (routesProvider.error != null) {
          return _buildErrorState(routesProvider.error!);
        }

        final filteredRoutes = _filterRoutes(routesProvider.routes);

        if (filteredRoutes.isEmpty) {
          return _buildEmptyState('No routes found matching your criteria');
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filteredRoutes.length,
          itemBuilder: (context, index) {
            return RouteCard(route: filteredRoutes[index]);
          },
        );
      },
    );
  }

  Widget _buildNearbyRoutesTab() {
    return Consumer<RoutesProvider>(
      builder: (context, routesProvider, child) {
        if (_currentLocation == null) {
          return _buildLocationRequiredState();
        }

        final filteredRoutes = _filterRoutes(routesProvider.nearbyRoutes);

        if (filteredRoutes.isEmpty) {
          return _buildEmptyState('No nearby routes found');
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filteredRoutes.length,
          itemBuilder: (context, index) {
            return RouteCard(route: filteredRoutes[index]);
          },
        );
      },
    );
  }

  Widget _buildPopularRoutesTab() {
    return Consumer<RoutesProvider>(
      builder: (context, routesProvider, child) {
        final filteredRoutes = _filterRoutes(routesProvider.popularRoutes);

        if (filteredRoutes.isEmpty) {
          return _buildEmptyState('No popular routes found');
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filteredRoutes.length,
          itemBuilder: (context, index) {
            return RouteCard(route: filteredRoutes[index]);
          },
        );
      },
    );
  }

  Widget _buildEmptyState(String message) {
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
            message,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            error,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _initializeScreen,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationRequiredState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.location_off,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Location access required\nto find nearby routes',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _getCurrentLocation,
            child: const Text('Enable Location'),
          ),
        ],
      ),
    );
  }

  void _showCreateRouteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Route'),
        content: const Text('Route creation feature coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}