import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PlansHistoryScreen extends StatefulWidget {
  const PlansHistoryScreen({Key? key}) : super(key: key);

  @override
  State<PlansHistoryScreen> createState() => _PlansHistoryScreenState();
}

class _PlansHistoryScreenState extends State<PlansHistoryScreen> {
  // Track which plan (by Firestore doc ID) is expanded
  final Map<String, bool> _expanded = {};

  String _formatDateTime(String? iso, {Timestamp? fallback}) {
    try {
      if (iso != null && iso.isNotEmpty) {
        final dt = DateTime.parse(iso);
        return DateFormat('EEE, MMM d, yyyy – hh:mm a').format(dt);
      }
    } catch (_) {
      // ignore and try fallback
    }

    if (fallback != null) {
      final dt = fallback.toDate();
      return DateFormat('EEE, MMM d, yyyy – hh:mm a').format(dt);
    }

    return 'Unknown';
  }

  String _formatPlannedDate(String? iso) {
    if (iso == null || iso.isEmpty) return 'Not provided';
    try {
      final dt = DateTime.parse(iso);
      return DateFormat('EEE, MMM d, yyyy').format(dt);
    } catch (_) {
      return iso;
    }
  }

  Future<void> _confirmDelete(String docId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this plan?'),
        content: const Text(
          'This will permanently remove the saved plan from history.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (ok == true) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('plans')
            .doc(docId)
            .delete();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Plan deleted')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting plan: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Past Trip Plans'),
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text(
            'Please log in to view your saved trip plans.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final plansQuery = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('plans')
        .orderBy('createdAt', descending: true);

    return Scaffold(
      backgroundColor: const Color(0xFFEAF3FF),
      appBar: AppBar(
        title: const Text('Past Trip Plans'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: plansQuery.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading saved plans:\n${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(
              child: Text(
                'No plans saved yet.\nGenerate a trip plan and tap "Save Plan".',
                textAlign: TextAlign.center,
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final plan = doc.data();

              final meta = (plan['meta'] ?? {}) as Map<String, dynamic>;

              final String from = (meta['from'] ?? '') as String;
              final String to = (meta['to'] ?? '') as String;
              final int members = (meta['members'] ?? 0) as int;

              final Timestamp? createdAtTs =
                  plan['createdAt'] is Timestamp ? plan['createdAt'] as Timestamp : null;

              final String savedAt =
                  _formatDateTime(meta['savedAt'] as String?, fallback: createdAtTs);
              final String plannedDate =
                  _formatPlannedDate(meta['plannedDate'] as String?);

              final String tripName =
                  (meta['tripName'] as String?) ??
                      (from.isNotEmpty && to.isNotEmpty
                          ? '$from → $to'
                          : 'Trip ${index + 1}');

              final String estimatedCost =
                  (plan['estimatedTotalCost'] ?? 'N/A') as String;
              final String itinerarySummary =
                  (plan['itinerarySummary'] ?? 'No summary available.') as String;

              final List<dynamic> routeStops =
                  (plan['routeStops'] as List?) ?? [];
              final List<dynamic> touristStops =
                  (plan['touristStops'] as List?) ?? [];
              final List<dynamic> hotels =
                  (plan['hotelRecommendations'] as List?) ?? [];
              final List<dynamic> services =
                  (plan['stopRecommendations'] as List?) ?? [];
              final List<dynamic> smartTips =
                  (plan['smartAdvisorTips'] as List?) ?? [];

              final String docId = doc.id;
              final bool isExpanded = _expanded[docId] ?? false;

              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 4,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onLongPress: () => _confirmDelete(docId),
                  child: Padding(
                    padding: const EdgeInsets.all(14.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // TOP: Trip name + cost
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                tripName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (estimatedCost.isNotEmpty)
                              Text(
                                estimatedCost,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.green.shade700,
                                ),
                                textAlign: TextAlign.right,
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),

                        // From → To
                        if (from.isNotEmpty || to.isNotEmpty)
                          Text(
                            '📍 ${from.isNotEmpty ? from : 'Unknown'} → ${to.isNotEmpty ? to : 'Unknown'}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.black87,
                            ),
                          ),

                        const SizedBox(height: 4),

                        // Dates + Travellers
                        Text(
                          '📅 Saved: $savedAt',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          '🗓 Trip Planned Date: $plannedDate',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          '👥 Travellers: $members',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),

                        const SizedBox(height: 8),
                        Divider(
                          height: 16,
                          color: Colors.grey.shade300,
                        ),

                        // Expand / Collapse Arrow
                        Center(
                          child: IconButton(
                            icon: AnimatedRotation(
                              duration: const Duration(milliseconds: 200),
                              turns: isExpanded ? 0.5 : 0.0,
                              child: const Icon(
                                Icons.keyboard_arrow_down,
                                size: 28,
                              ),
                            ),
                            onPressed: () {
                              setState(() {
                                _expanded[docId] = !isExpanded;
                              });
                            },
                          ),
                        ),

                        // Expanded content
                        AnimatedCrossFade(
                          duration: const Duration(milliseconds: 250),
                          crossFadeState: isExpanded
                              ? CrossFadeState.showSecond
                              : CrossFadeState.showFirst,
                          firstChild: const SizedBox.shrink(),
                          secondChild: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                '📝 Itinerary Summary:',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.indigo.shade700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                itinerarySummary,
                                style: const TextStyle(
                                  fontSize: 13,
                                ),
                              ),

                              const SizedBox(height: 10),
                              Text(
                                '🚗 Route:',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.indigo.shade700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              if (routeStops.isEmpty)
                                const Text(
                                  'No route information available.',
                                  style: TextStyle(fontSize: 13),
                                )
                              else
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: routeStops
                                      .whereType<String>()
                                      .map((name) {
                                    final stops =
                                        routeStops.whereType<String>().toList();
                                    final idx = stops.indexOf(name);
                                    final isLast = idx == stops.length - 1;
                                    return Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 2),
                                      child: Text(
                                        isLast ? '• $name' : '• $name →',
                                        style: const TextStyle(
                                          fontSize: 13,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),

                              const SizedBox(height: 10),
                              Text(
                                '📸 Tourist Stops:',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.indigo.shade700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              if (touristStops.isEmpty)
                                const Text(
                                  'No tourist stops available.',
                                  style: TextStyle(fontSize: 13),
                                )
                              else
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: touristStops.map((raw) {
                                    final m = raw as Map<String, dynamic>;
                                    final name =
                                        (m['name'] ?? '') as String;
                                    if (name.isEmpty) {
                                      return const SizedBox.shrink();
                                    }
                                    return Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 2),
                                      child: Text(
                                        '• $name',
                                        style: const TextStyle(
                                          fontSize: 13,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),

                              const SizedBox(height: 10),
                              Text(
                                '🏨 Hotel Recommendations:',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.indigo.shade700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              if (hotels.isEmpty)
                                const Text(
                                  'No hotel recommendations available.',
                                  style: TextStyle(fontSize: 13),
                                )
                              else
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: hotels.map((raw) {
                                    final m = raw as Map<String, dynamic>;
                                    final name =
                                        (m['name'] ?? '') as String;
                                    if (name.isEmpty) {
                                      return const SizedBox.shrink();
                                    }
                                    return Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 2),
                                      child: Text(
                                        '• $name',
                                        style: const TextStyle(
                                          fontSize: 13,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),

                              const SizedBox(height: 10),
                              Text(
                                '⛽ Service Stops:',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.indigo.shade700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              if (services.isEmpty)
                                const Text(
                                  'No service stops available.',
                                  style: TextStyle(fontSize: 13),
                                )
                              else
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: services.map((raw) {
                                    final m = raw as Map<String, dynamic>;
                                    final name =
                                        (m['name'] ?? '') as String;
                                    if (name.isEmpty) {
                                      return const SizedBox.shrink();
                                    }
                                    return Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 2),
                                      child: Text(
                                        '• $name',
                                        style: const TextStyle(
                                          fontSize: 13,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),

                              const SizedBox(height: 10),
                              Text(
                                '💡 Smart Advisor Tips:',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.indigo.shade700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              if (smartTips.isEmpty)
                                const Text(
                                  'No specific suggestions generated.',
                                  style: TextStyle(fontSize: 13),
                                )
                              else
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: smartTips.map((raw) {
                                    final m = raw as Map<String, dynamic>;
                                    final heading =
                                        (m['heading'] ?? 'Tip') as String;
                                    final tip =
                                        (m['tip'] ?? 'No detail provided.')
                                            as String;
                                    return Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 8),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '• $heading',
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            tip,
                                            style: const TextStyle(
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 6),
                        const Text(
                          'Long-press to delete this plan.',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
