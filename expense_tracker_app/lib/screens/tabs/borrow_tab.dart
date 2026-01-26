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

  double get totalBorrowAmount {
    return _borrows.fold(0.0, (sum, e) => sum + e.amount);
  }

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

  Future<void> _confirmRepay(Borrow borrow) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Mark as Paid?'),
        content: Text(
          'Have you repaid ₹${borrow.amount.toStringAsFixed(2)} to ${borrow.person}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes, Paid'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _deleteBorrow(borrow.id);
    }
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
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            Row(
              children: [
                // Amount input
                Expanded(
                  child: TextField(
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
                ),

                const SizedBox(width: 12),

                // Add button
                SizedBox(
                  height: 46, // matches TextField height
                  width: 100,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_canAddBorrow) {
                        _addBorrow();
                      } else if (_amountController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please enter a valid amount.'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      } else if (_selectedBorrower == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please select Borrowed from'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      } else {
                        // Show info
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Please enter valid amount and select Borrowed from!',
                            ),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _canAddBorrow
                          ? null
                          : Colors.grey.shade200, // optional visual hint
                    ),
                    child: const Text('Add'),
                  ),
                ),
              ],
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
                return GestureDetector(
                  onLongPress: () async {
                    final shouldDelete = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Delete borrower'),
                        content: Text('Delete "$person"?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text(
                              'Delete',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    );

                    if (shouldDelete == true) {
                      await DatabaseHelper.instance.deleteBorrower(person);

                      setState(() {
                        _borrowers.remove(person);

                        // reset selection if deleted borrower was selected
                        if (_selectedBorrower == person) {
                          _selectedBorrower = null;
                        }
                      });

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('$person deleted')),
                      );
                    }
                  },
                  child: ChoiceChip(
                    label: Text(person, style: const TextStyle(fontSize: 10)),
                    selected: _selectedBorrower == person,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    onSelected: (_) {
                      setState(() {
                        _selectedBorrower = person;
                      });
                    },
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            Row(
              children: [
                const Text(
                  'Due Amount',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Text(
                  '₹${totalBorrowAmount.toStringAsFixed(2)}',
                  maxLines: 1,
                  softWrap: false,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
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
                                          ? TextButton.icon(
                                              key: const ValueKey('pay'),
                                              icon: const Icon(
                                                Icons.payments_outlined,
                                                color: Colors.green,
                                                size: 20,
                                              ),
                                              label: const Text(
                                                'Pay',
                                                style: TextStyle(
                                                  color: Colors.green,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              onPressed: () =>
                                                  _confirmRepay(borrow),
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
          ],
        ),
      ),
    );
  }
}
