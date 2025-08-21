import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/route_tracking_service.dart';

class RouteGuidanceWidget extends StatelessWidget {
  const RouteGuidanceWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<RouteTrackingService>(
      builder: (context, trackingService, child) {
        if (trackingService.currentRoute == null) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: trackingService.isOffRoute ? Colors.red.shade50 : Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: trackingService.isOffRoute ? Colors.red : Colors.blue,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status indicator
              Row(
                children: [
                  Icon(
                    trackingService.isOffRoute ? Icons.warning : Icons.navigation,
                    color: trackingService.isOffRoute ? Colors.red : Colors.blue,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      trackingService.isOffRoute ? 'OFF ROUTE' : 'ON ROUTE',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: trackingService.isOffRoute ? Colors.red : Colors.blue,
                      ),
                    ),
                  ),
                  // Route completion badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${(trackingService.routeCompletion * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Guidance text
              Text(
                trackingService.getTurnGuidance(),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Metrics row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildMetric(
                    'Distance from route',
                    '${trackingService.distanceFromRoute.toStringAsFixed(0)}m',
                    trackingService.isOffRoute ? Colors.red : Colors.grey,
                  ),
                  _buildMetric(
                    'To waypoint',
                    '${trackingService.distanceToNextWaypoint.toStringAsFixed(0)}m',
                    Colors.blue,
                  ),
                  _buildMetric(
                    'Segment',
                    '${trackingService.currentRouteSegment + 1}',
                    Colors.orange,
                  ),
                ],
              ),
              
              // Progress bar
              if (trackingService.routeCompletion > 0) ...[
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: trackingService.routeCompletion,
                  backgroundColor: Colors.grey.shade300,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    trackingService.isOffRoute ? Colors.red : Colors.blue,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildMetric(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}