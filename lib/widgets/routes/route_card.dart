import 'package:flutter/material.dart';
import '../../models/fitness_route.dart';
import '../../theme/app_theme.dart';

class RouteCard extends StatelessWidget {
  final FitnessRoute route;

  const RouteCard({super.key, required this.route});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showRouteDetails(context),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 12),
                _buildDescription(),
                const SizedBox(height: 12),
                _buildStats(),
                const SizedBox(height: 12),
                _buildLocation(),
                if (route.createdByUserName != null) ...[
                  const SizedBox(height: 8),
                  _buildCreator(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getActivityIcon(),
            color: AppTheme.primaryColor,
            size: 24,
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
              Row(
                children: [
                  _buildDifficultyChip(),
                  const SizedBox(width: 8),
                  if (route.rating > 0) _buildRatingDisplay(),
                ],
              ),
            ],
          ),
        ),
        if (route.isFavorite)
          const Icon(
            Icons.favorite,
            color: Colors.red,
            size: 20,
          ),
      ],
    );
  }

  Widget _buildDescription() {
    return Text(
      route.description,
      style: TextStyle(
        fontSize: 14,
        color: Colors.grey.shade600,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildStats() {
    return Row(
      children: [
        _buildStatChip(
          icon: Icons.straighten,
          label: '${route.distanceKm.toStringAsFixed(1)} km',
          color: Colors.blue,
        ),
        const SizedBox(width: 8),
        _buildStatChip(
          icon: Icons.timer,
          label: route.estimatedDuration,
          color: Colors.green,
        ),
        const SizedBox(width: 8),
        if (route.elevationGain > 0)
          _buildStatChip(
            icon: Icons.trending_up,
            label: '${route.elevationGain}m',
            color: Colors.orange,
          ),
      ],
    );
  }

  Widget _buildLocation() {
    return Row(
      children: [
        Icon(
          Icons.location_on,
          size: 16,
          color: Colors.grey.shade600,
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            route.locationSummary,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildCreator() {
    return Row(
      children: [
        Icon(
          Icons.person,
          size: 16,
          color: Colors.grey.shade600,
        ),
        const SizedBox(width: 4),
        Text(
          'Created by ${route.createdByUserName}',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        const Spacer(),
        if (route.timesUsed > 0)
          Text(
            '${route.timesUsed} uses',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
      ],
    );
  }

  Widget _buildDifficultyChip() {
    Color color;
    switch (route.difficulty.toLowerCase()) {
      case 'easy':
        color = Colors.green;
        break;
      case 'moderate':
        color = Colors.orange;
        break;
      case 'hard':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        route.difficultyDisplay,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildRatingDisplay() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.star,
          size: 16,
          color: Colors.amber.shade600,
        ),
        const SizedBox(width: 2),
        Text(
          route.rating.toStringAsFixed(1),
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        if (route.ratingCount > 0)
          Text(
            ' (${route.ratingCount})',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade500,
            ),
          ),
      ],
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getActivityIcon() {
    switch (route.activityType.toLowerCase()) {
      case 'running':
      case 'jogging':
        return Icons.directions_run;
      case 'walking':
        return Icons.directions_walk;
      case 'cycling':
      case 'biking':
        return Icons.directions_bike;
      case 'hiking':
        return Icons.terrain;
      default:
        return Icons.route;
    }
  }

  void _showRouteDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    route.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    route.description,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildDetailedStats(),
                  const SizedBox(height: 20),
                  _buildDetailedLocation(),
                  if (route.createdByUserName != null) ...[
                    const SizedBox(height: 20),
                    _buildDetailedCreator(),
                  ],
                  const SizedBox(height: 30),
                  _buildActionButtons(context),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailedStats() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Route Statistics',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildDetailStat(
                    'Distance',
                    '${route.distanceKm.toStringAsFixed(1)} km',
                    Icons.straighten,
                  ),
                ),
                Expanded(
                  child: _buildDetailStat(
                    'Est. Duration',
                    route.estimatedDuration,
                    Icons.timer,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildDetailStat(
                    'Difficulty',
                    route.difficultyDisplay,
                    Icons.trending_up,
                  ),
                ),
                Expanded(
                  child: _buildDetailStat(
                    'Elevation',
                    '${route.elevationGain}m',
                    Icons.landscape,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.primaryColor),
        const SizedBox(height: 4),
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
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailedLocation() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Location',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    route.locationSummary,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedCreator() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
              child: Icon(
                Icons.person,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    route.createdByUserName!,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    'Route Creator',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            if (route.timesUsed > 0)
              Column(
                children: [
                  Text(
                    '${route.timesUsed}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Uses',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Start activity with this route
            },
            icon: const Icon(Icons.play_arrow),
            label: const Text('Start Activity'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 12),
        IconButton(
          onPressed: () {
            // TODO: Toggle favorite
          },
          icon: Icon(
            route.isFavorite ? Icons.favorite : Icons.favorite_border,
            color: route.isFavorite ? Colors.red : Colors.grey,
          ),
        ),
        IconButton(
          onPressed: () {
            // TODO: Share route
          },
          icon: const Icon(Icons.share, color: Colors.grey),
        ),
      ],
    );
  }
}