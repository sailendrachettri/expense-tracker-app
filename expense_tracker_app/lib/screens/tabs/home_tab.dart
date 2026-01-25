import 'package:flutter/material.dart';
import '../../models/expense.dart';
import '../../db/database_helper.dart';
import '../../utils/formate_date_time.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final TextEditingController _amountController = TextEditingController();

  String? _selectedCategory;

  double get totalExpenseAmountToday {
    return _todayExpenses.fold(0.0, (sum, e) => sum + e.amount);
  }

  final List<Expense> _todayExpenses = [];
  List<String> _categories = [];

  bool get _canAddExpense =>
      _amountController.text.isNotEmpty && _selectedCategory != null;

  @override
  void initState() {
    super.initState();
    _loadTodayExpenses();
    _loadCategories();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _showAddCategoryDialog() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Category'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'e.g. Entertainment, Bills',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isEmpty) return;

              await DatabaseHelper.instance.insertCategory(
                controller.text.trim(),
              );

              Navigator.pop(context);
              _loadCategories();
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _loadTodayExpenses() async {
    final expenses = await DatabaseHelper.instance.getTodayExpenses();
    setState(() {
      _todayExpenses
        ..clear()
        ..addAll(expenses);
    });
  }

  Future<void> _loadCategories() async {
    final data = await DatabaseHelper.instance.getCategories();
    setState(() {
      _categories = data;
    });
  }

  Future<void> _addExpense() async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || _selectedCategory == null) return;

    final expense = Expense(
      id: DateTime.now().toString(),
      category: _selectedCategory!,
      amount: amount,
      date: DateTime.now(),
    );

    await DatabaseHelper.instance.insertExpense(expense);

    setState(() {
      _todayExpenses.insert(0, expense);
      _amountController.clear();
      _selectedCategory = null;
    });
  }

  Future<void> _deleteExpense(String id) async {
    await DatabaseHelper.instance.deleteExpense(id);
    setState(() {
      _todayExpenses.removeWhere((e) => e.id == id);
    });
  }

  int? _selectedExpenseIndex;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add Expense',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 20),

            Row(
              children: [
                // Amount input
                Expanded(
                  child: TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      prefixText: '₹ ',
                      labelText: 'Amount (INR)',
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),

                const SizedBox(width: 12),

                // Add button
                SizedBox(
                  height: 56, // matches TextField height
                  width: 100,
                  child: ElevatedButton(
                    onPressed: _canAddExpense
                        ? _addExpense
                        : null, // 👈 disable logic
                    child: const Text('Add'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              textBaseline: TextBaseline.alphabetic,
              children: [
                const Text(
                  'Select Category',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
                const SizedBox(width: 10),
                InkWell(
                  onTap: _showAddCategoryDialog,
                  borderRadius: BorderRadius.circular(999),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Icon(Icons.add_circle, size: 17),
                  ),
                ),
              ],
            ),

            Wrap(
              spacing: 10,
              children: _categories.map((category) {
                return ChoiceChip(
                  label: Text(category, style: TextStyle(fontSize: 10)),
                  selected: _selectedCategory == category,
                   shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)
                  ),
                  onSelected: (_) {
                    setState(() {
                      _selectedCategory = category;
                    });
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            Row(
              children: [
                const Text(
                  'Today',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Text(
                  '₹${totalExpenseAmountToday.toStringAsFixed(2)}',
                  maxLines: 1,
                  softWrap: false,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // DAILY EXPENSE HISTORY
            Expanded(
              child: _todayExpenses.isEmpty
                  ? const Center(
                      child: Text(
                        'No expenses added today',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _todayExpenses.length,
                      itemBuilder: (context, index) {
                        final expense = _todayExpenses[index];
                        final isSelected = _selectedExpenseIndex == index;

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedExpenseIndex = isSelected ? null : index;
                            });
                          },
                          child: Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            elevation: isSelected ? 3 : 1.5,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              child: Row(
                                children: [
                                  // Icon
                                  CircleAvatar(
                                    radius: 22,
                                    backgroundColor: Colors.teal.shade100,
                                    child: const Icon(
                                      Icons.currency_rupee,
                                      color: Colors.teal,
                                      size: 20,
                                    ),
                                  ),

                                  const SizedBox(width: 12),

                                  // Category + Time
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          expense.category,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 15,
                                          ),
                                        ),
                                        // const SizedBox(height: 2),
                                        Text(
                                          formatExpenseTime(expense.date),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Amount / Delete
                                  IntrinsicWidth(
                                    child: AnimatedSwitcher(
                                      duration: const Duration(
                                        milliseconds: 200,
                                      ),
                                      transitionBuilder: (child, animation) =>
                                          ScaleTransition(
                                            scale: animation,
                                            child: child,
                                          ),
                                      child: isSelected
                                          ? IconButton(
                                              key: const ValueKey('delete'),
                                              icon: const Icon(
                                                Icons.delete_outline,
                                                color: Colors.red,
                                                size: 27,
                                              ),
                                              splashRadius: 18,
                                              onPressed: () =>
                                                  _deleteExpense(expense.id),
                                            )
                                          : Align(
                                              key: const ValueKey('amount'),
                                              alignment: Alignment.centerRight,
                                              child: Text(
                                                '₹${expense.amount.toStringAsFixed(2)}',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 17,
                                                ),
                                              ),
                                            ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),

            // if (_canAddExpense)
            //   SizedBox(
            //     width: double.infinity,
            //     child: ElevatedButton(
            //       onPressed: _addExpense,
            //       child: const Text('Add Expense'),
            //     ),
            //   ),
          ],
        ),
      ),
    );
  }
}
