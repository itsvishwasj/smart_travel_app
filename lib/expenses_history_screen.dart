// expenses_history_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

class ExpensesHistoryScreen extends StatefulWidget {
  const ExpensesHistoryScreen({Key? key}) : super(key: key);

  @override
  State<ExpensesHistoryScreen> createState() =>
      _ExpensesHistoryScreenState();
}

class _ExpensesHistoryScreenState
    extends State<ExpensesHistoryScreen> {
  List<Map<String, dynamic>> _savedRecords = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> savedRecordsJson =
        prefs.getStringList('savedExpenseRecords') ?? [];

    final List<Map<String, dynamic>> loadedRecords = [];

    // newest first
    for (final jsonString in savedRecordsJson.reversed) {
      try {
        final dynamic decoded = jsonDecode(jsonString);

        if (decoded is Map) {
          loadedRecords.add(
            Map<String, dynamic>.from(decoded),
          );
        } else {
          print(
              'Skipping expense record: not a Map - $decoded');
        }
      } catch (e) {
        print(
            'Error decoding expense record JSON: $e');
      }
    }

    setState(() {
      _savedRecords = loadedRecords;
      _isLoading = false;
    });
  }

  // Delete record (and update SharedPreferences)
  Future<void> _deleteExpenseRecord(int index) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> savedRecordsJson =
        prefs.getStringList('savedExpenseRecords') ?? [];

    final int originalIndex =
        savedRecordsJson.length - 1 - index;

    if (originalIndex >= 0 &&
        originalIndex < savedRecordsJson.length) {
      savedRecordsJson.removeAt(originalIndex);
      await prefs.setStringList(
          'savedExpenseRecords', savedRecordsJson);

      setState(() {
        _savedRecords.removeAt(index);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              "Expense record deleted successfully."),
        ),
      );
    }
  }

  void _confirmDeleteRecord(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Confirm Delete"),
          content: const Text(
            "Are you sure you want to permanently delete this expense record?",
          ),
          actions: <Widget>[
            TextButton(
              child: const Text("Cancel"),
              onPressed: () =>
                  Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text(
                "Delete",
                style: TextStyle(color: Colors.red),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                _deleteExpenseRecord(index);
              },
            ),
          ],
        );
      },
    );
  }

  // Build one expense card (matches new structure from expense_tab.dart)
  Widget _buildExpenseCard(
      Map<String, dynamic> record, int index) {
    // ===== BASIC FIELDS =====
    final double total =
        (record['total'] as num?)?.toDouble() ?? 0.0;
    final int travelers =
        (record['travelers'] as num?)?.toInt() ?? 1;

    // Timestamp
    final String timestamp = record['timestamp'] != null
        ? DateFormat('MMM dd, yyyy - hh:mm a')
            .format(DateTime.parse(record['timestamp']))
        : 'Unknown Date';

    // Split data (safe cast)
    final dynamic splitRaw = record['split_data'];
    final Map<String, dynamic> splitData =
        splitRaw is Map
            ? Map<String, dynamic>.from(splitRaw)
            : <String, dynamic>{};

    final double equalShare =
        (splitData['Split Share per Traveler (Equal)']
                    as num?)
                ?.toDouble() ??
            0.0;
    final double sumShares =
        (splitData['Total Split Shares Sum (Items)']
                    as num?)
                ?.toDouble() ??
            0.0;

    // Trip details: either map or 'Manual Entry'
    final dynamic tripDetailsRaw = record['trip_details'];
    String tripName = 'Manual Entry';
    String tripDate = '-';
    String estimatedCost = '-';

    if (tripDetailsRaw is Map) {
      final map =
          Map<String, dynamic>.from(tripDetailsRaw);
      tripName = (map['name'] ?? 'Trip').toString();
      tripDate = (map['date'] ?? '-').toString();
      estimatedCost =
          (map['estimatedCost'] ?? '-').toString();
    }

    // Items list (safe)
    final List<dynamic> itemsRaw =
        (record['items'] as List?) ?? const [];
    final List<Map<String, dynamic>> items =
        itemsRaw
            .whereType<Map>()
            .map((m) => Map<String, dynamic>.from(m))
            .toList();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.all(20),
        title: Text(
          "Total Expense: ₹${total.toStringAsFixed(2)}",
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.indigo,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              "Date Saved: $timestamp",
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              tripDetailsRaw is String
                  ? "Trip: Manual Entry"
                  : "Trip: $tripName",
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(
            Icons.delete_forever,
            color: Colors.red,
          ),
          onPressed: () =>
              _confirmDeleteRecord(index),
          tooltip: 'Delete Record',
        ),
        children: <Widget>[
          Padding(
            padding:
                const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Divider(
                  color: Colors.grey,
                  thickness: 1,
                ),

                // Trip info (only if linked to a trip)
                if (tripDetailsRaw is! String)
                  Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Trip Route: $tripName",
                        style: TextStyle(
                          fontWeight:
                              FontWeight.w600,
                          color:
                              Colors.indigo.shade700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Trip Date: $tripDate",
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Estimated Trip Cost: $estimatedCost",
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.green.shade700,
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),

                // Travelers & split
                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Total Travelers:",
                      style: TextStyle(
                        fontWeight:
                            FontWeight.w600,
                        color:
                            Colors.indigo.shade700,
                      ),
                    ),
                    Text(
                      "$travelers",
                      style: const TextStyle(
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Equal Split (per traveler):",
                      style: TextStyle(
                        fontWeight:
                            FontWeight.w600,
                        color:
                            Colors.indigo.shade700,
                      ),
                    ),
                    Text(
                      "₹${equalShare.toStringAsFixed(2)}",
                      style: const TextStyle(
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Sum of Individual Shares:",
                      style: TextStyle(
                        fontWeight:
                            FontWeight.w600,
                        color:
                            Colors.deepOrange.shade700,
                      ),
                    ),
                    Text(
                      "₹${sumShares.toStringAsFixed(2)}",
                      style: TextStyle(
                        fontWeight:
                            FontWeight.w600,
                        color:
                            Colors.deepOrange.shade700,
                      ),
                    ),
                  ],
                ),

                const Divider(
                  height: 25,
                  color: Colors.indigo,
                  thickness: 1.5,
                ),
                const Text(
                  "Detailed Items:",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.indigo,
                  ),
                ),
                const SizedBox(height: 10),
                if (items.isEmpty)
                  const Text(
                    "No items recorded.",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  )
                else
                  ...items.map((item) {
                    final String name =
                        (item['item'] ?? '')
                            .toString();
                    final double amount =
                        (item['amount'] as num?)
                                ?.toDouble() ??
                            0.0;
                    final int splitMembers =
                        (item['splitMembers']
                                    as num?)
                                ?.toInt() ??
                            1;
                    final double perShare =
                        amount / (splitMembers == 0
                            ? 1
                            : splitMembers);

                    return Padding(
                      padding:
                          const EdgeInsets.symmetric(
                        vertical: 4.0,
                        horizontal: 8.0,
                      ),
                      child: Row(
                        mainAxisAlignment:
                            MainAxisAlignment
                                .spaceBetween,
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              "• $name\n  (split for $splitMembers member${splitMembers > 1 ? 's' : ''})",
                              style:
                                  const TextStyle(
                                fontSize: 14,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.end,
                            children: [
                              Text(
                                "₹${amount.toStringAsFixed(2)}",
                                style:
                                    const TextStyle(
                                  fontSize: 14,
                                  fontWeight:
                                      FontWeight
                                          .w600,
                                ),
                              ),
                              Text(
                                "₹${perShare.toStringAsFixed(2)}/share",
                                style:
                                    const TextStyle(
                                  fontSize: 12,
                                  color:
                                      Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }).toList(),
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
        title: const Text('Past Expense Records'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      backgroundColor: const Color(0xFFEAF3FF),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Colors.indigo,
              ),
            )
          : _savedRecords.isEmpty
              ? Center(
                  child: Padding(
                    padding:
                        const EdgeInsets.all(20.0),
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(20),
                      ),
                      elevation: 8,
                      child: Padding(
                        padding:
                            const EdgeInsets.all(30.0),
                        child: Column(
                          mainAxisSize:
                              MainAxisSize.min,
                          mainAxisAlignment:
                              MainAxisAlignment
                                  .center,
                          children: const [
                            Icon(
                              Icons.receipt_long,
                              size: 50,
                              color: Colors.indigo,
                            ),
                            SizedBox(height: 10),
                            Text(
                              'No past expense records found. Save a record from the Expenses tab first!',
                              textAlign:
                                  TextAlign.center,
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                )
              : ListView.builder(
                  padding:
                      const EdgeInsets.all(20.0),
                  itemCount: _savedRecords.length,
                  itemBuilder: (context, index) {
                    final record =
                        _savedRecords[index];
                    return _buildExpenseCard(
                        record, index);
                  },
                ),
    );
  }
}
