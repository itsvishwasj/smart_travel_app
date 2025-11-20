// trip_suggestions_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

// --------------------------------------------------------------------------
// Data Models and Helpers
// --------------------------------------------------------------------------

class TripPlan {
  final String id;
  final String tripRoute;

  /// Raw date key used for matching with expenses: "YYYY-MM-DD" or "No Date"
  final String tripDateKey;

  /// Nicely formatted date for UI: "24 Nov 2025" etc.
  final String tripDateDisplay;

  /// Raw ISO from Firestore meta['plannedDate'], may be null.
  final String? plannedDateIso;

  /// Estimated cost string (e.g., "₹35,000 - ₹40,000")
  final String estimatedCost;

  TripPlan({
    required this.id,
    required this.tripRoute,
    required this.tripDateKey,
    required this.tripDateDisplay,
    this.plannedDateIso,
    this.estimatedCost = '',
  });
}

class ExpenseSummary {
  final double totalActualExpense;
  final bool dataExists;

  ExpenseSummary({required this.totalActualExpense, required this.dataExists});
}

// --------------------------------------------------------------------------
// NewFeatureScreen Widget
// --------------------------------------------------------------------------

class NewFeatureScreen extends StatefulWidget {
  const NewFeatureScreen({super.key});

  @override
  State<NewFeatureScreen> createState() => _NewFeatureScreenState();
}

class _NewFeatureScreenState extends State<NewFeatureScreen> {
  TripPlan? _selectedPlan;
  ExpenseSummary? _expenseSummary;

  List<TripPlan> _savedPlans = [];
  bool _isLoadingPlans = false;
  bool _isLoadingExpenses = false;

  // AI state
  bool _isLoadingAi = false;
  String? _aiAdvice;

  // ⚠️ Use the same key you use in PlanTab
  static const String _geminiApiKey = 'AIzaSyC2gkLJ-pDwn4LMH9E3zRRgCj9GKu0AwR4';

  @override
  void initState() {
    super.initState();
    _loadPlans();
  }

  // --------------------------------------------------------------------------
  // Data Logic: Loading, Date Check, and Expense Fetching
  // --------------------------------------------------------------------------

  bool _isPastDate(String? dateIso) {
    if (dateIso == null || dateIso.isEmpty) return true;
    try {
      final plannedDate = DateTime.parse(dateIso.split('T').first);
      final today = DateTime.now();
      final plannedDay =
          DateTime(plannedDate.year, plannedDate.month, plannedDate.day);
      final todayDay = DateTime(today.year, today.month, today.day);

      return plannedDay.isBefore(todayDay);
    } catch (_) {
      return true;
    }
  }

  Future<void> _loadPlans() async {
    setState(() {
      _isLoadingPlans = true;
    });
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        setState(() {
          _isLoadingPlans = false;
        });
      }
      return;
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('plans')
          .orderBy('createdAt', descending: true)
          .get();

      final List<TripPlan> loadedPlans = [];

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

        // Planned date in ISO
        final String? plannedIso = meta['plannedDate'] as String?;

        // For matching with expenses: YYYY-MM-DD or 'No Date'
        final String dateKey =
            (plannedIso != null && plannedIso.isNotEmpty)
                ? plannedIso.split('T').first
                : 'No Date';

        // For display: 24 Nov 2025 or 'No Date'
        String displayDate;
        if (dateKey != 'No Date') {
          try {
            final d = DateTime.parse(dateKey);
            displayDate = DateFormat('dd MMM yyyy').format(d);
          } catch (_) {
            displayDate = dateKey;
          }
        } else {
          displayDate = 'No Date';
        }

        // Estimated cost – read from the same field your app uses
        final dynamic estimatedAny = raw['estimatedTotalCost'] ??
            meta['estimatedExpense'] ??
            meta['estimatedTotal'] ??
            meta['estimated'];

        final String estimatedCostText =
            estimatedAny == null ? '' : estimatedAny.toString();

        loadedPlans.add(
          TripPlan(
            id: doc.id,
            tripRoute: tripName,
            tripDateKey: dateKey,
            tripDateDisplay: displayDate,
            plannedDateIso: plannedIso,
            estimatedCost: estimatedCostText,
          ),
        );
      }

      if (!mounted) return;

      setState(() {
        _savedPlans = loadedPlans;
        _isLoadingPlans = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingPlans = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading plans: $e')),
      );
    }
  }

  /// Fetch actual expenses from `users/{uid}/expenses` that match
  /// the selected plan's `trip_details.name` and `trip_details.date`.
  Future<void> _fetchExpenseData(TripPlan plan) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() {
      _isLoadingExpenses = true;
      _expenseSummary = null;
    });

    try {
      final String tripName = plan.tripRoute;
      final String tripDateKey = plan.tripDateKey;

      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('expenses')
          .where('trip_details.name', isEqualTo: tripName)
          .where('trip_details.date', isEqualTo: tripDateKey)
          .get();

      double totalActual = 0.0;
      bool dataExists = snapshot.docs.isNotEmpty;

      if (dataExists) {
        for (final doc in snapshot.docs) {
          final data = doc.data();
          // In expense_tab.dart you stored 'total'; support fallbacks too.
          final dynamic rawTotal =
              data['total'] ?? data['totalAmount'] ?? data['total_expense'];

          if (rawTotal is num) {
            totalActual += rawTotal.toDouble();
          } else if (rawTotal is String) {
            totalActual += double.tryParse(rawTotal) ?? 0.0;
          }
        }
      }

      if (!mounted) return;

      setState(() {
        _expenseSummary = ExpenseSummary(
          totalActualExpense: totalActual,
          dataExists: dataExists,
        );
        _isLoadingExpenses = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingExpenses = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching expenses: $e')),
      );
    }
  }

  // --------------------------------------------------------------------------
  // Helper: format AI advice with blank lines between points
  // --------------------------------------------------------------------------

  String _formatAdvice(String raw) {
    // Take only non-empty lines, then add one blank line after each
    final lines = raw
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
    return lines.join('\n\n');
  }

  // --------------------------------------------------------------------------
  // AI Suggestions with Gemini (EXPENSE-FOCUSED, SHORT, SMART)
  // --------------------------------------------------------------------------

  Future<void> _generateAiAdvice() async {
    if (_selectedPlan == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a trip first.')),
      );
      return;
    }

    final plan = _selectedPlan!;
    final expense = _expenseSummary;

    setState(() {
      _isLoadingAi = true;
      _aiAdvice = null;
    });

    try {
      if (_geminiApiKey.isEmpty) {
        throw 'Gemini API key is empty. Please set it in trip_suggestions_screen.dart';
      }

      final model = GenerativeModel(
        model: 'gemini-2.5-flash', // ✅ same as PlanTab
        apiKey: _geminiApiKey,
      );

      final String tripDateForPrompt =
          (plan.plannedDateIso != null && plan.plannedDateIso!.isNotEmpty)
              ? plan.plannedDateIso!.split('T').first
              : plan.tripDateDisplay;

      final bool hasActual =
          (expense != null && expense.dataExists && expense.totalActualExpense > 0);
      final double? actualTotal =
          hasActual ? expense!.totalActualExpense : null;

      final String overspendHint;
      if (hasActual) {
        overspendHint =
            'The actual total expense recorded for this trip is about ₹${actualTotal!.toStringAsFixed(2)}, '
            'and the estimated cost from the planner was: "${plan.estimatedCost}". '
            'Use this difference to judge overspending or underspending, but do not invent fake numbers.';
      } else {
        overspendHint =
            'No actual expenses were recorded for this trip yet. You can still give proactive budgeting and savings tips.';
      }

      final prompt = '''
You are a smart TRAVEL EXPENSE coach for ONE user.

You only know what is given below about this single trip:

- Trip route: ${plan.tripRoute}
- Trip date (planned): $tripDateForPrompt
- Estimated trip cost (if available): "${plan.estimatedCost.isEmpty ? 'Not available' : plan.estimatedCost}"
- Actual total expense (if available): ${hasActual ? '₹${actualTotal!.toStringAsFixed(2)}' : 'Not entered yet'}

$overspendHint

Your job:
Give EXACTLY 4 SHORT numbered lines of advice focused on MONEY and SAVINGS for THIS trip.

Each line MUST:
- Start with "1.", "2.", "3.", "4.".
- Talk directly to the user using "you" and "your trip".
- Feel specific to this route and budget situation, not generic.
- Be at most about 20 words.
- Be clear and practical.

CONTENT FOCUS (use these ideas, but words are your own):

1. Budget prediction:
   - From what you see, might they go above, around, or below a reasonable budget for such a trip?
   - Give one simple money tip.

2. Category insight:
   - Which cost types (stay, food, transport, activities, shopping, etc.) are most likely to become heavy or already look heavy?
   - Give one small optimisation.

3. Packing-based savings:
   - Suggest what they should carry to avoid many tiny, repeated purchases on this kind of route.

4. Timing / peak-time / season:
   - Comment on how dates like weekends/holidays or common patterns on this route could make things costlier or cheaper, with one action tip.

STRICT RULES:
- Output ONLY the 4 numbered lines. No headings, no bullet lists, no sections, no emojis.
- Do NOT invent fake amounts. Use only the information given and general travel behaviour.
- Do NOT explain the logic; just give the four smart tips.
''';

      final response = await model.generateContent([
        Content.text(prompt),
      ]);

      final text = response.text ?? 'No suggestions generated.';

      if (!mounted) return;
      setState(() {
        _aiAdvice = _formatAdvice(text.trim()); // 👈 add blank line after each point
        _isLoadingAi = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingAi = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating AI suggestions: $e')),
      );
    }
  }

  // --------------------------------------------------------------------------
  // UI: Plan selection container & dialog
  // --------------------------------------------------------------------------

  Widget _buildPlanSelectionContainer() {
    return InkWell(
      onTap: () => _showPlanSelectionDialog(context),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.indigo.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.indigo.shade200),
        ),
        padding: const EdgeInsets.all(15.0),
        child: Row(
          children: [
            Icon(Icons.luggage, color: Colors.indigo.shade700),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select Trip Plan',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo.shade900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _selectedPlan == null
                        ? 'Tap to choose a saved trip...'
                        : '${_selectedPlan!.tripRoute} (${_selectedPlan!.tripDateDisplay})',
                    style: TextStyle(
                      fontSize: 14,
                      color: _selectedPlan == null
                          ? Colors.grey.shade600
                          : Colors.black87,
                      fontStyle: _selectedPlan == null
                          ? FontStyle.italic
                          : FontStyle.normal,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_drop_down, color: Colors.indigo.shade700),
          ],
        ),
      ),
    );
  }

  void _onPlanSelected(BuildContext dialogContext, TripPlan plan) {
    setState(() {
      _selectedPlan = plan;
      _expenseSummary = null;
      _aiAdvice = null;
    });

    _fetchExpenseData(plan);

    Navigator.pop(dialogContext);
  }

  void _showPlanSelectionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        if (_isLoadingPlans) {
          return const AlertDialog(
            title: Text('Loading Plans...'),
            content: SizedBox(
              height: 50,
              child: Center(
                child: CircularProgressIndicator(color: Colors.indigo),
              ),
            ),
          );
        }

        if (_savedPlans.isEmpty) {
          return AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('No Plans Found'),
            content: const Text('You have no saved trip plans.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text(
                  'Close',
                  style: TextStyle(color: Colors.indigo),
                ),
              ),
            ],
          );
        }

        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            'Select a Trip Plan',
            style: TextStyle(color: Colors.indigo),
          ),
          contentPadding: const EdgeInsets.all(0),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _savedPlans.length,
              itemBuilder: (context, index) {
                final plan = _savedPlans[index];
                final isPast = _isPastDate(plan.plannedDateIso);

                final Color tileColor =
                    isPast ? Colors.indigo.shade100 : Colors.indigo.shade300;
                final Color textColor =
                    isPast ? Colors.grey.shade800 : Colors.indigo.shade900;

                return Column(
                  children: [
                    ListTile(
                      tileColor: tileColor,
                      title: Text(
                        plan.tripRoute,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      subtitle: Text(
                        'Planned: ${plan.tripDateDisplay} ' +
                            (isPast ? '(Past)' : '(Upcoming)'),
                        style: TextStyle(
                          color: textColor.withOpacity(0.8),
                        ),
                      ),
                      trailing: Icon(
                        isPast ? Icons.history : Icons.calendar_month,
                        color: textColor,
                      ),
                      onTap: () => _onPlanSelected(dialogContext, plan),
                    ),
                    if (index < _savedPlans.length - 1)
                      const Divider(
                        height: 1,
                        thickness: 0.5,
                        color: Colors.black12,
                      ),
                  ],
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.indigo),
              ),
            ),
          ],
        );
      },
    );
  }

  // --------------------------------------------------------------------------
  // UI: Expense Summary Section
  // --------------------------------------------------------------------------

  Widget _buildExpenseSummary() {
    if (_selectedPlan == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 40, color: Colors.black26),
        Text(
          'Expense Summary', // 👈 changed text here
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.indigo.shade700,
          ),
        ),
        const SizedBox(height: 10),

        // 1. Estimated Cost (from plan)
        _buildEstimatedCostTile(),

        const SizedBox(height: 10),

        // 2. Actual Expenses (from expense tab / Firestore)
        _buildActualExpenseTile(),

        // 3. AI suggestions section
        _buildAiSuggestionsSection(),
      ],
    );
  }

  Widget _buildEstimatedCostTile() {
    final String text = _selectedPlan!.estimatedCost.trim();
    final bool hasValue = text.isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.orange.shade700.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(Icons.money_outlined, color: Colors.orange.shade700),
          const SizedBox(width: 15),
          const Expanded(
            child: Text(
              'Estimated Cost',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            hasValue ? text : 'Not available',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.orange.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseTile({
    required String title,
    required double amount,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 15),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 15),
          Expanded(
            child: Text(
              title,
              style:
                  TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: color),
            ),
          ),
          Text(
            '₹${NumberFormat('#,##0.00').format(amount)}',
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildActualExpenseTile() {
    if (_isLoadingExpenses) {
      return const Center(
        child: LinearProgressIndicator(color: Colors.green),
      );
    }

    if (_expenseSummary == null) {
      return const SizedBox.shrink();
    }

    if (!_expenseSummary!.dataExists) {
      return _buildStatusTile(
        message: 'Still actual expenses not entered.',
        icon: Icons.error_outline,
        color: Colors.red.shade700,
      );
    }

    return _buildExpenseTile(
      title: 'Total Actual Expenses',
      amount: _expenseSummary!.totalActualExpense,
      icon: Icons.check_circle_outline,
      color: Colors.green.shade700,
    );
  }

  Widget _buildStatusTile({
    required String message,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 15),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 15),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 15,
                fontStyle: FontStyle.italic,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // UI: AI Suggestions Section
  // --------------------------------------------------------------------------

  Widget _buildAiSuggestionsSection() {
    if (_selectedPlan == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 25),
        // 👇 Removed "AI-Powered Suggestions" heading, only button now
        ElevatedButton.icon(
          onPressed: _isLoadingAi ? null : _generateAiAdvice,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.indigo,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          ),
          icon: const Icon(Icons.auto_awesome),
          label: Text(
            _isLoadingAi ? "Generating..." : "Get Smart Suggestions",
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 10),
        if (_isLoadingAi)
          const LinearProgressIndicator()
        else if (_aiAdvice != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.indigo.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.indigo.shade100),
            ),
            child: Text(
              _aiAdvice!,
              style: const TextStyle(fontSize: 14.5, height: 1.4),
            ),
          )
        else
          const Text(
            "Tap the button to generate personalised advice for this trip.",
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
      ],
    );
  }

  // --------------------------------------------------------------------------
  // Main Build Method
  // --------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF3FF),
      appBar: AppBar(
        backgroundColor: Colors.indigo,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Trip Plan Expense Tracker",
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 8,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 👇 Removed "Analyze Trip Finances" heading
                _buildPlanSelectionContainer(),

                _buildExpenseSummary(),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
