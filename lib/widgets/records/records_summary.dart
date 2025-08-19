import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/personal_records_provider.dart';
import '../../theme/app_theme.dart';

class RecordsSummary extends StatelessWidget {
  const RecordsSummary({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PersonalRecordsProvider>(
      builder: (context, recordsProvider, child) {
        final recentRecords = recordsProvider.recentRecords;
        final totalRecords = recordsProvider.getTotalRecords();
        final newRecordsCount = recordsProvider.getNewRecordsCount();
        final improvements = recordsProvider.getImprovementsOnly();

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.military_tech,
                        color: AppTheme.primaryColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Personal Records',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        // Navigate to records tab - we'll implement this
                      },
                      child: const Text('View All'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Records Stats
                Row(
                  children: [
                    Expanded(
                      child: _buildRecordStat(
                        'Total Records',
                        totalRecords.toString(),
                        Icons.military_tech,
                        AppTheme.primaryColor,
                      ),
                    ),
                    Expanded(
                      child: _buildRecordStat(
                        'This Week',
                        newRecordsCount.toString(),
                        Icons.schedule,
                        Colors.green,
                      ),
                    ),
                    Expanded(
                      child: _buildRecordStat(
                        'Improvements',
                        improvements.length.toString(),
                        Icons.trending_up,
                        Colors.orange,
                      ),
                    ),
                  ],
                ),
                
                if (recentRecords.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text(
                    'Recent Records',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...recentRecords.take(3).map((record) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppTheme.primaryColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Icon(
                              _getRecordIcon(record.recordType),
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${record.activityTypeDisplay} - ${record.recordTypeDisplay}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  record.timeAgo,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                record.valueDisplay,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                              if (record.improvementDisplay != null)
                                Text(
                                  record.improvementDisplay!,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.green,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ] else
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.military_tech_outlined,
                          color: Colors.grey,
                          size: 20,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Complete activities to set personal records!',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecordStat(String label, String count, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          count,
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
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  IconData _getRecordIcon(String recordType) {
    switch (recordType.toLowerCase()) {
      case 'fastest_time':
        return Icons.timer;
      case 'longest_distance':
        return Icons.straighten;
      case 'highest_calories':
        return Icons.local_fire_department;
      case 'best_pace':
        return Icons.speed;
      default:
        return Icons.military_tech;
    }
  }
}