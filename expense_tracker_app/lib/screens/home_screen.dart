import 'package:flutter/material.dart';
import '../constants/categories.dart';
import '../models/expense.dart';
import '../db/database_helper.dart';
import '../models/borrow.dart';
import '../widgets/add_borrow_sheet.dart';

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
  final List<Borrow> _borrows = [];

  bool get _canAddExpense {
    return _amountController.text.isNotEmpty && _selectedCategory != null;
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

  @override
  void initState() {
    super.initState();
    _loadTodayExpenses();
    _loadBorrows();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _loadBorrows() async {
    final data = await DatabaseHelper.instance.getBorrows();
    setState(() {
      _borrows.clear();
      _borrows.addAll(data);
    });
  }

  void _openAddBorrowSheet() async {
    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => const AddBorrowSheet(),
    );

    if (result == true) {
      _loadBorrows(); // refresh list
    }
  }

  Future<void> _deleteBorrow(String id) async {
    await DatabaseHelper.instance.deleteBorrow(id);
    _loadBorrows();
  }

  Future<void> _loadTodayExpenses() async {
    final expenses = await DatabaseHelper.instance.getTodayExpenses();
    setState(() {
      _todayExpenses.clear();
      _todayExpenses.addAll(expenses);
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
    final List<Widget> pages = [_homeTab(), _borrowTab(), _reportsTab()];
    return Scaffold(
      body: pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.swap_horiz),
            label: 'Borrow',
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

  // ---------------- BORROW TAB ----------------

  final _borrowAmountController = TextEditingController();
  String? _selectedBorrower;

  bool get _canAddBorrow {
    final amount = double.tryParse(_borrowAmountController.text);
    return amount != null && amount > 0 && _selectedBorrower != null;
  }

  final List<String> _borrowers = [
    'Friend',
    'Family',
    'Office Colleague',
    'Bank',
    'Other',
  ];

  Future<void> _addBorrow() async {
    if (!_canAddBorrow) return;

    final borrow = Borrow(
      id: DateTime.now().toString(),
      person: _selectedBorrower!,
      amount: double.parse(_borrowAmountController.text),
      date: DateTime.now(),
    );

    await DatabaseHelper.instance.insertBorrow(borrow);

    setState(() {
      _borrows.insert(0, borrow);
      _borrowAmountController.clear();
      _selectedBorrower = null;
    });
  }

  Widget _borrowTab() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add Borrow',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 20),

            // Amount input
            TextField(
              controller: _borrowAmountController,
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
              'Borrowed From',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),

            const SizedBox(height: 10),

            // Borrower selector (like category chips)
            Wrap(
              spacing: 10,
              children: _borrowers.map((person) {
                return ChoiceChip(
                  label: Text(person),
                  selected: _selectedBorrower == person,
                  onSelected: (_) {
                    setState(() {
                      _selectedBorrower = person;
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

            // TODAY BORROW HISTORY
            Expanded(
              child: _borrows.isEmpty
                  ? const Center(
                      child: Text(
                        'No borrowings added today',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _borrows.length,
                      itemBuilder: (context, index) {
                        final borrow = _borrows[index];

                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.orange.shade100,
                              child: const Icon(
                                Icons.person,
                                color: Colors.orange,
                              ),
                            ),
                            title: Text(borrow.person),
                            subtitle: Text(
                              '₹${borrow.amount.toStringAsFixed(2)}',
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteBorrow(borrow.id),
                            ),
                          ),
                        );
                      },
                    ),
            ),

            // ADD BUTTON (only when valid)
            if (_canAddBorrow)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _addBorrow,
                  child: const Text('Add Borrow'),
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
      child: Text('Reports coming soon 📊', style: TextStyle(fontSize: 18)),
    );
  }
}
