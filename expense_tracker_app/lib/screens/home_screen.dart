import 'package:flutter/material.dart';
import '../constants/categories.dart';
import '../models/expense.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final TextEditingController _amountController = TextEditingController();
  String? _selectedCategory;

  final List<Expense> _todayExpenses = [];

  bool get _canAddExpense {
    return _amountController.text.isNotEmpty && _selectedCategory != null;
  }

  void _addExpense() {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || _selectedCategory == null) return;

    final expense = Expense(
      id: DateTime.now().toString(),
      category: _selectedCategory!,
      amount: amount,
      date: DateTime.now(),
    );

    setState(() {
      _todayExpenses.insert(0, expense);
      _amountController.clear();
      _selectedCategory = null;
    });
  }

  void _deleteExpense(String id) {
    setState(() {
      _todayExpenses.removeWhere((e) => e.id == id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _currentIndex == 0 ? _homeTab() : _reportsTab(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Reports',
          ),
        ],
      ),
    );
  }

  // ---------------- HOME TAB ----------------

  Widget _homeTab() {
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

            const Text(
              'Select Category',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),

            const SizedBox(height: 10),

            Wrap(
              spacing: 10,
              children: expenseCategories.map((category) {
                return ChoiceChip(
                  label: Text(category),
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
                              onPressed: () =>
                                  _deleteExpense(expense.id),
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

  // ---------------- REPORTS TAB ----------------

  Widget _reportsTab() {
    return const Center(
      child: Text(
        'Reports coming soon 📊',
        style: TextStyle(fontSize: 18),
      ),
    );
  }
}
