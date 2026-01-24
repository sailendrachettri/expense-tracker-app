import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../models/borrow.dart';

class AddBorrowSheet extends StatefulWidget {
  const AddBorrowSheet({super.key});

  @override
  State<AddBorrowSheet> createState() => _AddBorrowSheetState();
}

class _AddBorrowSheetState extends State<AddBorrowSheet> {
  final _personController = TextEditingController();
  final _amountController = TextEditingController();

  Future<void> _submit() async {
    final person = _personController.text;
    final amount = double.tryParse(_amountController.text);

    if (person.isEmpty || amount == null || amount <= 0) return;

    final borrow = Borrow(
      id: DateTime.now().toString(),
      person: person,
      amount: amount,
      date: DateTime.now(),
    );

    await DatabaseHelper.instance.insertBorrow(borrow);

    Navigator.of(context).pop(true);
  }

  @override
  void dispose() {
    _personController.dispose();
    _amountController.dispose();
    super.dispose();
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
          // Borrowed From (like Title)
          TextField(
            controller: _personController,
            decoration: const InputDecoration(
              labelText: 'Borrowed From',
            ),
          ),

          // Amount
          TextField(
            controller: _amountController,
            decoration: const InputDecoration(
              labelText: 'Amount',
              prefixText: '₹ ',
            ),
            keyboardType: TextInputType.number,
          ),

          const SizedBox(height: 12),

          ElevatedButton(
            onPressed: _submit,
            child: const Text('Add Borrow'),
          ),
        ],
      ),
    );
  }
}
