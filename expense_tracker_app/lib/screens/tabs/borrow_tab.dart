import 'package:flutter/material.dart';
import '../../models/borrow.dart';
import '../../db/database_helper.dart';

class BorrowTab extends StatefulWidget {
  const BorrowTab({super.key});

  @override
  State<BorrowTab> createState() => _BorrowTabState();
}

class _BorrowTabState extends State<BorrowTab> {
  final TextEditingController _amountController = TextEditingController();
  String? _selectedBorrower;

  final List<Borrow> _borrows = [];

  final List<String> _borrowers = [
    'Friend',
    'Family',
    'Office Colleague',
    'Bank',
    'Other',
  ];

  bool get _canAddBorrow {
    final amount = double.tryParse(_amountController.text);
    return amount != null && amount > 0 && _selectedBorrower != null;
  }

  @override
  void initState() {
    super.initState();
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
      _borrows
        ..clear()
        ..addAll(data);
    });
  }

  Future<void> _addBorrow() async {
    if (!_canAddBorrow) return;

    final borrow = Borrow(
      id: DateTime.now().toString(),
      person: _selectedBorrower!,
      amount: double.parse(_amountController.text),
      date: DateTime.now(),
    );

    await DatabaseHelper.instance.insertBorrow(borrow);

    setState(() {
      _borrows.insert(0, borrow);
      _amountController.clear();
      _selectedBorrower = null;
    });
  }

  Future<void> _deleteBorrow(String id) async {
    await DatabaseHelper.instance.deleteBorrow(id);
    _loadBorrows();
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
              'Add Borrow',
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
}
