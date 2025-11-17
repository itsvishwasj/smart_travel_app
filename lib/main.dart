// main.dart
import 'package:flutter/material.dart';
import 'dart:convert'; // Import for JSON handling
import 'package:url_launcher/url_launcher.dart'; 
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart'; 
import 'package:intl/intl.dart'; // For date formatting and current time

// NEW IMPORTS for Firebase Auth and Login Screen
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart'; // Ensure you have created this file

// NEW IMPORTS for Location Services (as requested)
import 'package:geolocator/geolocator.dart'; 
import 'package:geocoding/geocoding.dart'; 

import 'weather_screen.dart';
import 'expense_tab.dart'; 
import 'plans_history_screen.dart'; 
import 'expenses_history_screen.dart'; 

// --- NEW: Initialize Firebase in main() ---
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    // !!! IMPORTANT: You must configure Firebase for your platform
    // You might need to replace this with your actual Firebase options, e.g.,
    // await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform); 
    await Firebase.initializeApp(); 
  } catch (e) {
    print('Error initializing Firebase: $e');
  }
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
      // --- NEW: Start with the AuthWrapper to check login state ---
      home: const AuthWrapper(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// --- NEW WIDGET: AuthWrapper to handle routing based on login status ---
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // StreamBuilder listens to the user's authentication state
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Show a loading indicator while checking the auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        
        // If the user is logged in (User object is not null)
        if (snapshot.hasData && snapshot.data != null) {
          return const HomeScreen(); // Navigate to the main app screen
        }

        // Otherwise, show the Login screen
        return const LoginScreen();
      },
    );
  }
}
// --------------------------------------------------------------------------

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<String> routeStops = []; // shared with Weather tab
  
  // --- NEW: Logout Function ---
  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error signing out: $e')),
      );
    }
  }
  // ---------------------------

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
    // Get the current user's email if logged in
    final User? user = FirebaseAuth.instance.currentUser;
    final String userEmail = user?.email ?? 'user.name@example.com';

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
              UserAccountsDrawerHeader(
                accountName: const Text(
                  'Welcome, Traveler!',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
                ),
                accountEmail: Text(userEmail, style: const TextStyle(color: Colors.white70)),
                currentAccountPicture: const CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Icon(Icons.account_circle, size: 50, color: Colors.indigo),
                ),
                decoration: const BoxDecoration(
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
                leading: const Icon(Icons.history, color: Colors.indigo), 
                title: const Text('History', style: TextStyle(color: Colors.indigo)),
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

              // LOGOUT OPTION
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red), // Use red for logout
                title: const Text('Logout', style: TextStyle(color: Colors.red)), 
                onTap: () {
                  Navigator.of(context).pop(); // Close the drawer first
                  _logout(); // Call the Firebase logout function
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

// PlanTab Implementation (REST OF YOUR CODE REMAINS UNCHANGED)
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
  final TextEditingController daysController = TextEditingController();
  final TextEditingController travellersController = TextEditingController();
  
  // NEW: FocusNode for 'From' TextField to track focus state
  final FocusNode _fromFocusNode = FocusNode();

  // UPDATED: BUDGET SLIDER NEW STATE (Range 0.0 to 11.0)
  double _budgetSliderValue = 5.0; // Default to mid-range
  // Use this as the primary controller for display, initialized with the default slider value
  // We use a helper function to determine the display text
  final TextEditingController budgetController = TextEditingController(text: 'Mid Budget'); 

  String? selectedVehicle;
  
  // New state variables for AI integration
  bool _isLoading = false;
  Map<String, dynamic>? _generatedPlan;
  bool get _showPlan => _generatedPlan != null; // Use a getter based on the plan data

  final ScrollController _scrollController = ScrollController();
  
  // State for location button visibility
  bool _isLocating = false; // To show a loading indicator on the location button

  // --- Date State Variables and Logic ---
  DateTime? _startDate; 
  String _startDateString = 'Select Start Date'; 

  // Helper to convert the 0-11 slider value into a qualitative budget string
  String _getBudgetLevel(double value) {
    if (value >= 8) {
      return 'High Budget';
    } else if (value >= 4) {
      return 'Mid Budget';
    } else {
      return 'Low Budget';
    }
  }

  // Function to show the date picker dialog
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime.now(), // Cannot select a date before today
      lastDate: DateTime(2030), // Limit to 2030 for now
    );
    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
        // Format the date for display
        _startDateString = DateFormat('EEE, MMM d, yyyy').format(picked);
      });
    }
  }

  // Helper to determine if a date is a weekend/weekday
  String _getDayType(DateTime date) {
    // DateTime.saturday is 6, DateTime.sunday is 7
    if (date.weekday == DateTime.saturday || date.weekday == DateTime.sunday) {
      return 'Weekend';
    }
    return 'Weekday';
  }
  // --- END Date State Variables and Logic ---

  // --- NEW: Location Functions Implementation ---
  
  @override
  void initState() {
    super.initState();
    // Listener to rebuild the widget when the 'From' field changes (for button visibility)
    fromController.addListener(_onFromChanged);
    // Listener to rebuild the widget when the focus of the 'From' field changes
    _fromFocusNode.addListener(_onFocusChanged);
  }

  void _onFromChanged() {
    // We call setState to potentially show/hide the location button
    setState(() {});
  }
  
  void _onFocusChanged() {
    // We call setState to potentially show/hide the location button
    setState(() {});
  }

  // Function to get current location and update the 'From' field
  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLocating = true;
    });

    try {
      // 1. Check/Request Permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
          throw Exception('Location permissions are denied. Please enable them in settings.');
        }
      }

      // 2. Get Position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high
      );

      // 3. Reverse Geocode (Convert Lat/Long to Address)
      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      
      String address = 'Unknown Location';
      if (placemarks.isNotEmpty) {
        final Placemark place = placemarks.first;
        // Construct a clean, human-readable address: City, State/Region, Country
        address = [place.locality, place.administrativeArea, place.country]
            .where((element) => element != null && element.isNotEmpty)
            .join(', ');
      }

      // 4. Update TextField
      fromController.text = address;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Location set to: $address')),
      );

    } catch (e) {
      // Handle any errors (permissions, service disabled, geocoding failure)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error getting location: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLocating = false;
      });
    }
  }
  // --- END Location Functions Implementation ---


  // --- GEMINI API CONSTANTS AND IMPLEMENTATION ---
  final String _apiKey = 'AIzaSyC2gkLJ-pDwn4LMH9E3zRRgCj9GKu0AwR4'; // User provided API key

  // UPDATED: JSON schema for structured output to include estimatedTotalCost
  final String _jsonSchemaTemplate = r'''
{
  "estimatedTotalCost": "A single string containing the estimated total cost for the trip in INR, e.g., '₹35,000 - ₹40,000' or 'INR 50,000 (Low Estimate)'.", 
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
    fromController.removeListener(_onFromChanged); // REMOVE LISTENER
    fromController.dispose();
    _fromFocusNode.removeListener(_onFocusChanged); // REMOVE FOCUS LISTENER
    _fromFocusNode.dispose(); // DISPOSE FOCUS NODE
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
    // CORRECTED URL: The previous URL was incorrect. This is a common standard search link.
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
      // Reset the budget slider and controller text to default 'Mid Budget'
      _budgetSliderValue = 5.0; 
      budgetController.text = _getBudgetLevel(_budgetSliderValue);
      daysController.clear();
      travellersController.clear();
      selectedVehicle = null;
      _startDate = null; // Clear the start date
      _startDateString = 'Select Start Date'; // Reset display string
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
    // Use the qualitative budget level from the slider
    final String budget = _getBudgetLevel(_budgetSliderValue); 
    final String vehicle = selectedVehicle ?? 'Car'; // Default to Car
    
    // Date Context Logic
    String dayType = 'Weekday';
    String dateInfo = '';
    if (_startDate != null) {
      dayType = _getDayType(_startDate!);
      String tripStartDate = DateFormat('EEE, MMM d, yyyy').format(_startDate!);
      dateInfo = 
          'The trip starts on the specific date: $tripStartDate, which falls on a $dayType. Please structure the plan and activities, especially pricing for accommodation, to reflect if it is a $dayType (e.g., higher prices on weekends).';
    } else {
      dateInfo = 'The trip date is not specified. Assume a generic weekday starting 3 days from the current time.';
    }


    // 2. Prepare CRITICAL INSTRUCTIONS (Logic)

    // NEW: Instruction for the estimated budget calculation
    final String budgetEstimationInstruction = '''
    Calculate a realistic **Estimated Total Cost** for this entire trip (accommodation, fuel/charge, and food/activities) in Indian Rupees (INR). 
    This estimate must be based on:
    - The qualitative budget level: **$budget**.
    - The number of travelers: $members.
    - The duration: $days days.
    - The vehicle type: $vehicle.
    - The date type: $dayType (Weekend costs are typically higher).
    - The route distance (which you must estimate yourself based on $start to $end).
    The result must be a single string in the format: '₹X,XXX - ₹Y,YYY' and be placed in the new 'estimatedTotalCost' field.
    ''';
    
    final int numMembers = int.tryParse(members) ?? 2;
    final int numRooms = (numMembers / 2).ceil();

    // UPDATED: Accommodation logic to use the qualitative budget level
    final String accommodationLogic = "The $numMembers travelers will likely need about $numRooms room(s). Based on the chosen **$budget** level, find appropriate accommodation recommendations (e.g., cost-effective hostels for 'Low Budget', 4-star hotels for 'High Budget'). Crucially, recommend accommodation in less expensive outskirts or satellite areas near the route's mid-points to save budget for the final destination. Ensure the recommendations are tailored to a $dayType.";

    String stopLogic;
    if (vehicle.toLowerCase().contains('ev')) {
      stopLogic = "Recommend **specific EV charging stations** (e.g., Electrify America) and ensure they are well-spaced for an EV's range.";
    } else {
      stopLogic = "Recommend **specific fuel stops** (e.g., Shell, BP) and major rest areas, ensuring they are well-spaced for a standard vehicle.";
    }

    // Smart Advisor Logic
    final String smartAdvisorLogic = '''
    Generate a list of at least five highly practical tips for the 'smartAdvisorTips' array. The focus MUST be only on the road trip itself, from the start point to the end point, and NOT on activities once the destination is reached.

    The required tips are:
    1.  **Vehicle Suitability:** Heading 'Vehicle Choice Analysis'. Tip must state whether the chosen $vehicle is ideal for the $start to $end road trip based on traffic, road conditions, and distance, and specifically mention: **'Use bikes to avoid traffic, use cars in rainy weather.'**
    2.  **Fuel Minimization:** Heading 'Fuel Expense Minimizer'. Tip must give a specific driving technique or route strategy to minimize fuel/EV charge costs *on this particular route*, tailored to the **$vehicle**.
    3.  **Food Minimization:** Heading 'On-Road Food Budget'. Tip must suggest practical ways to minimize food spending *during the drive*, tailored to the **$budget** level.
    4.  **Weather/Route Safety:** Heading 'Monsoon/Rain Safety Route'. Suggest a specific alternative route or section to avoid known water-logging or high-traffic areas during heavy rain, saving time and fuel.
    5.  **Traffic Avoidance:** Heading 'Traffic & Timing'. Suggest the best time of day (e.g., 'start at 4 AM') or a specific small detour to bypass the worst traffic congestion on the route.
    ''';

    // 3. Construct the Final Prompt (NOW WITH BUDGET CALCULATION)
    final String finalPrompt = '''
      You are a specialized road trip planning AI. Your task is to generate a comprehensive road trip plan for a $days-day journey from $start to $end.
      The traveler is interested in: $interests.
      The travel party consists of $members members with a total trip budget level of **$budget**.
      They are traveling in a $vehicle.

      **CRITICAL INSTRUCTIONS (MUST FOLLOW):**
      1.  **BUDGET ESTIMATION (CRITICAL):** $budgetEstimationInstruction
      2.  **ITINERARY and TOURIST STOPS:** The plan must include a logical sequence of stops and at least 3-5 must-see tourist attractions relevant to the user's interests. This should focus on stops ALONG THE ROUTE, not activities at the final destination. The plan must be fully tailored to the **$budget** level.
      3.  **DATE CONSTRAINT:** $dateInfo
      4.  **ACCOMMODATION RULE:** $accommodationLogic
      5.  **STOP RULE:** $stopLogic
      6.  **SMART ADVISOR RULE (CRITICAL FOCUS):** $smartAdvisorLogic

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
    // Get the current date and time for the 'Plan Generated' stamp
    final now = DateTime.now();
    final formattedNow = DateFormat('MMM d, yyyy - hh:mm a').format(now);

    // Get the selected trip start date string
    final String tripStartDateText = _startDate != null 
        ? DateFormat('EEE, MMM d, yyyy').format(_startDate!) 
        : 'Not Specified (Assumed Weekday)'; 
        
    // Logic to determine if the "Use current location" button should be visible
    final bool showCurrentLocationOption = fromController.text.isEmpty && !_fromFocusNode.hasFocus;
        
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
                focusNode: _fromFocusNode, // Assign the FocusNode
                decoration: InputDecoration(
                  labelText: "From",
                  hintText: "e.g., Bengaluru",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                ),
              ),
              
              // --- NEW: Use Current Location Option ---
              if (showCurrentLocationOption)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: GestureDetector(
                    onTap: _isLocating ? null : _getCurrentLocation,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _isLocating 
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.indigo,
                              ),
                            )
                          : Icon(
                              Icons.my_location, 
                              color: Colors.indigo.shade700, 
                              size: 18
                            ),
                        const SizedBox(width: 8),
                        Text(
                          _isLocating ? 'Locating...' : 'Use current location',
                          style: TextStyle(
                            color: Colors.indigo.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              // --- END NEW: Use Current Location Option ---
              
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
              
              // --- BUDGET SLIDER INPUT SECTION (UPDATED FOR 0-11 SCALE) ---
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Text Field to display the current qualitative budget value
                  TextField(
                    controller: budgetController,
                    readOnly: true, // Make it read-only since the slider controls the value
                    decoration: InputDecoration(
                      labelText: "Budget Level",
                      hintText: "Mid Budget",
                      prefix: const Text('Budget: '),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                  ),
                  
                  // Slider (0 to 11, 11 divisions)
                  Slider(
                    value: _budgetSliderValue,
                    min: 0.0,
                    max: 11.0,
                    divisions: 11, 
                    label: _budgetSliderValue.round().toString(),
                    onChanged: (double newValue) {
                      setState(() {
                        _budgetSliderValue = newValue;
                        // Update the text field to reflect the new qualitative budget level
                        budgetController.text = _getBudgetLevel(_budgetSliderValue);
                      });
                    },
                  ),
                  
                  // Label for the slider range
                  Padding(
                    padding: const EdgeInsets.only(left: 12.0, right: 12.0, bottom: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text('Low (0)', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        Text('Mid (5-7)', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        Text('High (11)', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                ],
              ),
              // --- END BUDGET SLIDER INPUT SECTION ---

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
              
              // --- Trip Start Date Input (Neutral Style) ---
              const SizedBox(height: 16), 
              GestureDetector(
                onTap: () => _selectDate(context),
                child: Container(
                  height: 60,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _startDateString == 'Select Start Date' ? 'Start Date' : 'Start Date: ${_startDateString}',
                        style: TextStyle(
                          fontSize: 16,
                          color: _startDateString == 'Select Start Date' ? Colors.grey.shade600 : Colors.black,
                        ),
                      ),
                      const Icon(Icons.calendar_today, color: Colors.grey),
                    ],
                  ),
                ),
              ),
              // --- END Trip Start Date Input ---
              
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
                      // 1. Summary Title
                      Text(
                        "Trip Plan from ${fromController.text} to ${toController.text}",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                      ),
                      
                      // --- NEW: Estimated Budget Section (Green colored) ---
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
                        child: Text(
                          '💰 Estimated Total Cost: ${_generatedPlan!['estimatedTotalCost']}',
                          style: TextStyle(
                              fontSize: 17, 
                              fontWeight: FontWeight.bold, 
                              color: Colors.green.shade700
                          ),
                        ),
                      ),
                      // --- END Estimated Budget Section ---

                      // --- Plan Date Info Section ---
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0, bottom: 10.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '🗓️ Trip Start Date: $tripStartDateText',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.indigo.shade700),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '🕒 Plan Generated: $formattedNow',
                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                            const Divider(height: 20),
                          ],
                        ),
                      ),
                      // --- END Plan Date Info Section ---

                      // 2. Summary
                      Text(
                        _generatedPlan!['itinerarySummary'] as String,
                        style: const TextStyle(fontSize: 15, fontStyle: FontStyle.italic),
                      ),
                      
                      // 3. Directions/Route Stops
                      _buildPlanSection(
                        "🚗 Recommended Route:", 
                        _generatedPlan!['routeStops'] as List<dynamic>, 
                        isRoute: true,
                      ),

                      // 4. Tourist Stops
                      _buildPlanSection(
                        "📸 Must-See Tourist Stops (Click to Map):", 
                        _generatedPlan!['touristStops'] as List<dynamic>,
                      ),

                      // 5. Hotel Recommendations
                      _buildPlanSection(
                        "🏨 Hotel Recommendations (Click to Map):", 
                        _generatedPlan!['hotelRecommendations'] as List<dynamic>,
                      ),

                      // 6. Fuel/Rest Stops
                      _buildPlanSection(
                        "⛽ Service Stops (Click to Map):", 
                        _generatedPlan!['stopRecommendations'] as List<dynamic>,
                      ),
                      
                      const SizedBox(height: 24),
                      // 7. Smart Advisor Tips (NEW SECTION)
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