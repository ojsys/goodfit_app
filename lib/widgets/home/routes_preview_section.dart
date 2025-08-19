import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/routes_provider.dart';
import '../../theme/app_theme.dart';

class RoutesPreviewSection extends StatelessWidget {
  const RoutesPreviewSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<RoutesProvider>(
      builder: (context, routesProvider, child) {
        final popularRoutes = routesProvider.popularRoutes.take(3).toList();
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Popular Routes',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    // Navigate to routes screen
                  },
                  child: const Text('Explore'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            if (popularRoutes.isEmpty)
              _buildEmptyState()
            else
              SizedBox(
                height: 160,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: popularRoutes.length,
                  itemBuilder: (context, index) {
                    return _buildRouteCard(popularRoutes[index]);
                  },
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildRouteCard(route) {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getActivityColor(route.activityType).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getActivityIcon(route.activityType),
                  color: _getActivityColor(route.activityType),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      route.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      route.activityType,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              if (route.rating > 0) ...[
                Icon(
                  Icons.star,
                  size: 16,
                  color: Colors.amber.shade600,
                ),
                Text(
                  route.rating.toStringAsFixed(1),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          
          Text(
            route.description,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          
          const SizedBox(height: 12),
          
          // Route Stats
          Row(
            children: [
              _buildRouteStat(
                Icons.straighten,
                '${route.distanceKm.toStringAsFixed(1)} km',
                Colors.blue,
              ),
              const SizedBox(width: 16),
              _buildRouteStat(
                Icons.timer,
                route.estimatedDuration,
                Colors.green,
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getDifficultyColor(route.difficulty).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  route.difficultyDisplay,
                  style: TextStyle(
                    fontSize: 12,
                    color: _getDifficultyColor(route.difficulty),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRouteStat(IconData icon, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(
            Icons.route,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 12),
          Text(
            'No routes available',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Explore and discover new routes!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              // Navigate to routes
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            ),
            child: const Text('Discover Routes'),
          ),
        ],
      ),
    );
  }

  IconData _getActivityIcon(String activityType) {
    switch (activityType.toLowerCase()) {
      case 'running':
        return Icons.directions_run;
      case 'cycling':
        return Icons.directions_bike;
      case 'walking':
        return Icons.directions_walk;
      case 'hiking':
        return Icons.terrain;
      default:
        return Icons.route;
    }
  }

  Color _getActivityColor(String activityType) {
    switch (activityType.toLowerCase()) {
      case 'running':
        return Colors.red;
      case 'cycling':
        return Colors.blue;
      case 'walking':
        return Colors.green;
      case 'hiking':
        return Colors.brown;
      default:
        return AppTheme.primaryColor;
    }
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return Colors.green;
      case 'moderate':
        return Colors.orange;
      case 'hard':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}