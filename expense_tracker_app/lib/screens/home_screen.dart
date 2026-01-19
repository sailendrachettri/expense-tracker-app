import 'package:flutter/material.dart';
import '../constants/categories.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final TextEditingController _amountController = TextEditingController();
  String? _selectedCategory;

  bool get _canAddExpense {
    return _amountController.text.isNotEmpty && _selectedCategory != null;
  }

  void _addExpense() {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || _selectedCategory == null) return;

    // Later: save expense to list / database
    debugPrint('Added ₹$amount for $_selectedCategory');

    _amountController.clear();
    setState(() {
      _selectedCategory = null;
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
              decoration: const InputDecoration(
                prefixText: '₹ ',
                labelText: 'Amount (INR)',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),

            const SizedBox(height: 20),

            const Text(
              'Select Category',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),

            const SizedBox(height: 10),

            // Category chips
            Wrap(
              spacing: 10,
              children: expenseCategories.map((category) {
                final isSelected = _selectedCategory == category;
                return ChoiceChip(
                  label: Text(category),
                  selected: isSelected,
                  onSelected: (_) {
                    setState(() {
                      _selectedCategory = category;
                    });
                  },
                );
              }).toList(),
            ),

            const Spacer(),

            // Add button (conditional)
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
