import 'package:flutter/material.dart';

class ExpenseTab extends StatefulWidget {
  const ExpenseTab({Key? key}) : super(key: key);

  @override
  State<ExpenseTab> createState() => _ExpenseTabState();
}

class ExpenseItem {
  final String item;
  final double amount;

  ExpenseItem(this.item, this.amount);
}

class _ExpenseTabState extends State<ExpenseTab> {
  final TextEditingController _itemController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _membersController = TextEditingController();

  // Color Definitions and Save Function
  // UPDATED COLORS
  final Color _primaryButtonColor = const Color(0xFF928FD2);    // Add and Reset Button Color: #928FD2
  final Color _clearButtonColor = const Color(0xFF7672CB);      // End Clear Button Color: #7672CB
  final Color _indigoColor = Colors.indigo.shade600;            // KEPT for Save button and now Per Person text

  void _saveExpenses() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Expenses saved (Placeholder action).")),
    );
  }
  
  // --- Logic Functions ---

  // State variables
  List<ExpenseItem> _expenses = []; 
  
  // Variable for calculation (default to 1 to prevent division by zero)
  int _numberOfPeople = 1; 

  @override
  void initState() {
    super.initState();
    _membersController.addListener(_handleMemberInputChange);
  }

  @override
  void dispose() {
    _membersController.removeListener(_handleMemberInputChange);
    _itemController.dispose();
    _amountController.dispose();
    _membersController.dispose();
    super.dispose();
  }

  void _handleMemberInputChange() {
    final text = _membersController.text.trim();
    final parsed = int.tryParse(text);

    int newCount;
    
    if (parsed != null && parsed > 0) {
      newCount = parsed;
    } else {
      // If empty or invalid (0 or less), calculate with 1 but don't change the field text.
      newCount = 1;
      
      // Visually correct the field if an invalid number was entered
      if (parsed != null && parsed <= 0) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
            _membersController.text = newCount.toString();
            _membersController.selection = TextSelection.fromPosition(
                TextPosition(offset: _membersController.text.length));
        });
      }
    }

    if (_numberOfPeople != newCount) {
      setState(() {
        _numberOfPeople = newCount;
      });
    }
  }

  void _addExpense() {
    final item = _itemController.text.trim();
    final amountText = _amountController.text.trim();

    if (item.isEmpty || amountText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter both item and amount.")),
      );
      return;
    }

    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid amount.")),
      );
      return;
    }

    setState(() {
      _expenses.add(ExpenseItem(item, amount));
      _itemController.clear();
      _amountController.clear();
    });
  }

  void _resetExpenses() {
    setState(() {
      _expenses = [];
      _numberOfPeople = 1; 
      _membersController.clear(); 
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("All expenses cleared.")),
    );
  }

  // --- Calculation Functions ---

  double get _totalExpense {
    return _expenses.fold(0.0, (sum, item) => sum + item.amount);
  }

  String get _perPersonCost {
    final count = _numberOfPeople > 0 ? _numberOfPeople : 1; 
    
    if (_totalExpense == 0) {
      return "0.00";
    }
    return (_totalExpense / count).toStringAsFixed(2);
  }

  // --- Build Widgets ---
  
  Widget _buildInputSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Item Input
        TextField(
          controller: _itemController,
          decoration: const InputDecoration(
            hintText: "Item (e.g. Food, Fuel)",
            labelText: "Item",
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
          onSubmitted: (_) => _addExpense(),
        ),
        const SizedBox(height: 12),
        // 2. Amount Input and Add Button
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: "Amount (₹)",
                  labelText: "Amount (₹)",
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                onSubmitted: (_) => _addExpense(),
              ),
            ),
            const SizedBox(width: 8),
            // 3. Add Button
            SizedBox(
              width: 80,
              height: 48,
              child: ElevatedButton(
                onPressed: _addExpense,
                style: ElevatedButton.styleFrom(
                  // COLOR CHANGE: Add button to 928FD2
                  backgroundColor: _primaryButtonColor, 
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                  padding: EdgeInsets.zero,
                ),
                child: const Text("Add", style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildExpenseList() {
    if (_expenses.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.only(top: 20),
          child: Text(
            "No expenses added yet.",
            style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
          ),
        ),
      );
    }
    return Column(
      children: _expenses.map((expense) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                expense.item,
                style: const TextStyle(fontSize: 16),
              ),
              Text(
                '₹${expense.amount.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTotalSection() {
    return Container(
      padding: const EdgeInsets.only(top: 20, bottom: 10),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 4,
                child: TextField(
                  controller: _membersController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "No. of members",
                    hintText: "e.g., 3",
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Reset Button 
              SizedBox(
                width: 80,
                height: 48,
                child: ElevatedButton(
                  onPressed: _resetExpenses,
                  style: ElevatedButton.styleFrom(
                    // COLOR CHANGE: Reset button to 928FD2
                    backgroundColor: _primaryButtonColor, 
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                    padding: EdgeInsets.zero,
                  ),
                  child: const Text("Reset", style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Total Display Card
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.indigo.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.indigo.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.money, color: Colors.indigo, size: 24),
                    const SizedBox(width: 10),
                    Text(
                      "Total:",
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo.shade700),
                    ),
                    const Spacer(),
                    Text(
                      '₹${_totalExpense.toStringAsFixed(2)}',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo.shade700),
                    ),
                  ],
                ),
                const Divider(height: 15, color: Colors.indigoAccent),
                Row(
                  // Per Person section color change
                  children: [
                    // ICON COLOR CHANGE: from purple to indigo
                    Icon(Icons.person, color: Colors.indigo.shade700, size: 24),
                    const SizedBox(width: 10),
                    Text(
                      "Per Person:", 
                      style: TextStyle(
                          fontSize: 18, 
                          fontWeight: FontWeight.bold, 
                          // TEXT COLOR CHANGE: from purple.shade700 to indigo.shade700
                          color: Colors.indigo.shade700
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '₹$_perPersonCost',
                      style: TextStyle(
                          fontSize: 18, 
                          fontWeight: FontWeight.bold, 
                          // VALUE COLOR CHANGE: from purple.shade700 to indigo.shade700
                          color: Colors.indigo.shade700
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Two-Button Row (Clear and Save)
          SizedBox(
            width: double.infinity,
            child: Row(
              children: [
                // Clear Button (End of Page)
                Expanded(
                  child: ElevatedButton(
                    onPressed: _resetExpenses,
                    style: ElevatedButton.styleFrom(
                      // COLOR CHANGE: End clear button to 7672CB
                      backgroundColor: _clearButtonColor, 
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text(
                      "Clear",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 15), // Spacer
                // Save Button (Indigo)
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saveExpenses, // Save function
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _indigoColor, // Indigo color (no change)
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
                // The 'Row' and 'Divider' for the header have been removed.
                
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