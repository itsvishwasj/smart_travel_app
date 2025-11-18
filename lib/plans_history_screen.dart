import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PlansHistoryScreen extends StatefulWidget {
  const PlansHistoryScreen({Key? key}) : super(key: key);

  @override
  State<PlansHistoryScreen> createState() => _PlansHistoryScreenState();
}

class _PlansHistoryScreenState extends State<PlansHistoryScreen> {
  List<Map<String, dynamic>> _savedPlans = [];
  List<bool> _expanded = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSavedPlans();
  }

  Future<void> _loadSavedPlans() async {
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> rawList =
          prefs.getStringList('savedTripPlans') ?? [];

      final List<Map<String, dynamic>> decoded = rawList.map((p) {
        try {
          return jsonDecode(p) as Map<String, dynamic>;
        } catch (_) {
          return <String, dynamic>{};
        }
      }).where((e) => e.isNotEmpty).toList();

      setState(() {
        _savedPlans = decoded.reversed.toList(); // latest first
        _expanded = List<bool>.filled(_savedPlans.length, false);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading saved plans: $e')),
      );
    }
  }

  String _formatDateTime(String? iso) {
    if (iso == null || iso.isEmpty) return 'Unknown';
    try {
      final dt = DateTime.parse(iso);
      return DateFormat('EEE, MMM d, yyyy – hh:mm a').format(dt);
    } catch (_) {
      return iso;
    }
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

  Future<void> _confirmDelete(int index) async {
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
      final prefs = await SharedPreferences.getInstance();
      final List<String> rawList =
          prefs.getStringList('savedTripPlans') ?? [];

      // because we reversed for display
      final realIndex = rawList.length - 1 - index;
      if (realIndex >= 0 && realIndex < rawList.length) {
        rawList.removeAt(realIndex);
        await prefs.setStringList('savedTripPlans', rawList);
      }

      await _loadSavedPlans();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Past Trip Plans'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _savedPlans.isEmpty
              ? const Center(
                  child: Text(
                    'No plans saved yet.\nGenerate a trip plan and tap "Save Plan".',
                    textAlign: TextAlign.center,
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _savedPlans.length,
                  itemBuilder: (context, index) {
                    final plan = _savedPlans[index];
                    final meta =
                        (plan['meta'] ?? {}) as Map<String, dynamic>;

                    final String from = (meta['from'] ?? '') as String;
                    final String to = (meta['to'] ?? '') as String;
                    final int members =
                        (meta['members'] ?? 0) as int;
                    final String savedAt =
                        _formatDateTime(meta['savedAt'] as String?);
                    final String plannedDate =
                        _formatPlannedDate(meta['plannedDate'] as String?);
                    final String tripName =
                        (meta['tripName'] ?? '') as String? ??
                            (from.isNotEmpty && to.isNotEmpty
                                ? '$from → $to'
                                : 'Trip ${index + 1}');

                    final String estimatedCost =
                        (plan['estimatedTotalCost'] ?? 'N/A') as String;
                    final String itinerarySummary =
                        (plan['itinerarySummary'] ??
                                'No summary available.')
                            as String;

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

                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 4,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onLongPress: () => _confirmDelete(index),
                        child: Padding(
                          padding: const EdgeInsets.all(14.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // TOP: Trip name + cost
                              Row(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
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
                                    duration: const Duration(
                                        milliseconds: 200),
                                    turns:
                                        _expanded[index] ? 0.5 : 0.0,
                                    child: const Icon(
                                      Icons.keyboard_arrow_down,
                                      size: 28,
                                    ),
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _expanded[index] =
                                          !_expanded[index];
                                    });
                                  },
                                ),
                              ),

                              // Expanded content
                              AnimatedCrossFade(
                                duration: const Duration(
                                    milliseconds: 250),
                                crossFadeState: _expanded[index]
                                    ? CrossFadeState.showSecond
                                    : CrossFadeState.showFirst,
                                firstChild:
                                    const SizedBox.shrink(),
                                secondChild: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
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
                                        style:
                                            TextStyle(fontSize: 13),
                                      )
                                    else
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: routeStops
                                            .whereType<String>()
                                            .map((name) {
                                          final idx = routeStops
                                              .whereType<String>()
                                              .toList()
                                              .indexOf(name);
                                          final isLast = idx ==
                                              routeStops
                                                      .whereType<
                                                          String>()
                                                      .length -
                                                  1;
                                          return Padding(
                                            padding:
                                                const EdgeInsets
                                                        .only(
                                                    bottom: 2),
                                            child: Text(
                                              isLast
                                                  ? '• $name'
                                                  : '• $name →',
                                              style:
                                                  const TextStyle(
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
                                        style:
                                            TextStyle(fontSize: 13),
                                      )
                                    else
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: touristStops
                                            .map((raw) {
                                          final m = raw
                                              as Map<String, dynamic>;
                                          final name =
                                              (m['name'] ?? '')
                                                  as String;
                                          if (name.isEmpty) {
                                            return const SizedBox
                                                .shrink();
                                          }
                                          return Padding(
                                            padding:
                                                const EdgeInsets
                                                        .only(
                                                    bottom: 2),
                                            child: Text(
                                              '• $name',
                                              style:
                                                  const TextStyle(
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
                                        style:
                                            TextStyle(fontSize: 13),
                                      )
                                    else
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: hotels.map((raw) {
                                          final m = raw
                                              as Map<String, dynamic>;
                                          final name =
                                              (m['name'] ?? '')
                                                  as String;
                                          if (name.isEmpty) {
                                            return const SizedBox
                                                .shrink();
                                          }
                                          return Padding(
                                            padding:
                                                const EdgeInsets
                                                        .only(
                                                    bottom: 2),
                                            child: Text(
                                              '• $name',
                                              style:
                                                  const TextStyle(
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
                                        style:
                                            TextStyle(fontSize: 13),
                                      )
                                    else
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: services.map((raw) {
                                          final m = raw
                                              as Map<String, dynamic>;
                                          final name =
                                              (m['name'] ?? '')
                                                  as String;
                                          if (name.isEmpty) {
                                            return const SizedBox
                                                .shrink();
                                          }
                                          return Padding(
                                            padding:
                                                const EdgeInsets
                                                        .only(
                                                    bottom: 2),
                                            child: Text(
                                              '• $name',
                                              style:
                                                  const TextStyle(
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
                                        style:
                                            TextStyle(fontSize: 13),
                                      )
                                    else
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: smartTips.map((raw) {
                                          final m = raw
                                              as Map<String, dynamic>;
                                          final heading =
                                              (m['heading'] ??
                                                      'Tip')
                                                  as String;
                                          final tip = (m['tip'] ??
                                                  'No detail provided.')
                                              as String;
                                          return Padding(
                                            padding:
                                                const EdgeInsets
                                                        .only(
                                                    bottom: 8),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment
                                                      .start,
                                              children: [
                                                Text(
                                                  '• $heading',
                                                  style:
                                                      const TextStyle(
                                                    fontSize: 13,
                                                    fontWeight:
                                                        FontWeight
                                                            .w600,
                                                  ),
                                                ),
                                                const SizedBox(
                                                    height: 2),
                                                Text(
                                                  tip,
                                                  style:
                                                      const TextStyle(
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
                ),
    );
  }
}
