import 'package:flutter/material.dart';
import '../models/expense.dart';
import '../widgets/expense_list.dart';
import '../widgets/add_expense_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Expense> _expenses = [];

  void _addExpense(String title, double amount) {
    final newExpense = Expense(
      id: DateTime.now().toString(),
      title: title,
      amount: amount,
      date: DateTime.now(),
    );

    setState(() {
      _expenses.add(newExpense);
    });
  }

  void _removeExpense(String id) {
    setState(() {
      _expenses.removeWhere((e) => e.id == id);
    });
  }

  double get totalExpense {
    return _expenses.fold(0, (sum, item) => sum + item.amount);
  }

  void _openAddExpenseSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => AddExpenseSheet(onAddExpense: _addExpense),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Tracker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _openAddExpenseSheet,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Total: ₹${totalExpense.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          Expanded(
            child: ExpenseList(
              expenses: _expenses,
              onDelete: _removeExpense,
            ),
          ),
        ],
      ),
    );
  }
}
