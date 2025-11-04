// plans_history_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart'; 

class PlansHistoryScreen extends StatefulWidget {
  const PlansHistoryScreen({Key? key}) : super(key: key);

  @override
  State<PlansHistoryScreen> createState() => _PlansHistoryScreenState();
}

class _PlansHistoryScreenState extends State<PlansHistoryScreen> {
  List<Map<String, dynamic>> _savedPlans = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPlans();
  }

  Future<void> _loadPlans() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> savedPlansJson = prefs.getStringList('savedTripPlans') ?? [];
    
    List<Map<String, dynamic>> loadedPlans = [];
    
    // Reverse for newest first display
    for (var jsonString in savedPlansJson.reversed) { 
      try {
        final Map<String, dynamic> planMap = jsonDecode(jsonString) as Map<String, dynamic>;
        loadedPlans.add(planMap);
      } catch (e) {
        print('Error decoding plan JSON: $e');
      }
    }

    setState(() {
      _savedPlans = loadedPlans;
      _isLoading = false;
    });
  }
  
  // NEW: Function to delete a plan
  Future<void> _deletePlan(int index) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> savedPlansJson = prefs.getStringList('savedTripPlans') ?? [];
    
    // The item at `index` in `_savedPlans` (the reversed list) corresponds to 
    // `savedPlansJson.length - 1 - index` in the original saved list.
    final int originalIndex = savedPlansJson.length - 1 - index; 

    if (originalIndex >= 0 && originalIndex < savedPlansJson.length) {
      savedPlansJson.removeAt(originalIndex);
      await prefs.setStringList('savedTripPlans', savedPlansJson);
      
      setState(() {
        _savedPlans.removeAt(index);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Trip plan deleted successfully.")),
      );
    }
  }

  // NEW: Confirmation Dialog for Delete
  void _confirmDeletePlan(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Confirm Delete"),
          content: const Text("Are you sure you want to permanently delete this trip plan?"),
          actions: <Widget>[
            TextButton(
              child: const Text("Cancel"),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text("Delete", style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(context).pop();
                _deletePlan(index);
              },
            ),
          ],
        );
      },
    );
  }
  
  // --- HELPER METHODS FOR DETAIL VIEW ---

  String _ratingToStars(String? rating) {
    if (rating == null || rating.isEmpty || rating.toLowerCase() == 'n/a' || rating.toLowerCase() == 'n/a/5') {
      return '';
    }

    RegExp exp = RegExp(r'(\d+\.?\d*)');
    String? numStr = exp.firstMatch(rating)?.group(1);

    if (numStr == null) {
      return '($rating)'; 
    }
    
    double? value = double.tryParse(numStr);
    if (value == null || value < 0.1) {
        return '($rating)'; 
    }
    
    if (value > 5 && value <= 10) {
        value = value / 2.0;
    } else if (value > 5) {
        return '($rating)'; 
    }

    double roundedValue = (value * 2).round() / 2;
    roundedValue = roundedValue > 5.0 ? 5.0 : roundedValue;

    int fullStars = roundedValue.floor();
    bool halfStar = (roundedValue - fullStars) >= 0.5;
    
    String stars = '⭐' * fullStars;

    if (halfStar) {
      stars += '½'; 
    }
    
    if (stars.isEmpty) {
        return '($rating)';
    }

    return stars;
  }
  
  Future<void> _openMap(BuildContext context, String query) async {
    final String encodedQuery = Uri.encodeComponent(query);
    // Use the correct Google Maps URL format for mobile
    final Uri url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$encodedQuery'); 

    // The user's code previously had an incorrect URL. This is the correct one.
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open map for: $query')),
      );
    }
  }
  
  Widget _buildPlanSection(BuildContext context, String title, List<dynamic> items, {bool isRoute = false}) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.only(top: 10, bottom: 5, left: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 10.0, bottom: 5.0),
            child: Text(title,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Colors.indigo)),
          ),
          ...items.map((item) {
            String name;
            String? mapQuery;
            String? type;

            if (isRoute) {
              name = item as String;
              final index = items.indexOf(item);
              final isLast = index == items.length - 1;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Text(isLast ? "📍 $name" : "📍 $name →", style: const TextStyle(fontSize: 14)),
              );
            } else {
              final itemMap = item as Map<String, dynamic>;
              name = itemMap['name'] as String;
              final rating = itemMap['rating'] as String?; 
              mapQuery = itemMap['mapSearchQuery'] as String?;
              type = itemMap['type'] as String?;
              
              String displayTitle = name;
              if (type != null && type.isNotEmpty) {
                  displayTitle = '$name (${type})';
              }

              String starString = _ratingToStars(rating);
              if (starString.isNotEmpty) {
                  displayTitle = '$displayTitle - $starString';
              }
              else if (rating != null && rating.isNotEmpty && rating.toLowerCase() != 'n/a') {
                  displayTitle = '$displayTitle - ($rating)';
              }

              if (mapQuery != null && mapQuery.isNotEmpty) {
                return GestureDetector(
                  onTap: () => _openMap(context, mapQuery!), 
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Text(
                      "• $displayTitle",
                      style: TextStyle(
                          color: Colors.indigo.shade700,
                          fontSize: 14,
                          decoration: TextDecoration.underline),
                    ),
                  ), 
                ); 
              } else {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Text("• $displayTitle", style: const TextStyle(fontSize: 14)),
                );
              }
            }
          }).toList(),
          const SizedBox(height: 5),
        ],
      ),
    );
  }

  // --- _buildPlanCard uses ExpansionTile ---
  Widget _buildPlanCard(Map<String, dynamic> plan, int index) {
    final String summary = plan['itinerarySummary'] as String? ?? 'No summary available.';
    final List<dynamic> routeStops = plan['routeStops'] as List<dynamic>? ?? [];
    final List<dynamic> touristStops = plan['touristStops'] as List<dynamic>? ?? [];
    final List<dynamic> hotelRecommendations = plan['hotelRecommendations'] as List<dynamic>? ?? [];
    final List<dynamic> stopRecommendations = plan['stopRecommendations'] as List<dynamic>? ?? []; 
    final String safetyTip = plan['safeRouteTip'] as String? ?? 'No safety tip provided.';
    
    String tripRoute = 'N/A';
    if (routeStops.length >= 2) {
      tripRoute = '${routeStops.first} to ${routeStops.last}';
    }

    final displayIndex = _savedPlans.length - index; 

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.all(20),
        title: Text(
          "Trip Plan #$displayIndex",
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo),
        ),
        subtitle: Text(
          "Route: $tripRoute",
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87),
        ),
        // UPDATED: Trailing is the Delete Button
        trailing: IconButton(
          icon: const Icon(Icons.delete_forever, color: Colors.red),
          onPressed: () => _confirmDeletePlan(index),
          tooltip: 'Delete Plan',
        ),
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Summary
                const Text("Itinerary Summary:", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Colors.indigo)),
                const Divider(color: Colors.indigo, thickness: 1.5),
                Text(summary, style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic)),

                // 2. Route Stops
                _buildPlanSection(context, "🚗 Detailed Route Stops:", routeStops, isRoute: true),

                // 3. Tourist Stops
                _buildPlanSection(context, "📸 Tourist Attractions (Click to Map):", touristStops),

                // 4. Hotel Recommendations
                _buildPlanSection(context, "🏨 Hotel Recommendations (Click to Map):", hotelRecommendations),

                // 5. Fuel/Rest Stops
                _buildPlanSection(context, "⛽ Service/Fuel Stops (Click to Map):", stopRecommendations),
                
                // 6. Safety Tip
                const SizedBox(height: 16),
                const Text("🛡️ Safety Tip:",
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Colors.indigo)),
                const Divider(color: Colors.indigo, thickness: 1.5),
                Padding(
                  padding: const EdgeInsets.only(left: 8, top: 4, bottom: 20),
                  child: Text(safetyTip, style: const TextStyle(fontSize: 14)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Past Trip Plans'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      backgroundColor: const Color(0xFFEAF3FF),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.indigo))
          : _savedPlans.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      elevation: 8,
                      child: Padding(
                        padding: const EdgeInsets.all(30.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.history_toggle_off, size: 50, color: Colors.indigo),
                            SizedBox(height: 10),
                            Text(
                              'No past plans found. Generate and save a plan first!',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 18, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(20.0),
                  itemCount: _savedPlans.length,
                  itemBuilder: (context, index) {
                    final plan = _savedPlans[index];
                    return _buildPlanCard(plan, index);
                  },
                ),
    );
  }
}