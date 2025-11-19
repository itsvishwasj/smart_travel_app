// expenses_history_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ExpensesHistoryScreen extends StatefulWidget {
  const ExpensesHistoryScreen({Key? key}) : super(key: key);

  @override
  State<ExpensesHistoryScreen> createState() =>
      _ExpensesHistoryScreenState();
}

class _ExpensesHistoryScreenState
    extends State<ExpensesHistoryScreen> {
  // Delete record from Firestore
  Future<void> _deleteExpenseRecord(String docId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('expenses')
          .doc(docId)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Expense record deleted successfully."),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to delete expense record: $e"),
        ),
      );
    }
  }

  void _confirmDeleteRecord(String docId) {
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
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text(
                "Delete",
                style: TextStyle(color: Colors.red),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                _deleteExpenseRecord(docId);
              },
            ),
          ],
        );
      },
    );
  }

  // Build one expense card (matches structure from updated expense_tab.dart)
  Widget _buildExpenseCard(
    Map<String, dynamic> record,
    String docId,
  ) {
    // ===== BASIC FIELDS =====
    final double total =
        (record['total'] as num?)?.toDouble() ?? 0.0;
    final int travelers =
        (record['travelers'] as num?)?.toInt() ?? 1;

    // Timestamp: prefer createdAt (Firestore), else fallback to 'timestamp' string
    String timestampLabel = 'Unknown Date';

    if (record['createdAt'] is Timestamp) {
      final ts = record['createdAt'] as Timestamp;
      timestampLabel =
          DateFormat('MMM dd, yyyy - hh:mm a').format(ts.toDate());
    } else if (record['timestamp'] != null) {
      try {
        timestampLabel = DateFormat('MMM dd, yyyy - hh:mm a')
            .format(DateTime.parse(record['timestamp'] as String));
      } catch (_) {
        timestampLabel = record['timestamp'].toString();
      }
    }

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
        (splitData['Total Split Shares Sum (Items)'] as num?)
                ?.toDouble() ??
            0.0;

    // Trip details: either map or 'Manual Entry'
    final dynamic tripDetailsRaw = record['trip_details'];
    String tripName = 'Manual Entry';
    String tripDate = '-';
    String estimatedCost = '-';

    if (tripDetailsRaw is Map) {
      final map = Map<String, dynamic>.from(tripDetailsRaw);
      tripName = (map['name'] ?? 'Trip').toString();
      tripDate = (map['date'] ?? '-').toString();
      estimatedCost = (map['estimatedCost'] ?? '-').toString();
    }

    // Items list (safe)
    final List<dynamic> itemsRaw =
        (record['items'] as List?) ?? const [];
    final List<Map<String, dynamic>> items = itemsRaw
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Date Saved: $timestampLabel",
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
          onPressed: () => _confirmDeleteRecord(docId),
          tooltip: 'Delete Record',
        ),
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(
                  color: Colors.grey,
                  thickness: 1,
                ),

                // Trip info (only if linked to a trip)
                if (tripDetailsRaw is! String)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Trip Route: $tripName",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.indigo.shade700,
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
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),

                // Travelers & split
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Total Travelers:",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.indigo.shade700,
                      ),
                    ),
                    Text(
                      "$travelers",
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Equal Split (per traveler):",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.indigo.shade700,
                      ),
                    ),
                    Text(
                      "₹${equalShare.toStringAsFixed(2)}",
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Sum of Individual Shares:",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.deepOrange.shade700,
                      ),
                    ),
                    Text(
                      "₹${sumShares.toStringAsFixed(2)}",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.deepOrange.shade700,
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
                        (item['item'] ?? '').toString();
                    final double amount =
                        (item['amount'] as num?)?.toDouble() ?? 0.0;
                    final int splitMembers =
                        (item['splitMembers'] as num?)?.toInt() ?? 1;
                    final double perShare =
                        amount / (splitMembers == 0 ? 1 : splitMembers);

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 4.0,
                        horizontal: 8.0,
                      ),
                      child: Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              "• $name\n  (split for $splitMembers member${splitMembers > 1 ? 's' : ''})",
                              style: const TextStyle(
                                fontSize: 14,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                "₹${amount.toStringAsFixed(2)}",
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                "₹${perShare.toStringAsFixed(2)}/share",
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.green,
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
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Past Expense Records'),
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
        ),
        backgroundColor: const Color(0xFFEAF3FF),
        body: const Center(
          child: Text(
            'Please log in to view your saved expense records.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final expensesQuery = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('expenses')
        .orderBy('createdAt', descending: true);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Past Expense Records'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      backgroundColor: const Color(0xFFEAF3FF),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: expensesQuery.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  'Error loading expense records:\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Colors.indigo,
              ),
            );
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 8,
                  child: Padding(
                    padding: const EdgeInsets.all(30.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(
                          Icons.receipt_long,
                          size: 50,
                          color: Colors.indigo,
                        ),
                        SizedBox(height: 10),
                        Text(
                          'No past expense records found. Save a record from the Expenses tab first!',
                          textAlign: TextAlign.center,
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
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20.0),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final record = doc.data();
              return _buildExpenseCard(record, doc.id);
            },
          );
        },
      ),
    );
  }
}
