import 'package:flutter/material.dart';

class WeatherScreen extends StatefulWidget {
  final List<String> routeStops;
  const WeatherScreen({Key? key, required this.routeStops}) : super(key: key);

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController manualCityController = TextEditingController();

  List<String> routeStops = [];
  Map<String, Map<String, dynamic>> weatherData = {};

  @override
  void initState() {
    super.initState();
    routeStops = List.from(widget.routeStops);
    for (var city in routeStops) {
      fetchWeather(city);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    manualCityController.dispose();
    super.dispose();
  }

  // --- Utility Functions ---

  String getWeatherEmoji(String condition) {
    condition = condition.toLowerCase();
    if (condition.contains('sunny') || condition.contains('clear')) return '☀️';
    if (condition.contains('cloud')) return '☁️';
    if (condition.contains('rain') || condition.contains('drizzle')) return '🌧️';
    if (condition.contains('snow')) return '❄️';
    if (condition.contains('thunder')) return '⛈️';
    return '🌡️';
  }

  void _addCity(String city) {
    city = city.trim();
    if (city.isEmpty) return;

    if (!routeStops.contains(city)) {
      setState(() {
        routeStops.add(city);
      });
      fetchWeather(city);
      manualCityController.clear();
    }
  }

  // --- Weather Fetching Logic ---

  Future<void> fetchWeather(String city) async {
    if (!mounted) return;

    setState(() {
      weatherData[city] = {
        'temp': '0',
        'condition': 'Loading...',
        'humidity': '0',
      };
    });

    await Future.delayed(const Duration(milliseconds: 700));

    if (!mounted) return;

    setState(() {
      final conditions = ['Sunny', 'Cloudy', 'Rainy', 'Snow', 'Drizzle', 'Clear'];
      weatherData[city] = {
        'temp': (15 + city.length % 15).toString(),
        'condition': conditions.elementAt(city.length % conditions.length),
        'humidity': (50 + city.length % 30).toString(),
      };
    });

    final index = routeStops.indexOf(city);
    if (index >= 0 && _scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final targetPosition = index * 160.0;
        _scrollController.animateTo(
          targetPosition,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      });
    }
  }

  // --- UI Layout ---

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFEAF3FF),
      child: SingleChildScrollView(
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
                // Manual city input field
                TextField(
                  controller: manualCityController,
                  decoration: InputDecoration(
                    labelText: "Enter city manually",
                    hintText: "e.g., Singapore",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.add, color: Colors.indigo),
                      onPressed: () => _addCity(manualCityController.text),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  onSubmitted: _addCity,
                ),
                const SizedBox(height: 20),

                // Title for the list
                const Text(
                  "Route Stops Weather Forecast",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo,
                  ),
                ),
                const Divider(color: Colors.indigoAccent),

                // List of weather cards
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: routeStops.map((city) {
                    final data = weatherData[city];
                    final isLoaded = data != null && data['condition'] != 'Loading...';

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Container(
                        key: ValueKey(city),
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.indigo.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.indigo.shade100),
                        ),
                        // The main container is a Row to separate content and emoji
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // 1. Weather info and city name (Left side)
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    city,
                                    style: const TextStyle(
                                        fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 6),
                                  if (isLoaded)
                                    Column(
                                      // This ensures the details are left-aligned
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text("Temp: ${data['temp']}°C", style: const TextStyle(fontSize: 15)),
                                        Text("Condition: ${data['condition']}", style: const TextStyle(fontSize: 15)),
                                        Text("Humidity: ${data['humidity']}%", style: const TextStyle(fontSize: 15)),
                                      ],
                                    )
                                  else
                                    const Text(
                                      "Fetching weather...",
                                      style: TextStyle(color: Colors.indigo, fontStyle: FontStyle.italic),
                                    ),
                                ],
                              ),
                            ),
                            
                            // 2. Weather emoji/icon (Right side)
                            Container(
                              padding: const EdgeInsets.only(left: 12),
                              child: Text(
                                isLoaded
                                    ? getWeatherEmoji(data['condition'])
                                    : "⏳",
                                style: const TextStyle(fontSize: 40),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }
}