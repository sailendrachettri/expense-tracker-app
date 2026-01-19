import 'package:flutter/material.dart';
import '../models/expense.dart';
import 'expense_item.dart';

class ExpenseList extends StatelessWidget {
  final List<Expense> expenses;
  final Function(String) onDelete;

  const ExpenseList({
    super.key,
    required this.expenses,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (expenses.isEmpty) {
      return const Center(
        child: Text('No expenses added yet'),
      );
    }

    return ListView.builder(
      itemCount: expenses.length,
      itemBuilder: (ctx, index) {
        return ExpenseItem(
          expense: expenses[index],
          onDelete: onDelete,
        );
      },
    );
  }
}
