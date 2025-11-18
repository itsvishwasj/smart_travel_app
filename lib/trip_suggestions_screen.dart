import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TripSuggestionsScreen extends StatefulWidget {
  const TripSuggestionsScreen({super.key});

  @override
  State<TripSuggestionsScreen> createState() => _TripSuggestionsScreenState();
}

class _TripSuggestionsScreenState extends State<TripSuggestionsScreen> {
  String? _selectedTripId;
  Map<String, dynamic>? _selectedTripData;
  bool _loading = false;

  List<Map<String, dynamic>> _tripExpenses = [];

  // ------------ Calculation Helpers ------------

  double _totalAmount() {
    return _tripExpenses.fold(
      0,
      (sum, e) => sum + (e['amount'] as num).toDouble(),
    );
  }

  Map<String, double> _amountByCategory() {
    final map = <String, double>{};

    for (final e in _tripExpenses) {
      final cat = e['category'] ?? 'Other';
      final amt = (e['amount'] as num).toDouble();
      map[cat] = (map[cat] ?? 0) + amt;
    }

    return map;
  }

  MapEntry<String, double>? _topCategory() {
    final byCat = _amountByCategory();
    if (byCat.isEmpty) return null;
    return byCat.entries.reduce((a, b) => a.value >= b.value ? a : b);
  }

  double _averagePerDay() {
    final total = _totalAmount();
    final start = (_selectedTripData!['startDate'] as Timestamp).toDate();
    final end = (_selectedTripData!['endDate'] as Timestamp).toDate();

    final days = end.difference(start).inDays + 1;
    return total / days;
  }

  double _nextTripSuggestion() {
    return _averagePerDay() * 1.1; // 10% buffer
  }

  // ------------ Load Expenses for Selected Trip ------------

  Future<void> _loadTripExpenses() async {
    setState(() => _loading = true);

    final uid = FirebaseAuth.instance.currentUser!.uid;

    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('expenses')
        .where('tripId', isEqualTo: _selectedTripId)
        .get();

    _tripExpenses = snap.docs.map((doc) {
      final data = doc.data();
      return {
        'id': doc.id,
        'amount': data['amount'] ?? 0,
        'category': data['category'] ?? 'Other',
        'date': (data['date'] as Timestamp).toDate(),
      };
    }).toList();

    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Trip Suggestions"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ---------------- Trip Picker ----------------
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .collection('trips') // change to 'plans' if needed
                  .orderBy('startDate', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final trips = snapshot.data!.docs;

                if (trips.isEmpty) {
                  return const Text(
                    "No trips found. Create a trip first.",
                    style: TextStyle(fontStyle: FontStyle.italic),
                  );
                }

                return DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: "Select Trip",
                    border: OutlineInputBorder(),
                  ),
                  value: _selectedTripId,
                  items: trips.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final name = data['name'] ?? 'Unnamed Trip';
                    final start =
                        (data['startDate'] as Timestamp).toDate();
                    final end =
                        (data['endDate'] as Timestamp).toDate();

                    final label =
                        "$name (${start.day}/${start.month} - ${end.day}/${end.month})";

                    return DropdownMenuItem(
                      value: doc.id,
                      child: Text(label),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedTripId = value;
                      _selectedTripData = snapshot.data!.docs
                          .firstWhere((d) => d.id == value)
                          .data() as Map<String, dynamic>;
                    });
                    _loadTripExpenses();
                  },
                );
              },
            ),

            const SizedBox(height: 16),

            // ---------------- Suggestions ----------------
            if (_selectedTripId == null)
              const Text(
                "Select a trip to view personalized suggestions.",
                style: TextStyle(fontStyle: FontStyle.italic),
              )
            else if (_loading)
              const CircularProgressIndicator()
            else if (_tripExpenses.isEmpty)
              const Text(
                "No expenses recorded for this trip.",
                style: TextStyle(fontStyle: FontStyle.italic),
              )
            else
              Expanded(child: _buildSuggestions()),
          ],
        ),
      ),
    );
  }

  // ---------------- Suggestions UI ----------------

  Widget _buildSuggestions() {
    final total = _totalAmount();
    final topCat = _topCategory();
    final avgDay = _averagePerDay();
    final suggestion = _nextTripSuggestion();

    return ListView(
      children: [
        Card(
          child: ListTile(
            title: const Text("Total Spent"),
            subtitle: Text("₹${total.toStringAsFixed(0)}"),
          ),
        ),
        if (topCat != null)
          Card(
            child: ListTile(
              title: const Text("Most Spent Category"),
              subtitle:
                  Text("${topCat.key} – ₹${topCat.value.toStringAsFixed(0)}"),
            ),
          ),
        Card(
          child: ListTile(
            title: const Text("Average Spend Per Day"),
            subtitle: Text("₹${avgDay.toStringAsFixed(0)}"),
          ),
        ),
        Card(
          child: ListTile(
            title: const Text("Suggested Budget (Next Trip)"),
            subtitle: Text(
              "₹${suggestion.toStringAsFixed(0)} per day\n(10% higher than your last trip)",
            ),
          ),
        ),
      ],
    );
  }
}
