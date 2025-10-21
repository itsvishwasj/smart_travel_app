import 'package:flutter/material.dart';
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

              // NEW LOGOUT OPTION ADDED HERE (COLOR CHANGED TO INDIGO)
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

// PlanTab Implementation (from Code 2)
class PlanTab extends StatefulWidget {
  final Function(List<String>) onRouteUpdate; // callback to send routeStops to HomeScreen
  const PlanTab({Key? key, required this.onRouteUpdate}) : super(key: key);

  @override
  State<PlanTab> createState() => _PlanTabState();
}

class _PlanTabState extends State<PlanTab> {
  // Sample data
  final List<Map<String, String>> hotels = const [
    {"name": "Budget Stay", "price": "₹1500"},
    {"name": "Comfort Inn", "price": "₹3000"},
  ];

  final List<String> fuels = const [
    "Shell Petrol Pump near midway point",
    "Indian Oil Station near highway exit",
    "HP Petrol Bunk before destination",
  ];

  final String safeRoute =
      "Recommended safe route from Bengaluru to Goa:\n- Take NH44 or NH48 for better road quality.\n- Avoid isolated forest routes at night.\n- Keep emergency numbers handy.";

  // Controllers for input fields
  final TextEditingController fromController = TextEditingController();
  final TextEditingController toController = TextEditingController();
  final TextEditingController budgetController = TextEditingController();
  final TextEditingController daysController = TextEditingController();
  final TextEditingController travellersController = TextEditingController();

  String? selectedVehicle;
  bool _showPlan = false;
  List<String> routeStops = [];

  final ScrollController _scrollController = ScrollController();
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

  // Helper function to simulate opening Google Maps
  Future<void> _openMap(BuildContext context, String query) async {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text("Would open Google Maps for $query")));
  }

  // Method to reset the entire plan form
  void _resetPlan() {
    setState(() {
      // 1. Clear text input fields
      fromController.clear();
      toController.clear();
      budgetController.clear();
      daysController.clear();
      travellersController.clear();

      // 2. Reset state variables
      selectedVehicle = null;
      _showPlan = false;
      routeStops = [];
      
      // 3. Notify HomeScreen to clear weather stops
      widget.onRouteUpdate([]);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Plan reset. Start a new trip!')),
    );
  }

  // Generate travel plan logic
  void _generatePlan() {
    if (fromController.text.isEmpty || toController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter both From and To locations")),
      );
      return;
    }

    setState(() {
      _showPlan = true;

      if (fromController.text.toLowerCase().contains("bengaluru") &&
          toController.text.toLowerCase().contains("goa")) {
        routeStops = const [
          "Bengaluru",
          "Tumkur",
          "Chitradurga",
          "Hubli",
          "Karwar",
          "Goa",
        ];
      } else {
        routeStops = [
          fromController.text,
          "Midway Point 1",
          "Midway Point 2",
          toController.text,
        ];
      }

      // Send routeStops to HomeScreen for Weather tab
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
      const SnackBar(content: Text('Smart plan generated!')),
    );
  }

  // METHOD: Show the modal radio button selection dialog
  void _showVehicleSelectionDialog(BuildContext context) {
    String? tempSelected = selectedVehicle;
    // Define vehicles with separate text and emoji for styling
    final List<Map<String, String>> vehicles = const [
      {'name': 'Bike', 'emoji': '🏍️'},
      {'name': 'Car', 'emoji': '🚗'},
      {'name': 'EV', 'emoji': '🔋'},
    ];
    
    // Define the font size for the large emoji
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
                  // The value stored in selectedVehicle and passed around
                  final String value = '${vehicleMap['name']} ${vehicleMap['emoji']}';
                  
                  return RadioListTile<String>(
                    // Build the title using a Row for custom text and emoji sizes
                    title: Row(
                      children: [
                        Text(
                          vehicleMap['name']!,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(width: 8),
                        // Use a Text widget with increased font size for the emoji
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
                    // Return the selected value and close the dialog
                    Navigator.of(context).pop(tempSelected);
                  },
                ),
              ],
            );
          },
        );
      },
    ).then((result) {
      // Update the main state after the dialog is closed
      if (result != null) {
        setState(() {
          selectedVehicle = result;
        });
      }
    });
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
              // Input fields start here
              TextField(
                controller: fromController,
                decoration: InputDecoration(
                  labelText: "From",
                  hintText: "e.g., Bengaluru",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: toController,
                decoration: InputDecoration(
                  labelText: "To",
                  hintText: "e.g., Goa",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: budgetController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "Budget",
                  hintText: "e.g., 5000",
                  prefix: const Text('₹ '),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    // Vehicle Selection: Replaced DropdownButtonFormField with custom input and dialog trigger
                    child: GestureDetector(
                      onTap: () => _showVehicleSelectionDialog(context),
                      child: Container(
                        height: 60, // Match height of TextField
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
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
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
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                ),
              ),
              const SizedBox(height: 26),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _generatePlan,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "Generate Smart Plan",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
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
                      Text(
                        "Here's your smart travel plan from ${fromController.text} to ${toController.text}!",
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        "Vehicle Selected: ${selectedVehicle ?? 'Not selected'}",
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 16),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        "Number of Days: ${daysController.text.isEmpty ? 'Not specified' : daysController.text}",
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 16),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        "Number of Travellers: ${travellersController.text.isEmpty ? 'Not specified' : travellersController.text}",
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 16),
                      ),
                      const SizedBox(height: 18),
                      const Text("🏨 Hotels:",
                          style: TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 16)),
                      ...hotels.map((hotel) => GestureDetector(
                            onTap: () => _openMap(context, hotel["name"]!),
                            child: Padding(
                              padding: const EdgeInsets.only(left: 14, top: 10),
                              child: Text(
                                "• ${hotel["name"]} — ${hotel["price"]}",
                                style: TextStyle(
                                    color: Colors.indigo.shade700,
                                    fontSize: 15,
                                    decoration: TextDecoration.underline),
                              ),
                            ),
                          )).toList(),
                      const SizedBox(height: 24),
                      const Text("⛽ Fuel Stops:",
                          style: TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 16)),
                      ...fuels.map((fuel) => GestureDetector(
                            onTap: () => _openMap(context, fuel),
                            child: Padding(
                              padding: const EdgeInsets.only(left: 14, top: 10),
                              child: Text(
                                "• $fuel",
                                style: TextStyle(
                                    color: Colors.indigo.shade700,
                                    fontSize: 15,
                                    decoration: TextDecoration.underline),
                              ),
                            ),
                          )).toList(),
                      const SizedBox(height: 24),
                      const Text("🛣️ Safe Route:",
                          style: TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 16)),
                      Padding(
                        padding: const EdgeInsets.only(left: 14, top: 10),
                        child: Text(safeRoute,
                            style: const TextStyle(fontSize: 15)),
                      ),
                      const SizedBox(height: 24),
                      const Text("🚗 Directions:",
                          style: TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 16)),
                      Padding(
                        padding: const EdgeInsets.only(left: 14, top: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: routeStops.map((stop) {
                            final index = routeStops.indexOf(stop);
                            final isLast = index == routeStops.length - 1;
                            return Text(isLast ? "• $stop" : "• $stop →",
                                style: const TextStyle(fontSize: 15));
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
            
              // Clear Plan Button (Conditional)
              if (_showPlan)
                Column(
                  children: [
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _resetPlan,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal.shade600,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          "Clear Plan",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10), // Add some padding at the bottom
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}