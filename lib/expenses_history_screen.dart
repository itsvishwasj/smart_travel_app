// expenses_history_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart'; 

class ExpensesHistoryScreen extends StatefulWidget {
  const ExpensesHistoryScreen({Key? key}) : super(key: key);

  @override
  State<ExpensesHistoryScreen> createState() => _ExpensesHistoryScreenState();
}

class _ExpensesHistoryScreenState extends State<ExpensesHistoryScreen> {
  List<Map<String, dynamic>> _savedRecords = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    final prefs = await SharedPreferences.getInstance();
    // Key used to save records in expense_tab.dart
    final List<String> savedRecordsJson = prefs.getStringList('savedExpenseRecords') ?? [];
    
    List<Map<String, dynamic>> loadedRecords = [];
    
    // Reverse for newest first display
    for (var jsonString in savedRecordsJson.reversed) { 
      try {
        final Map<String, dynamic> recordMap = jsonDecode(jsonString) as Map<String, dynamic>;
        loadedRecords.add(recordMap);
      } catch (e) {
        print('Error decoding expense record JSON: $e');
      }
    }

    setState(() {
      _savedRecords = loadedRecords;
      _isLoading = false;
    });
  }
  
  // NEW: Function to delete a record
  Future<void> _deleteExpenseRecord(int index) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> savedRecordsJson = prefs.getStringList('savedExpenseRecords') ?? [];
    
    // Calculate the index in the original list (since we display them reversed)
    final int originalIndex = savedRecordsJson.length - 1 - index; 

    if (originalIndex >= 0 && originalIndex < savedRecordsJson.length) {
      savedRecordsJson.removeAt(originalIndex);
      await prefs.setStringList('savedExpenseRecords', savedRecordsJson);
      
      setState(() {
        _savedRecords.removeAt(index);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Expense record deleted successfully.")),
      );
    }
  }

  // NEW: Confirmation Dialog for Delete
  void _confirmDeleteRecord(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Confirm Delete"),
          content: const Text("Are you sure you want to permanently delete this expense record?"),
          actions: <Widget>[
            TextButton(
              child: const Text("Cancel"),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text("Delete", style: TextStyle(color: Colors.red)),
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

  // Expense Card Builder (using ExpansionTile for details)
  Widget _buildExpenseCard(Map<String, dynamic> record, int index) {
    // Safely extract data
    final total = record['total']?.toStringAsFixed(2) ?? 'N/A';
    final members = record['members'] ?? '1';
    // perPerson is now saved as a string (as fixed in expense_tab.dart)
    final perPerson = record.containsKey('perPerson') ? record['perPerson'].toString() : 'N/A'; 
    final timestamp = record['timestamp'] != null 
        ? DateFormat('MMM dd, yyyy - hh:mm a').format(DateTime.parse(record['timestamp'])) 
        : 'Unknown Date';
    
    final List<dynamic> items = record['items'] as List<dynamic>? ?? [];

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.all(20),
        title: Text(
          "Total Expense: ₹$total",
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo),
        ),
        subtitle: Text(
          "Date: $timestamp",
          style: const TextStyle(fontSize: 14, color: Colors.black54),
        ),
        // NEW: Trailing is the Delete Button
        trailing: IconButton(
          icon: const Icon(Icons.delete_forever, color: Colors.red),
          onPressed: () => _confirmDeleteRecord(index),
          tooltip: 'Delete Record',
        ),
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(color: Colors.grey, thickness: 1),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Total Members:", style: TextStyle(fontWeight: FontWeight.w600, color: Colors.indigo.shade700)),
                    Text("$members", style: const TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 5),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Cost Per Person:", style: TextStyle(fontWeight: FontWeight.w600, color: Colors.indigo.shade700)),
                    Text("₹$perPerson", style: const TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
                const Divider(height: 25, color: Colors.indigo, thickness: 1.5),
                const Text("Detailed Items:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.indigo)),
                const SizedBox(height: 10),
                ...items.map((item) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("• ${item['item']}", style: const TextStyle(fontSize: 14)),
                        Text("₹${item['amount']?.toStringAsFixed(2) ?? 'N/A'}", style: const TextStyle(fontSize: 14)),
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
          ? const Center(child: CircularProgressIndicator(color: Colors.indigo))
          : _savedRecords.isEmpty
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
                            Icon(Icons.receipt_long, size: 50, color: Colors.indigo),
                            SizedBox(height: 10),
                            Text(
                              'No past expense records found. Save a record from the Expenses tab first!',
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
                  itemCount: _savedRecords.length,
                  itemBuilder: (context, index) {
                    final record = _savedRecords[index];
                    return _buildExpenseCard(record, index);
                  },
                ),
    );
  }
}