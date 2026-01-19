import 'package:flutter/material.dart';

class AddExpenseSheet extends StatefulWidget {
  final Function(String, double) onAddExpense;

  const AddExpenseSheet({
    super.key,
    required this.onAddExpense,
  });

  @override
  State<AddExpenseSheet> createState() => _AddExpenseSheetState();
}

class _AddExpenseSheetState extends State<AddExpenseSheet> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();

  void _submit() {
    final title = _titleController.text;
    final amount = double.tryParse(_amountController.text);

    if (title.isEmpty || amount == null || amount <= 0) return;

    widget.onAddExpense(title, amount);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(labelText: 'Title'),
          ),
          TextField(
            controller: _amountController,
            decoration: const InputDecoration(labelText: 'Amount'),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _submit,
            child: const Text('Add Expense'),
          ),
        ],
      ),
    );
  }
}
