import 'package:flutter/material.dart';

class PlansHistoryScreen extends StatelessWidget {
  const PlansHistoryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Past Trip Plans'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      backgroundColor: const Color(0xFFEAF3FF), // Light blue background
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0), // Padding around the card
          child: Card( // White Card with curved edges and elevation
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            elevation: 8,
            child: Padding(
              padding: const EdgeInsets.all(30.0), // Padding inside the card
              child: Column(
                mainAxisSize: MainAxisSize.min, // Keep the card height minimal
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.history_toggle_off, size: 50, color: Colors.indigo), // Consistent branding color
                  SizedBox(height: 10),
                  Text(
                    'History of past trip plans will be shown here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}