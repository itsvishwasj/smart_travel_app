import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ExpenseTab extends StatefulWidget {
  const ExpenseTab({Key? key}) : super(key: key);

  @override
  State<ExpenseTab> createState() => _ExpenseTabState();
}

class ExpenseItem {
  final String item;
  final double amount;
  final int splitMembers;

  ExpenseItem(this.item, this.amount, this.splitMembers);

  Map<String, dynamic> toJson() => {
        'item': item,
        'amount': amount,
        'splitMembers': splitMembers,
      };
}

class _ExpenseTabState extends State<ExpenseTab> {
  final TextEditingController _itemController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _splitMembersController =
      TextEditingController(text: '1');

  final Color _primaryButtonColor = const Color(0xFF928FD2);
  final Color _clearButtonColor = const Color(0xFF7672CB);
  final Color _indigoColor = Colors.indigo.shade600;

  List<ExpenseItem> _expenses = [];

  /// Each plan map will have:
  /// {
  ///   "id": "...",                   // firestore doc id
  ///   "tripRoute": "From → To",
  ///   "tripStartDate": "YYYY-MM-DD" or "No Date",
  ///   "travelers": "2",
  ///   "estimatedTotalCost": "₹.. - ₹.."
  /// }
  List<Map<String, dynamic>> _savedPlans = [];
  Map<String, dynamic>? _selectedTrip;
  int _totalTravelers = 1;

  @override
  void initState() {
    super.initState();
    _totalTravelers = 1;
    _splitMembersController.text = '1';
    _loadPlans();
  }

  @override
  void dispose() {
    _itemController.dispose();
    _amountController.dispose();
    _splitMembersController.dispose();
    super.dispose();
  }

  // --------------------------------------------------------------------------
  // Load plans from Firestore (MATCHES main.dart Firestore format)
  // --------------------------------------------------------------------------
  Future<void> _loadPlans() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (!mounted) return;
      setState(() {
        _savedPlans = [];
        _selectedTrip = null;
        _totalTravelers = 1;
        _splitMembersController.text = '1';
      });
      return;
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('plans')
          .orderBy('createdAt', descending: true)
          .get();

      final List<Map<String, dynamic>> loadedPlans = [];

      for (final doc in snapshot.docs) {
        final raw = doc.data();
        final Map<String, dynamic> meta =
            (raw['meta'] ?? {}) as Map<String, dynamic>;

        final String from = (meta['from'] ?? '') as String;
        final String to = (meta['to'] ?? '') as String;
        final String tripName =
            (meta['tripName'] ??
                    (from.isNotEmpty && to.isNotEmpty
                        ? '$from → $to'
                        : 'Trip')) as String;

        final dynamic membersRaw = meta['members'] ?? 1;
        final int members = membersRaw is int
            ? membersRaw
            : int.tryParse(membersRaw.toString()) ?? 1;

        final String? plannedIso = meta['plannedDate'] as String?;
        final String tripDateDisplay =
            (plannedIso != null && plannedIso.isNotEmpty)
                ? plannedIso.split('T').first
                : 'No Date';

        final String estimatedCost =
            (raw['estimatedTotalCost'] ?? '') as String;

        loadedPlans.add({
          'id': doc.id,
          'tripRoute': tripName,
          'tripStartDate': tripDateDisplay,
          'travelers': members.toString(),
          'estimatedTotalCost': estimatedCost,
        });
      }

      if (!mounted) return;

      setState(() {
        _savedPlans = loadedPlans;

        // keep selectedTrip if still present; else reset
        if (_selectedTrip != null &&
            !_savedPlans.any((p) => p['id'] == _selectedTrip!['id'])) {
          _selectedTrip = null;
          _totalTravelers = 1;
          _splitMembersController.text = '1';
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading trips: $e')),
      );
    }
  }

  // --------------------------------------------------------------------------
  // Helpers – trip selector dialog + date formatter
  // --------------------------------------------------------------------------
  void _openTripSelectorDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Select Trip",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                if (_savedPlans.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: Text("No plans found."),
                  )
                else
                  ..._savedPlans.map((plan) {
                    final date = plan["tripStartDate"];
                    final formattedDate = _formatDate(date.toString());

                    return ListTile(
                      title: Text(plan['tripRoute']),
                      subtitle: Text(formattedDate),
                      onTap: () {
                        Navigator.pop(context);
                        setState(() {
                          _selectedTrip = plan;
                          _totalTravelers =
                              int.tryParse(plan['travelers']) ?? 1;
                          if (_totalTravelers < 1) _totalTravelers = 1;
                          _splitMembersController.text =
                              _totalTravelers.toString();
                        });
                      },
                    );
                  }).toList(),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDate(String dateStr) {
    try {
      DateTime date = DateTime.parse(dateStr);
      return "${date.day} ${_monthName(date.month)} ${date.year}";
    } catch (e) {
      return dateStr; // fallback, e.g. "No Date"
    }
  }

  String _monthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months[month - 1];
  }

  // --------------------------------------------------------------------------
  // Calculations
  // --------------------------------------------------------------------------
  double get _totalAmount =>
      _expenses.fold(0.0, (sum, item) => sum + item.amount);

  Map<String, double> _calculateSplitDetails() {
    double totalAmount = _totalAmount;

    double totalSplitShareSum = _expenses.fold(
        0.0, (sum, item) => sum + (item.amount / item.splitMembers));

    double perPersonShare =
        _totalTravelers > 0 ? totalAmount / _totalTravelers : 0.0;

    return {
      'Total Expense': totalAmount,
      'Total Travelers': _totalTravelers.toDouble(),
      'Split Share per Traveler (Equal)': perPersonShare,
      'Total Split Shares Sum (Items)': totalSplitShareSum,
    };
  }

  // --------------------------------------------------------------------------
  // Expense operations
  // --------------------------------------------------------------------------
  void _addExpense() {
    final item = _itemController.text;
    final amountText = _amountController.text;
    final splitMembersText = _splitMembersController.text;

    if (item.isEmpty || amountText.isEmpty || splitMembersText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter item, amount, and split members"),
        ),
      );
      return;
    }

    final amount = double.tryParse(amountText);
    final splitMembers = int.tryParse(splitMembersText);

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid amount")),
      );
      return;
    }

    if (splitMembers == null ||
        splitMembers <= 0 ||
        splitMembers > _totalTravelers) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Split members must be a valid number between 1 and $_totalTravelers (Total Travelers)",
          ),
        ),
      );
      return;
    }

    setState(() {
      _expenses.add(
        ExpenseItem(item, amount, splitMembers),
      );
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
      _selectedTrip = null;
      _totalTravelers = 1;
      _splitMembersController.text = '1';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Current expense list cleared.")),
    );
  }

  // Save expenses to Firestore under users/{uid}/expenses
  Future<void> _saveExpenses() async {
    if (_expenses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No expenses to save.")),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must be logged in to save expenses.'),
        ),
      );
      return;
    }

    final double total = _totalAmount;

    final Map<String, dynamic> recordMetadata = {
      'timestamp': DateTime.now().toIso8601String(),
      'total': total,
      'trip_details': _selectedTrip != null
          ? {
              'name': _selectedTrip!['tripRoute'],
              'date': _selectedTrip!['tripStartDate'],
              'estimatedCost': _selectedTrip!['estimatedTotalCost'],
              'travelers': _totalTravelers,
            }
          : 'Manual Entry',
      'travelers': _totalTravelers,
      'split_data': _calculateSplitDetails(),
      'items': _expenses.map((e) => e.toJson()).toList(),
      'createdAt': FieldValue.serverTimestamp(),
    };

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('expenses')
          .add(recordMetadata);

      setState(() {
        _expenses.clear();
        _selectedTrip = null;
        _totalTravelers = 1;
        _splitMembersController.text = '1';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Expense record saved to your account!"),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to save expenses: $e"),
        ),
      );
    }
  }

  // --------------------------------------------------------------------------
  // UI Widgets
  // --------------------------------------------------------------------------
  Widget _buildTripSelection() {
    return GestureDetector(
      onTap: () => _openTripSelectorDialog(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                _selectedTrip == null
                    ? 'Tap to select a trip'
                    : _selectedTrip!['tripRoute'],
                style: const TextStyle(fontSize: 16),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }

  Widget _buildInputSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: TextField(
                  controller: _itemController,
                  decoration: InputDecoration(
                    labelText: 'Item Name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Amount (₹)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                'Split for how many members (Max: $_totalTravelers):',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade700,
                ),
              ),
            ),
            SizedBox(
              width: 80,
              child: TextField(
                controller: _splitMembersController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: '1-$_totalTravelers',
                  border: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(
                      Radius.circular(10),
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 5, vertical: 10),
                ),
                enabled: _totalTravelers > 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: _resetExpenses,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryButtonColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Reset",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: ElevatedButton(
                onPressed: _addExpense,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Add",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildExpenseList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Items Added:",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        if (_expenses.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10.0),
            child: Center(
              child: Text(
                "No expenses added yet.",
                style: TextStyle(color: Colors.grey),
              ),
            ),
          )
        else
          ..._expenses.asMap().entries.map((entry) {
            final index = entry.key;
            final expense = entry.value;
            final splitCost = expense.amount / expense.splitMembers;

            return Card(
              elevation: 1,
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                title: Text(
                  expense.item,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  'Split for ${expense.splitMembers} member${expense.splitMembers > 1 ? 's' : ''}',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '₹${expense.amount.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: _indigoColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '(₹${splitCost.toStringAsFixed(2)}/share)',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete,
                        color: Colors.red,
                      ),
                      onPressed: () => _removeExpense(index),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
      ],
    );
  }

  Widget _buildSplitDetailRow(
      String label, String value, Color labelColor, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 15,
                color: labelColor,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalSection() {
    final splitData = _calculateSplitDetails();

    return Container(
      padding: const EdgeInsets.all(15.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Total Expenses:",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _indigoColor,
                ),
              ),
              Text(
                "₹${_totalAmount.toStringAsFixed(2)}",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _indigoColor,
                ),
              ),
            ],
          ),
          const Divider(
            height: 20,
            color: Colors.grey,
          ),
          const Text(
            "Final Split Breakdown:",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          if (_expenses.isNotEmpty) ...[
            _buildSplitDetailRow(
              'Total Travelers',
              '${splitData['Total Travelers']!.toInt()}',
              Colors.black54,
              Colors.black54,
            ),
            _buildSplitDetailRow(
              'Sum of Individual Shares',
              '₹${splitData['Total Split Shares Sum (Items)']!.toStringAsFixed(2)}',
              Colors.deepOrange,
              Colors.deepOrange,
            ),
            _buildSplitDetailRow(
              'Average Share Per Traveler (Equal)',
              '₹${splitData['Split Share per Traveler (Equal)']!.toStringAsFixed(2)}',
              Colors.green.shade700,
              Colors.green.shade700,
            ),
            const SizedBox(height: 15),
          ],
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _resetExpenses,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _clearButtonColor,
                    side: BorderSide(
                      color: _clearButtonColor,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "Clear All",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: ElevatedButton(
                  onPressed: _saveExpenses,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "Save",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 8,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 24.0,
              horizontal: 26.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTripSelection(),

                // If no trip selected, keep layout clean but don't show warning text
                if (_selectedTrip == null) ...[
                  const SizedBox(height: 10),
                ] else ...[
                  const SizedBox(height: 20),

                  // TRIP DETAILS
                  const Text(
                    "Trip Details:",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Date: ${_formatDate(_selectedTrip!['tripStartDate'])}",
                  ),
                  Text("Total Travelers: $_totalTravelers"),
                  Text(
                    "Estimated Cost: ${_selectedTrip!['estimatedTotalCost']}",
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 20),
                  const Text(
                    "Please enter all the expenses of this trip.",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 20),
                  const Divider(color: Colors.grey, height: 30),

                  // INPUT FORM SECTION
                  _buildInputSection(),
                  const SizedBox(height: 15),

                  // EXPENSE LIST
                  _buildExpenseList(),
                  const Divider(color: Colors.grey, height: 30),

                  // TOTAL + SAVE SECTION
                  _buildTotalSection(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
