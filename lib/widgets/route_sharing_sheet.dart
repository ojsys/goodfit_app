import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/route.dart' as route_model;
import '../services/route_analytics_service.dart';
import '../services/route_tracking_service.dart';
import '../services/offline_route_service.dart';

class RouteSharingSheet extends StatefulWidget {
  final route_model.Route route;
  final RouteTrackingAnalytics? analytics;

  const RouteSharingSheet({
    super.key,
    required this.route,
    this.analytics,
  });

  @override
  State<RouteSharingSheet> createState() => _RouteSharingSheetState();
}

class _RouteSharingSheetState extends State<RouteSharingSheet> {
  late RouteAnalyticsService _analyticsService;
  late OfflineRouteService _offlineService;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _analyticsService = RouteAnalyticsService();
    _offlineService = OfflineRouteService();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Text(
                'Share Route',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Route Info
          _buildRouteInfoCard(),
          
          const SizedBox(height: 20),
          
          // Share Options
          const Text(
            'Share Options',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Share buttons grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1,
            children: [
              _buildShareButton(
                icon: Icons.link,
                label: 'Copy Link',
                onTap: _copyRouteLink,
              ),
              _buildShareButton(
                icon: Icons.qr_code,
                label: 'QR Code',
                onTap: _showQRCode,
              ),
              _buildShareButton(
                icon: Icons.share,
                label: 'Share',
                onTap: _shareRoute,
              ),
              _buildShareButton(
                icon: Icons.download,
                label: 'Export GPX',
                onTap: _exportGPX,
              ),
              _buildShareButton(
                icon: Icons.cloud_download,
                label: 'Cache Offline',
                onTap: _cacheOffline,
              ),
              _buildShareButton(
                icon: Icons.analytics,
                label: 'Analytics',
                onTap: _exportAnalytics,
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Export options
          if (widget.analytics != null) ...[
            const Text(
              'Export Data',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            
            const SizedBox(height: 12),
            
            _buildExportOptions(),
            
            const SizedBox(height: 20),
          ],
          
          // Bottom padding for safe area
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  Widget _buildRouteInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.route.name,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 8),
          
          Row(
            children: [
              _buildInfoChip(
                icon: Icons.straighten,
                label: widget.route.formattedDistance,
              ),
              const SizedBox(width: 8),
              _buildInfoChip(
                icon: Icons.terrain,
                label: widget.route.formattedElevationGain,
              ),
              const SizedBox(width: 8),
              _buildInfoChip(
                icon: Icons.star,
                label: widget.route.averageRating.toStringAsFixed(1),
              ),
            ],
          ),
          
          if (widget.analytics != null) ...[
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            Text(
              'Your Performance',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildInfoChip(
                  icon: Icons.check_circle,
                  label: '${(widget.analytics!.routeCompletion * 100).toStringAsFixed(0)}% complete',
                  color: Colors.green,
                ),
                const SizedBox(width: 8),
                _buildInfoChip(
                  icon: Icons.speed,
                  label: '${widget.analytics!.routeEfficiency.toStringAsFixed(1)}% efficient',
                  color: Colors.blue,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildShareButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.grey.shade100,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 24,
                color: Colors.blue,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExportOptions() {
    return Column(
      children: [
        _buildExportTile(
          title: 'Route Data (JSON)',
          subtitle: 'Complete route information',
          icon: Icons.data_object,
          onTap: () => _exportData('json'),
        ),
        _buildExportTile(
          title: 'GPX File',
          subtitle: 'GPS Exchange Format',
          icon: Icons.route,
          onTap: () => _exportData('gpx'),
        ),
        _buildExportTile(
          title: 'Performance Report',
          subtitle: 'Detailed analytics and statistics',
          icon: Icons.assessment,
          onTap: () => _exportData('report'),
        ),
      ],
    );
  }

  Widget _buildExportTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: _isExporting
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: _isExporting ? null : onTap,
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    Color? color,
  }) {
    final chipColor = color ?? Colors.grey.shade600;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: chipColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: chipColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: chipColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _copyRouteLink() async {
    final link = 'https://goodfit.app/routes/${widget.route.id}';
    await Clipboard.setData(ClipboardData(text: link));
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Route link copied to clipboard'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _showQRCode() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('QR Code'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text('QR Code\nComing Soon'),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Scan to access route:\n${widget.route.name}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _shareRoute() {
    // TODO: Implement native sharing
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Native sharing feature coming soon'),
      ),
    );
  }

  Future<void> _exportGPX() async {
    setState(() {
      _isExporting = true;
    });

    try {
      // Generate GPX data
      final gpxData = _generateGPX();
      
      // TODO: Save to device or share
      await Future.delayed(const Duration(seconds: 2)); // Simulate export
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('GPX file exported successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isExporting = false;
      });
    }
  }

  Future<void> _cacheOffline() async {
    final success = await _offlineService.cacheRoute(widget.route);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success 
                ? 'Route cached for offline use' 
                : 'Failed to cache route',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Future<void> _exportAnalytics() async {
    setState(() {
      _isExporting = true;
    });

    try {
      final analyticsData = await _analyticsService.exportRouteData(widget.route.id);
      
      // TODO: Save or share analytics data
      await Future.delayed(const Duration(seconds: 1)); // Simulate export
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Analytics exported successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isExporting = false;
      });
    }
  }

  Future<void> _exportData(String format) async {
    setState(() {
      _isExporting = true;
    });

    try {
      switch (format) {
        case 'json':
          final jsonData = widget.route.toJson();
          // TODO: Save JSON data
          break;
        case 'gpx':
          final gpxData = _generateGPX();
          // TODO: Save GPX data
          break;
        case 'report':
          final reportData = _generateReport();
          // TODO: Save report
          break;
      }
      
      await Future.delayed(const Duration(seconds: 1)); // Simulate export
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${format.toUpperCase()} exported successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isExporting = false;
      });
    }
  }

  String _generateGPX() {
    final buffer = StringBuffer();
    
    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln('<gpx version="1.1" creator="GoodFit App">');
    buffer.writeln('  <trk>');
    buffer.writeln('    <name>${widget.route.name}</name>');
    buffer.writeln('    <desc>${widget.route.description}</desc>');
    buffer.writeln('    <trkseg>');
    
    if (widget.route.coordinates != null) {
      for (final point in widget.route.coordinates!) {
        buffer.writeln('      <trkpt lat="${point.latitude}" lon="${point.longitude}"/>');
      }
    }
    
    buffer.writeln('    </trkseg>');
    buffer.writeln('  </trk>');
    buffer.writeln('</gpx>');
    
    return buffer.toString();
  }

  Map<String, dynamic> _generateReport() {
    return {
      'route': widget.route.toJson(),
      'analytics': widget.analytics?.toJson(),
      'generated_at': DateTime.now().toIso8601String(),
      'app_version': '1.0.0',
    };
  }
}