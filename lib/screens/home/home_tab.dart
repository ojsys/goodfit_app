import 'package:flutter/material.dart';
import '../../widgets/common/activity_summary_card.dart';
import '../../widgets/common/upcoming_events_section.dart';
import '../../widgets/common/suggested_matches_section.dart';
import '../../widgets/common/activity_feed_section.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('A Good Fit'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {},
          ),
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.grey.shade300,
            child: const Icon(Icons.person, size: 20),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ActivitySummaryCard(),
            SizedBox(height: 24),
            UpcomingEventsSection(),
            SizedBox(height: 24),
            SuggestedMatchesSection(),
            SizedBox(height: 24),
            ActivityFeedSection(),
          ],
        ),
      ),
    );
  }
}