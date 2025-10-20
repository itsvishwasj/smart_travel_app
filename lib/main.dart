import 'package:flutter/material.dart';
import 'weather_screen.dart';
import 'expense_tab.dart'; // 👈 1. Import the new ExpenseTab

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Travel Assistant',
      theme: ThemeData(primarySwatch: Colors.indigo),
      home: HomeScreen(), // Directly open main app
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<String> routeStops = []; // shared with Weather tab

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
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Logout tapped")),
                );
              },
            ),
          ],
          bottom: const TabBar(
            labelColor: Colors.indigo,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.indigo,
            tabs: [
              Tab(text: "Plan"),
              Tab(text: "Weather"),
              Tab(text: "Expenses"), // Renamed "Expense" to "Expenses" for clarity
            ],
          ),
        ),
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
            const ExpenseTab(), // 👈 2. Replaced placeholder with ExpenseTab
          ],
        ),
      ),
    );
  }
}

class PlanTab extends StatefulWidget {
  final Function(List<String>) onRouteUpdate; // callback to send routeStops to HomeScreen
  const PlanTab({Key? key, required this.onRouteUpdate}) : super(key: key);

  @override
  State<PlanTab> createState() => _PlanTabState();
}

class _PlanTabState extends State<PlanTab> {
  // Sample data
  final List<Map<String, String>> hotels = [
    {"name": "Budget Stay", "price": "₹1500"},
    {"name": "Comfort Inn", "price": "₹3000"},
  ];

  final List<String> fuels = [
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
        routeStops = [
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
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Smart plan generated!')),
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
                    child: DropdownButtonFormField<String>(
                      value: selectedVehicle,
                      decoration: InputDecoration(
                        labelText: "Vehicle",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      items: ['Bike 🏍️', 'Car 🚗', 'EV 🔋']
                          .map(
                            (vehicle) => DropdownMenuItem(
                              value: vehicle,
                              child: Text(vehicle),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedVehicle = value;
                        });
                      },
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
                          )),
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
                          )),
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
            ],
          ),
        ),
      ),
    );
  }
}