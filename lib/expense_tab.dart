// expense_tab.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // For local storage
import 'dart:convert'; // For JSON encoding

class ExpenseTab extends StatefulWidget {
  const ExpenseTab({Key? key}) : super(key: key);

  @override
  State<ExpenseTab> createState() => _ExpenseTabState();
}

class ExpenseItem {
  final String item;
  final double amount;

  ExpenseItem(this.item, this.amount);

  // Convert ExpenseItem to a Map for JSON encoding
  Map<String, dynamic> toJson() => {
        'item': item,
        'amount': amount,
      };
}

class _ExpenseTabState extends State<ExpenseTab> {
  final TextEditingController _itemController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _membersController = TextEditingController();

  // Color Definitions
  final Color _primaryButtonColor = const Color(0xFF928FD2);    // Add and Reset Button Color: #928FD2
  final Color _clearButtonColor = const Color(0xFF7672CB);      // End Clear Button Color: #7672CB
  final Color _indigoColor = Colors.indigo.shade600;            

  // State variables
  List<ExpenseItem> _expenses = []; 
  
  // UPDATED: Function to save the current expense list with full metadata
  void _saveExpenses() async {
    if (_expenses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No expenses to save.")),
      );
      return;
    }
    
    // Calculate values based on current state
    final int membersCount = int.tryParse(_membersController.text) ?? 1;
    final double total = _totalAmount;
    final double perPerson = _perPersonAmount;

    // 1. Prepare the complete historical record
    final Map<String, dynamic> recordMetadata = {
      'timestamp': DateTime.now().toIso8601String(), // Add timestamp
      'members': membersCount,
      'total': total,
      'perPerson': perPerson.toStringAsFixed(2), // Save as string for precision
      'items': _expenses.map((e) => e.toJson()).toList() // Detailed items list
    };
    
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // *** FIX: Use the correct key 'savedExpenseRecords' matching the history screen ***
      final List<String> savedRecordsJson = prefs.getStringList('savedExpenseRecords') ?? [];
      
      // 2. Add the new record (as a single JSON string)
      savedRecordsJson.add(jsonEncode(recordMetadata));
      
      // 3. Save the updated list
      await prefs.setStringList('savedExpenseRecords', savedRecordsJson);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Expenses saved successfully to history!")),
      );
      
      // Clear current expense list after saving
      setState(() {
        _expenses.clear();
        // Keep membersController value for next entry, as it's common to reuse
      });

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error saving expenses: $e")),
      );
    }
  }
  
  // --- Logic Functions ---

  // Variable for calculation (default to 1 member)
  double get _totalAmount {
    return _expenses.fold(0.0, (sum, item) => sum + item.amount);
  }

  double get _perPersonAmount {
    int members = int.tryParse(_membersController.text) ?? 1;
    return _totalAmount / (members > 0 ? members : 1);
  }

  void _addExpense() {
    final item = _itemController.text;
    final amountText = _amountController.text;

    if (item.isEmpty || amountText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter both item and amount")),
      );
      return;
    }

    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid amount")),
      );
      return;
    }

    setState(() {
      _expenses.add(ExpenseItem(item, amount));
      _itemController.clear();
      _amountController.clear();
    });
  }

  void _removeExpense(int index) {
    setState(() {
      _expenses.removeAt(index);
    });
  }

  void _resetExpenses() {
    setState(() {
      _expenses.clear();
      _membersController.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Current expense list cleared.")),
    );
  }

  // --- Widget Builders ---
  
  Widget _buildInputSection() {
    return Column(
      children: [
        TextField(
          controller: _itemController,
          decoration: InputDecoration(
            labelText: "Expense Item",
            hintText: "e.g., Petrol, Food",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "Amount",
                  hintText: "e.g., 1500",
                  prefix: const Text('₹ '),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _membersController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "Members",
                  hintText: "e.g., 2",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                onChanged: (_) {
                  // Rebuild total section immediately on member change
                  setState(() {});
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: _addExpense,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryButtonColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text(
                  "Add Expense",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                onPressed: _resetExpenses,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _clearButtonColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text(
                  "Clear List",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildExpenseList() {
    return Container(
      constraints: const BoxConstraints(minHeight: 100), 
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 8.0, bottom: 4.0),
            child: Text(
              "Current Expenses:",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          ..._expenses.asMap().entries.map((entry) {
            final index = entry.key;
            final expense = entry.value;
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 0),
              title: Text(expense.item, style: const TextStyle(fontSize: 16)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "₹ ${expense.amount.toStringAsFixed(2)}",
                    style: TextStyle(fontSize: 16, color: _indigoColor, fontWeight: FontWeight.w600),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.red, size: 20),
                    onPressed: () => _removeExpense(index),
                  ),
                ],
              ),
            );
          }).toList(),
          if (_expenses.isEmpty) 
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10.0),
              child: Center(
                child: Text(
                  "No expenses added yet.",
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTotalSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 15.0),
      decoration: BoxDecoration(
        color: Colors.indigo.shade50,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            "Total: ₹ ${_totalAmount.toStringAsFixed(2)}",
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 5),
          Text(
            "Per Person: ₹ ${_perPersonAmount.toStringAsFixed(2)}",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _indigoColor),
          ),
          const SizedBox(height: 15),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saveExpenses, // Calls the corrected saving function
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600, // Distinct color for Save
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text(
                      "Save",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        color: const Color(0xFFEAF3FF),
        padding: const EdgeInsets.all(20.0),
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 8,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 26.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInputSection(),
                const SizedBox(height: 15),
                _buildExpenseList(),
                const Divider(color: Colors.grey, height: 30),
                _buildTotalSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}