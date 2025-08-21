import 'package:flutter/material.dart';
import '../models/route.dart' as route_model;

class RouteCard extends StatelessWidget {
  final route_model.Route route;
  final VoidCallback? onTap;
  final VoidCallback? onFavorite;
  final bool showFavoriteButton;
  final bool isFavorite;
  final bool compact;

  const RouteCard({
    super.key,
    required this.route,
    this.onTap,
    this.onFavorite,
    this.showFavoriteButton = false,
    this.isFavorite = false,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row with title and favorite button
              Row(
                children: [
                  Expanded(
                    child: Text(
                      route.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: compact ? 1 : 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (showFavoriteButton)
                    IconButton(
                      onPressed: onFavorite,
                      icon: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: isFavorite ? Colors.red : Colors.grey,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                      padding: EdgeInsets.zero,
                    ),
                  _buildDifficultyBadge(),
                ],
              ),
              
              // Description (only if not compact and has description)
              if (!compact && route.description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  route.description,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              
              const SizedBox(height: 12),
              
              // Main metrics row
              Row(
                children: [
                  _buildMetricChip(
                    icon: Icons.straighten,
                    label: route.formattedDistance,
                    color: Colors.blue,
                  ),
                  const SizedBox(width: 8),
                  _buildMetricChip(
                    icon: Icons.terrain,
                    label: route.formattedElevationGain,
                    color: Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  _buildMetricChip(
                    icon: Icons.access_time,
                    label: route.formattedEstimatedDuration,
                    color: Colors.green,
                  ),
                ],
              ),
              
              // Additional info row (only if not compact)
              if (!compact) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    // Surface type
                    if (route.surfaceType.isNotEmpty)
                      _buildInfoChip(
                        icon: _getSurfaceIcon(route.surfaceType),
                        label: _formatSurfaceType(route.surfaceType),
                      ),
                    
                    const SizedBox(width: 8),
                    
                    // Activity types
                    if (route.activityTypes.isNotEmpty)
                      _buildInfoChip(
                        icon: Icons.directions_run,
                        label: route.activityTypes.take(2).join(', '),
                      ),
                    
                    const Spacer(),
                    
                    // Rating and usage stats
                    if (route.averageRating > 0) ...[
                      Icon(Icons.star, size: 16, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(
                        route.averageRating.toStringAsFixed(1),
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '(${route.totalRatings})',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                ),
                
                const SizedBox(height: 8),
                
                // Safety and scenic ratings
                Row(
                  children: [
                    _buildRatingBar('Safety', route.safetyRating, Colors.blue),
                    const SizedBox(width: 16),
                    _buildRatingBar('Scenic', route.scenicRating, Colors.green),
                    
                    const Spacer(),
                    
                    // Times used
                    if (route.timesUsed > 0) ...[
                      Icon(Icons.people, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        '${route.timesUsed} uses',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDifficultyBadge() {
    final color = _getDifficultyColor(route.difficultyLevel);
    final text = _getDifficultyText(route.difficultyLevel);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildMetricChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
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

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.grey.shade600),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingBar(String label, int rating, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
        const SizedBox(width: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(5, (index) {
            return Icon(
              index < rating ? Icons.circle : Icons.circle_outlined,
              size: 8,
              color: index < rating ? color : Colors.grey.shade300,
            );
          }),
        ),
      ],
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

  IconData _getSurfaceIcon(String surfaceType) {
    switch (surfaceType.toLowerCase()) {
      case 'road': return Icons.local_shipping;
      case 'trail': return Icons.hiking;
      case 'track': return Icons.track_changes;
      case 'gravel': return Icons.terrain;
      default: return Icons.landscape;
    }
  }

  String _formatSurfaceType(String surfaceType) {
    return surfaceType.split('_').map((word) => 
        word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1)
    ).join(' ');
  }
}