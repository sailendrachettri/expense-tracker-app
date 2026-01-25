import 'package:flutter/material.dart';
import '../../models/expense.dart';
import '../../db/database_helper.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final TextEditingController _amountController = TextEditingController();
  String? _selectedCategory;

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

            // Amount input
            TextField(
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

            const SizedBox(height: 20),

            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                const Text(
                  'Select Category',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 6),
                TextButton.icon(
                  onPressed: _showAddCategoryDialog,
                  icon: const Icon(Icons.add_circle, size: 18),
                  label: const Text(''),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            Wrap(
              spacing: 10,
              children: _categories.map((category) {
                return ChoiceChip(
                  label: Text(category, style: TextStyle(fontSize: 10)),
                  selected: _selectedCategory == category,
                  onSelected: (_) {
                    setState(() {
                      _selectedCategory = category;
                    });
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            const Text(
              'Today',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.teal.shade100,
                              child: const Icon(
                                Icons.currency_rupee,
                                color: Colors.teal,
                              ),
                            ),
                            title: Text(expense.category),
                            subtitle: Text(
                              '₹${expense.amount.toStringAsFixed(2)}',
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteExpense(expense.id),
                            ),
                          ),
                        );
                      },
                    ),
            ),

            if (_canAddExpense)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _addExpense,
                  child: const Text('Add Expense'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
