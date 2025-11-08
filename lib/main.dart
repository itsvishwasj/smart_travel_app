// main.dart
import 'package:flutter/material.dart';
import 'dart:convert'; // Import for JSON handling
// !!! IMPORTANT: The url_launcher package must be added to pubspec.yaml
import 'package:url_launcher/url_launcher.dart'; 

// !!! IMPORTANT: google_generative_ai package must be added to pubspec.yaml
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart'; // NEW: For local storage

import 'weather_screen.dart';
import 'expense_tab.dart'; 
import 'plans_history_screen.dart'; 
import 'expenses_history_screen.dart'; 

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Travel Assistant',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        useMaterial3: true,
      ), 
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<String> routeStops = []; // shared with Weather tab

  // --- Navigation Helpers ---
  void _navigateToTab(int index, BuildContext context) {
    Navigator.of(context).pop(); // Close the drawer
    final TabController? controller = DefaultTabController.of(context);
    if (controller != null) {
      controller.animateTo(index);
    }
  }

  void _navigateToPlansHistory() {
    Navigator.of(context).pop(); // Close the drawer first
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const PlansHistoryScreen(),
      ),
    );
  }

  void _navigateToExpensesHistory() {
    Navigator.of(context).pop(); // Close the drawer first
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ExpensesHistoryScreen(),
      ),
    );
  }
  
  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: 'Smart Travel Assistant',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(Icons.travel_explore, color: Colors.indigo),
      children: const <Widget>[
        Padding(
          padding: EdgeInsets.only(top: 15),
          child: Text('Your intelligent companion for trip planning, weather checks, and expense tracking.'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFEAF3FF),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          title: const Text(
            "Smart Travel Assistant",
            style: TextStyle(
              color: Colors.indigo,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          iconTheme: const IconThemeData(color: Colors.indigo),
          actions: const [
            // LOGOUT BUTTON REMOVED FROM HERE
          ],
          bottom: const TabBar(
            labelColor: Colors.indigo,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.indigo,
            tabs: [
              Tab(text: "Plan"),
              Tab(text: "Weather"),
              Tab(text: "Expenses"),
            ],
          ),
        ),
        
        // --- INDIGO-THEMED DRAWER ---
        drawer: Drawer(
          backgroundColor: Colors.white, 
          child: ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
              // Drawer Header
              const UserAccountsDrawerHeader(
                accountName: Text(
                  'Welcome, Traveler!',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
                ),
                accountEmail: Text('user.name@example.com', style: TextStyle(color: Colors.white70)),
                currentAccountPicture: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Icon(Icons.account_circle, size: 50, color: Colors.indigo),
                ),
                decoration: BoxDecoration(
                  color: Colors.indigo, // Primary color theme
                ),
              ),
              
              // Navigation ListTiles (to tabs)
              ListTile(
                leading: const Icon(Icons.map, color: Colors.indigo),
                title: const Text('Plan Trip', style: TextStyle(color: Colors.indigo)),
                onTap: () => _navigateToTab(0, context),
              ),
              ListTile(
                leading: const Icon(Icons.cloud, color: Colors.indigo),
                title: const Text('Current Weather', style: TextStyle(color: Colors.indigo)),
                onTap: () => _navigateToTab(1, context),
              ),
              ListTile(
                leading: const Icon(Icons.monetization_on, color: Colors.indigo),
                title: const Text('Track Expenses', style: TextStyle(color: Colors.indigo)),
                onTap: () => _navigateToTab(2, context),
              ),
              const Divider(),
              
              // History Expansion Tile (COLOR CHANGED TO INDIGO)
              ExpansionTile(
                leading: const Icon(Icons.history, color: Colors.indigo), // CHANGED from teal to indigo
                title: const Text('History', style: TextStyle(color: Colors.indigo)), // CHANGED from teal to indigo
                children: <Widget>[
                  ListTile(
                    title: const Padding(
                      padding: EdgeInsets.only(left: 30.0),
                      child: Text('Past Plans'),
                    ),
                    leading: const Icon(Icons.list_alt, color: Colors.indigo),
                    onTap: _navigateToPlansHistory,
                  ),
                  ListTile(
                    title: const Padding(
                      padding: EdgeInsets.only(left: 30.0),
                      child: Text('Past Expenses'),
                    ),
                    leading: const Icon(Icons.receipt, color: Colors.indigo),
                    onTap: _navigateToExpensesHistory,
                  ),
                ],
              ),
              const Divider(),

              // Settings
              ListTile(
                leading: const Icon(Icons.settings, color: Colors.grey),
                title: const Text('Settings'),
                onTap: () {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Settings page coming soon!")),
                  );
                },
              ),
              
              // About App
              ListTile(
                leading: const Icon(Icons.info_outline, color: Colors.grey),
                title: const Text('About App'),
                onTap: () {
                  Navigator.of(context).pop(); 
                  _showAboutDialog();
                },
              ),

              // LOGOUT OPTION (COLOR CHANGED TO INDIGO)
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.indigo), // CHANGED from red to indigo
                title: const Text('Logout', style: TextStyle(color: Colors.indigo)), // CHANGED from red to indigo
                onTap: () {
                  Navigator.of(context).pop(); // Close the drawer first
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Logout tapped")),
                  );
                },
              ),
            ],
          ),
        ),
        // --- END OF DRAWER ---

        body: TabBarView(
          children: [
            PlanTab(
              onRouteUpdate: (stops) {
                setState(() {
                  routeStops = stops;
                });
              },
            ),
            WeatherScreen(routeStops: routeStops),
            const ExpenseTab(),
          ],
        ),
      ),
    );
  }
}

// PlanTab Implementation
class PlanTab extends StatefulWidget {
  final Function(List<String>) onRouteUpdate; // callback to send routeStops to HomeScreen
  const PlanTab({Key? key, required this.onRouteUpdate}) : super(key: key);

  @override
  State<PlanTab> createState() => _PlanTabState();
}

class _PlanTabState extends State<PlanTab> {
  // Controllers for input fields
  final TextEditingController fromController = TextEditingController();
  final TextEditingController toController = TextEditingController();
  final TextEditingController budgetController = TextEditingController();
  final TextEditingController daysController = TextEditingController();
  final TextEditingController travellersController = TextEditingController();

  String? selectedVehicle;
  
  // New state variables for AI integration
  bool _isLoading = false;
  Map<String, dynamic>? _generatedPlan;
  bool get _showPlan => _generatedPlan != null; // Use a getter based on the plan data

  final ScrollController _scrollController = ScrollController();

  // --- GEMINI API CONSTANTS AND IMPLEMENTATION ---
  final String _apiKey = 'AIzaSyC2gkLJ-pDwn4LMH9E3zRRgCj9GKu0AwR4'; // User provided API key

  // JSON schema for structured output
  final String _jsonSchemaTemplate = r'''
{
  "itinerarySummary": "A one-paragraph summary of the proposed road trip itinerary tailored to the budget and vehicle type.",
  "routeStops": [
    "A list of key city names or landmarks that must be visited in order."
  ],
  "touristStops": [
    {
      "name": "The name of the tourist attraction.",
      "mapSearchQuery": "A concise string to search on Google Maps (e.g., 'Stonehenge')."
    }
  ],
  "hotelRecommendations": [
    {
      "name": "The name of the hotel.",
      "mapSearchQuery": "A concise string to search on Google Maps (e.g., 'Best Western Seattle')."
    }
  ],
  "stopRecommendations": [
    {
      "name": "The name of the stop (e.g., 'Electrify America - Stop 2' or 'Shell Station near Exit 45').",
      "mapSearchQuery": "A concise string to search on Google Maps (e.g., 'Electrify America near Fresno').",
      "type": "Fuel" 
    }
  ],
  "smartAdvisorTips": [
    {
      "heading": "A short, descriptive heading for the tip (e.g., 'Safety Tip', 'Budget Overview', 'Rainy Day Route')",
      "tip": "The detailed, concise advice for the user."
    }
  ]
}
''';

  // --- Gemini API Call Implementation ---
  Future<Map<String, dynamic>> _callGeminiApi(String prompt) async {
    // 1. Initialize the Gemini Model
    final model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: _apiKey,
    );
    
    // 2. Generate content using the simplest signature 
    final response = await model.generateContent(
      [Content.text(prompt)],
    );

    if (response.text == null || response.text!.isEmpty) {
      throw Exception("Gemini API returned an empty response. Check API key validity or network.");
    }
    
    // 3. Clean and parse the response text assuming it's JSON
    try {
        return json.decode(response.text!) as Map<String, dynamic>;
    } catch (e) {
        // Fallback for cleaning up common markdown fences
        String cleanedText = response.text!.trim();
        if (cleanedText.startsWith('```json')) {
          cleanedText = cleanedText.substring(7);
        }
        if (cleanedText.endsWith('```')) {
          cleanedText = cleanedText.substring(0, cleanedText.length - 3);
        }
        return json.decode(cleanedText) as Map<String, dynamic>;
    }
  }

  // --- Logic Functions ---

  @override
  void dispose() {
    _scrollController.dispose();
    fromController.dispose();
    toController.dispose();
    budgetController.dispose();
    daysController.dispose();
    travellersController.dispose();
    super.dispose();
  }

  // DEFINITIVE FIX: Use the standard, universal Google Maps search URL scheme.
  Future<void> _openMap(BuildContext context, String query) async {
    // 1. Encode the query for a safe URL
    final String encodedQuery = Uri.encodeComponent(query);
    
    // 2. Construct the CORRECT, robust Google Maps search URL (Universal standard).
    final Uri url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$encodedQuery');

    // 3. Launch the URL using the url_launcher package
    if (await canLaunchUrl(url)) {
      // Use externalApplication mode to force the device to open the dedicated Maps app or browser
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      // If the URL cannot be launched, show an error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not launch map for: $query. Check if you have a browser or map app installed.')),
      );
    }
  }
  
  // NEW: Function to save the current plan to local storage
  void _savePlan() async {
    if (_generatedPlan == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No plan generated to save!')),
      );
      return;
    }

    try {
      // 1. Get SharedPreferences instance
      final prefs = await SharedPreferences.getInstance();
      
      // 2. Load existing plans (or an empty list if none exist)
      final savedPlansJson = prefs.getStringList('savedTripPlans') ?? [];
      
      // 3. Convert the current plan Map<String, dynamic> to a JSON string
      final planJsonString = jsonEncode(_generatedPlan);
      
      // 4. Add the new JSON string to the list
      savedPlansJson.add(planJsonString);
      
      // 5. Save the updated list back to SharedPreferences
      await prefs.setStringList('savedTripPlans', savedPlansJson);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Plan saved successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving plan: $e')),
      );
    }
  }

  // Method to reset the entire plan form
  void _resetPlan() {
    setState(() {
      fromController.clear();
      toController.clear();
      budgetController.clear();
      daysController.clear();
      travellersController.clear();
      selectedVehicle = null;
      _generatedPlan = null; // Clear the generated plan
      _isLoading = false;
      widget.onRouteUpdate([]); // Notify HomeScreen to clear weather stops
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Plan reset. Start a new trip!')),
    );
  }

  // Method to generate the travel plan using Gemini API
  void _generatePlan() async {
    if (fromController.text.isEmpty || toController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter both From and To locations")),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _generatedPlan = null; // Clear previous plan
    });

    // 1. Prepare Variables for the Prompt
    final String days = daysController.text.isNotEmpty ? daysController.text : '3';
    final String start = fromController.text.trim();
    final String end = toController.text.trim();
    
    // Hardcoded Interests (since no input field exists)
    const String interests = 'scenic drives, local cuisine, and history'; 
    
    final String members = travellersController.text.isNotEmpty ? travellersController.text : '2';
    final String budget = budgetController.text.isNotEmpty ? '₹${budgetController.text}' : '₹10,000';
    final String vehicle = selectedVehicle ?? 'Car'; // Default to Car
    
    // Date Constraint
    final String dateContext = 'Today is November 2025. The suggested itinerary must start within 3-4 days of this current time (e.g., Nov 11, 2025) and not in a far-off month like February.';

    // 2. Prepare CRITICAL INSTRUCTIONS (Logic)
    final int numMembers = int.tryParse(members) ?? 2;
    final int numRooms = (numMembers / 2).ceil();

    // Accommodation logic is for the **journey's overnight stops**, but the logic is now less about the final destination.
    final String accommodationLogic = "The $numMembers travelers will likely need about $numRooms room(s). Distribute the total budget of $budget across these rooms and the trip duration to find appropriate mid-range, cost-effective hotels. Crucially, recommend accommodation in less expensive outskirts or satellite areas near the route's mid-points to save budget for the final destination.";

    String stopLogic;
    if (vehicle.toLowerCase().contains('ev')) {
      stopLogic = "Recommend **specific EV charging stations** (e.g., Electrify America) and ensure they are well-spaced for an EV's range.";
    } else {
      stopLogic = "Recommend **specific fuel stops** (e.g., Shell, BP) and major rest areas, ensuring they are well-spaced for a standard vehicle.";
    }

    // UPDATED: Smart Advisor Logic to focus 100% on pre-destination road trip logistics and cost savings.
    final String smartAdvisorLogic = '''
    Generate a list of at least five highly practical tips for the 'smartAdvisorTips' array. The focus MUST be only on the road trip itself, from the start point to the end point, and NOT on activities once the destination is reached.

    The required tips are:
    1.  **Vehicle Suitability:** Heading 'Vehicle Choice Analysis'. Tip must state whether the chosen $vehicle is ideal for the $start to $end road trip based on traffic, road conditions, and distance, and specifically mention: **'Use bikes to avoid traffic, use cars in rainy weather.'**
    2.  **Fuel Minimization:** Heading 'Fuel Expense Minimizer'. Tip must give a specific driving technique or route strategy to minimize fuel/EV charge costs *on this particular route*.
    3.  **Food Minimization:** Heading 'On-Road Food Budget'. Tip must suggest practical ways to minimize food spending *during the drive*, such as where to stop cheaply or what to pack.
    4.  **Weather/Route Safety:** Heading 'Monsoon/Rain Safety Route'. Suggest a specific alternative route or section to avoid known water-logging or high-traffic areas during heavy rain, saving time and fuel.
    5.  **Traffic Avoidance:** Heading 'Traffic & Timing'. Suggest the best time of day (e.g., 'start at 4 AM') or a specific small detour to bypass the worst traffic congestion on the route.
    ''';

    // 3. Construct the Final Prompt (NOW WITH JSON INSTRUCTION)
    final String finalPrompt = '''
      You are a specialized road trip planning AI. Your task is to generate a comprehensive road trip plan for a $days-day journey from $start to $end.
      The traveler is interested in: $interests.
      The travel party consists of $members members with a total trip budget of $budget (for all trip accommodation and stops).
      They are traveling in a $vehicle.

      **CRITICAL INSTRUCTIONS (MUST FOLLOW):**
      1.  **ITINERARY and TOURIST STOPS:** The plan must include a logical sequence of stops and at least 3-5 must-see tourist attractions relevant to the user's interests. This should focus on stops ALONG THE ROUTE, not activities at the final destination.
      2.  **DATE CONSTRAINT:** $dateContext
      3.  **ACCOMMODATION RULE:** $accommodationLogic
      4.  **STOP RULE:** $stopLogic
      5.  **SMART ADVISOR RULE (CRITICAL FOCUS):** $smartAdvisorLogic

      **OUTPUT INSTRUCTION (CRITICAL):**
      You MUST ONLY return the response as a single, valid, raw JSON object that strictly adheres to this structure. Do not include any explanatory text, Markdown fences (like ```json), or code comments outside of the JSON object itself.

      JSON Structure to follow:
      $_jsonSchemaTemplate
    ''';

    try {
      // 4. Call the Gemini API
      final Map<String, dynamic> result = await _callGeminiApi(finalPrompt);

      setState(() {
        _generatedPlan = result;
        _isLoading = false;
        
        // 5. Send routeStops to HomeScreen for Weather tab
        // Safely extract the list, handling potential null or wrong type by defaulting to an empty list
        final List<String> routeStops = List<String>.from((_generatedPlan!['routeStops'] as List?)?.whereType<String>() ?? []);

        widget.onRouteUpdate(routeStops);
      });

      // Scroll to bottom after generating plan
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Smart plan generated by AI!')),
      );

    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating plan. The AI likely failed to return clean JSON. Error: ${e.toString()}'),
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  // METHOD: Show the modal radio button selection dialog
  void _showVehicleSelectionDialog(BuildContext context) {
    String? tempSelected = selectedVehicle;
    final List<Map<String, String>> vehicles = const [
      {'name': 'Bike', 'emoji': '🏍️'},
      {'name': 'Car', 'emoji': '🚗'},
      {'name': 'EV', 'emoji': '🔋'},
    ];
    
    const double emojiFontSize = 26.0;

    showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateSB) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              title: const Text('Select Vehicle'),
              contentPadding: const EdgeInsets.only(top: 12.0),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: vehicles.map((vehicleMap) {
                  final String value = '${vehicleMap['name']} ${vehicleMap['emoji']}';
                  
                  return RadioListTile<String>(
                    title: Row(
                      children: [
                        Text(
                          vehicleMap['name']!,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          vehicleMap['emoji']!,
                          style: const TextStyle(fontSize: emojiFontSize),
                        ),
                      ],
                    ),
                    value: value,
                    groupValue: tempSelected,
                    onChanged: (String? newValue) {
                      setStateSB(() {
                        tempSelected = newValue;
                      });
                    },
                  );
                }).toList(),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: const Text('Select'),
                  onPressed: () {
                    Navigator.of(context).pop(tempSelected);
                  },
                ),
              ],
            );
          },
        );
      },
    ).then((result) {
      if (result != null) {
        setState(() {
          selectedVehicle = result;
        });
      }
    });
  }

  // UPDATED: Helper widget to build the sections based on Gemini's JSON output
  Widget _buildPlanSection(String title, List<dynamic> items, {bool isRoute = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Text(title,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
        Padding(
          padding: const EdgeInsets.only(left: 14, top: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: items.map((item) {
              String name;
              String? mapQuery;

              if (isRoute) {
                // Handle routeStops (simple list of strings)
                name = item as String;
                final index = items.indexOf(item);
                final isLast = index == items.length - 1;
                return Text(isLast ? "• $name" : "• $name →" , style: const TextStyle(fontSize: 15));
              } else {
                // Handle complex objects (tourist, hotels, stops)
                final itemMap = item as Map<String, dynamic>;
                name = itemMap['name'] as String;
                mapQuery = itemMap['mapSearchQuery'] as String;

                // CORRECTED: Tap action now calls the _openMap function
                return GestureDetector(
                  onTap: () => _openMap(context, mapQuery!),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      "• $name",
                      style: TextStyle(
                          color: Colors.indigo.shade700,
                          fontSize: 15,
                          decoration: TextDecoration.underline),
                    ),
                  ), 
                ); 
              }
            }).toList(),
          ),
        ),
      ],
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.all(20.0),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 8,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 26.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              // --- Input Fields ---
              TextField(
                controller: fromController,
                decoration: InputDecoration(
                  labelText: "From",
                  hintText: "e.g., Bengaluru",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: toController,
                decoration: InputDecoration(
                  labelText: "To",
                  hintText: "e.g., Goa",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: budgetController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "Budget (Total Trip)",
                  hintText: "e.g., 5000 (INR)",
                  prefix: const Text('₹ '),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _showVehicleSelectionDialog(context),
                      child: Container(
                        height: 60,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  selectedVehicle ?? "Vehicle",
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: selectedVehicle == null ? Colors.grey.shade600 : Colors.black,
                                  ),
                                ),
                              ),
                            ),
                            const Icon(Icons.arrow_drop_down, color: Colors.grey),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: daysController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: "Days",
                        hintText: "e.g., 5",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: travellersController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "No. of travellers",
                  hintText: "e.g., 2",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                ),
              ),
              const SizedBox(height: 26),

              // --- Generate Plan & Refresh/Clear Buttons ---
              Row(
                children: [
                  // 1. Generate Plan Button (Existing)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _generatePlan,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 3,
                              ),
                            )
                          : const Text(
                              "Generate Smart Plan (AI)",
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                            ),
                    ),
                  ),
                  
                  // 2. Clear/Refresh Button (NEW POSITION & STYLE)
                  if (_showPlan || _isLoading) ...[
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: _resetPlan,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal.shade600, // Kept the previous color
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Icon(
                        Icons.refresh, // Renamed/Replaced with refresh icon
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 30),

              // --- AI GENERATED PLAN OUTPUT ---
              if (_showPlan)
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.indigo.shade50,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Summary
                      Text(
                        "Trip Plan from ${fromController.text} to ${toController.text}",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                      ),
                      const Divider(color: Colors.indigo),
                      Text(
                        _generatedPlan!['itinerarySummary'] as String,
                        style: const TextStyle(fontSize: 15, fontStyle: FontStyle.italic),
                      ),
                      
                      // 2. Directions/Route Stops
                      _buildPlanSection(
                        "🚗 Recommended Route:", 
                        _generatedPlan!['routeStops'] as List<dynamic>, 
                        isRoute: true,
                      ),

                      // 3. Tourist Stops
                      _buildPlanSection(
                        "📸 Must-See Tourist Stops (Click to Map):", 
                        _generatedPlan!['touristStops'] as List<dynamic>,
                      ),

                      // 4. Hotel Recommendations
                      _buildPlanSection(
                        "🏨 Hotel Recommendations (Click to Map):", 
                        _generatedPlan!['hotelRecommendations'] as List<dynamic>,
                      ),

                      // 5. Fuel/Rest Stops
                      _buildPlanSection(
                        "⛽ Service Stops (Click to Map):", 
                        _generatedPlan!['stopRecommendations'] as List<dynamic>,
                      ),
                      
                      const SizedBox(height: 24),
                      // 6. Smart Advisor Tips (NEW SECTION)
                      const Text("💡 Smart Advisor Tips:",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.indigo)),
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: (_generatedPlan!['smartAdvisorTips'] as List<dynamic>?)
                              ?.map((tipItem) {
                                final Map<String, dynamic> item = tipItem as Map<String, dynamic>;
                                final String heading = item['heading'] as String? ?? 'Tip';
                                final String tip = item['tip'] as String? ?? 'No detail provided.';
                                
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Heading is now bold and styled
                                      Text(
                                        "• $heading",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.indigo.shade700,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      // Tip is the body text
                                      Text(
                                        tip, 
                                        style: const TextStyle(fontSize: 15),
                                      ),
                                    ],
                                  ),
                                );
                              })
                              .toList() ?? [const Text("No specific suggestions generated.")],
                        ),
                      ),
                    ],
                  ),
                ),
            
              // --- Save Plan Button (NEW POSITION) ---
              if (_showPlan)
                Column(
                  children: [
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _savePlan, // Call the new save function
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade600, // Distinct color for Save
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text(
                          "Save Plan", // New button text
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}