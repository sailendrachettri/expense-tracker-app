import 'package:expense_tracker_app/utils/formate_date_time.dart';
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

  List<String> _borrowers = [];

  bool get _canAddBorrow {
    final amount = double.tryParse(_amountController.text);
    return amount != null && amount > 0 && _selectedBorrower != null;
  }

  @override
  void initState() {
    super.initState();
    _loadBorrowers();
    _loadBorrows();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _loadBorrowers() async {
    final data = await DatabaseHelper.instance.getBorrowers();
    setState(() {
      _borrowers = data;
    });
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

  void _showAddBorrowerDialog() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Borrower'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'e.g. John, Mom, HDFC Bank',
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

              await DatabaseHelper.instance.insertBorrower(
                controller.text.trim(),
              );

              Navigator.pop(context);
              _loadBorrowers();
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  int? _selectedBorrowIndex;

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

            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  'Borrowed From',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
                const SizedBox(width: 10),
                InkWell(
                  onTap: _showAddBorrowerDialog,
                  borderRadius: BorderRadius.circular(999),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Icon(Icons.add_circle, size: 17),
                  ),
                ),
              ],
            ),

            // Borrower selector (like category chips)
            Wrap(
              spacing: 10,
              children: _borrowers.map((person) {
                return ChoiceChip(
                  label: Text(person, style: TextStyle(fontSize: 10)),
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
                        final isSelected = _selectedBorrowIndex == index;

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedBorrowIndex = isSelected ? null : index;
                            });
                          },
                          child: Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: isSelected ? 3 : 1.5,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              child: Row(
                                children: [
                                  // Avatar
                                  CircleAvatar(
                                    backgroundColor: Colors.orange.shade100,
                                    child: const Icon(
                                      Icons.person,
                                      color: Colors.orange,
                                    ),
                                  ),

                                  const SizedBox(width: 12),

                                  // Person + time
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          borrow.person,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 15,
                                          ),
                                        ),
                                        Text(
                                          formatExpenseTime(borrow.date),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Amount / Delete switcher
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
                                              ),
                                              splashRadius: 18,
                                              onPressed: () =>
                                                  _deleteBorrow(borrow.id),
                                            )
                                          : Align(
                                              key: const ValueKey('amount'),
                                              alignment: Alignment.centerRight,
                                              child: Text(
                                                '₹${borrow.amount.toStringAsFixed(2)}',
                                                maxLines: 1,
                                                softWrap: false,
                                                textAlign: TextAlign.right,
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
