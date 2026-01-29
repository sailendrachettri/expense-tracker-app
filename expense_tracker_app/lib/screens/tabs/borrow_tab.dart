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

  Map<String, List<Borrow>> _groupBorrowsByPerson() {
    final Map<String, List<Borrow>> map = {};
    for (final borrow in _borrows) {
      map.putIfAbsent(borrow.person, () => []).add(borrow);
    }
    return map;
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
                      labelStyle: const TextStyle(color: Colors.green),
                      floatingLabelStyle: const TextStyle(color: Colors.green),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: Colors.green,
                          width: 1.5,
                        ),
                      ),

                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: Color.fromARGB(184, 111, 215, 115),
                          width: 2,
                        ),
                      ),

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
                    child: const Text(
                      'Add',
                      style: TextStyle(
                        color: Colors.green, // change to any color you want
                        fontWeight: FontWeight.bold, // optional
                        fontSize: 16, // optional
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  'Who did you borrow from?',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 17),
                ),
                const SizedBox(width: 10),
              ],
            ),

            // Borrower selector (like category chips)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  ..._borrowers.map((person) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: GestureDetector(
                        onLongPress: () async {
                          final shouldDelete = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Delete Borrower'),
                              content: Text('Delete "$person"?'),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
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
                            await DatabaseHelper.instance.deleteBorrower(
                              person,
                            );

                            setState(() {
                              _borrowers.remove(person);
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
                          label: Text(
                            person,
                            style: TextStyle(
                              fontSize: 10,
                              color: _selectedBorrower == person
                                  ? Colors.green
                                  : Colors.black,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          selected: _selectedBorrower == person,
                          backgroundColor: Colors.white,
                          checkmarkColor: Colors.green,
                          selectedColor: const Color.fromARGB(
                            255,
                            227,
                            238,
                            228,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: const BorderSide(
                              color: Colors.green,
                              width: 0.8,
                            ),
                          ),
                          onSelected: (_) {
                            setState(() {
                              _selectedBorrower = person;
                            });
                          },
                        ),
                      ),
                    );
                  }),

                  // ➕ Add borrower (same style as category add)
                  Material(
                    color: Colors.transparent, // keep background clean
                    shape: const CircleBorder(),
                    child: InkWell(
                      onTap: _showAddBorrowerDialog,
                      customBorder:
                          const CircleBorder(), // 👈 forces circular ripple
                      child: const Padding(
                        padding: EdgeInsets.all(
                          6,
                        ), // equal padding = perfect circle
                        child: Icon(
                          Icons.add_circle,
                          size: 17,
                          color: Colors.green,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
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
                    color: Colors.green,
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
                  : ListView(
                      children: _groupBorrowsByPerson().entries.map((entry) {
                        final borrower = entry.key;
                        final borrowsForPerson = entry.value;

                        double totalAmount = borrowsForPerson.fold(
                          0.0,
                          (sum, b) => sum + b.amount,
                        );

                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),

                          child: Theme(
                            data: Theme.of(context).copyWith(
                              dividerColor: Colors
                                  .transparent, // hides the top/bottom line
                            ),
                            child: ExpansionTile(
                              key: PageStorageKey(borrower),
                              title: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: Colors.green.shade100,
                                        child: const Icon(
                                          Icons.people_outline_outlined,
                                          color: Colors.green,
                                        ),
                                      ),

                                      const SizedBox(width: 10),
                                      Text(
                                        borrower,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    '₹${totalAmount.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                              children: [
                                // PAY ALL BUTTON
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 4,
                                  ),
                                  child: Align(
                                    alignment: Alignment.center,
                                    child: ElevatedButton.icon(
                                      icon: const Icon(
                                        Icons.payments_outlined,
                                        color: Colors.green,
                                        size: 18,
                                      ),
                                      label: const Text(
                                        'Pay All',
                                        style: TextStyle(
                                          color: Colors.green,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        minimumSize: const Size(100, 36),
                                      ),
                                      onPressed: () async {
                                        final confirmed = await showDialog<bool>(
                                          context: context,
                                          builder: (_) => AlertDialog(
                                            title: const Text(
                                              'Pay Full Amount?',
                                            ),
                                            content: Text(
                                              'Have you repaid the full amount of ₹${totalAmount.toStringAsFixed(2)} to $borrower?',
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(
                                                  context,
                                                  false,
                                                ),
                                                child: const Text('Cancel'),
                                              ),
                                              ElevatedButton(
                                                onPressed: () => Navigator.pop(
                                                  context,
                                                  true,
                                                ),
                                                child: const Text('Yes, Paid'),
                                              ),
                                            ],
                                          ),
                                        );

                                        if (confirmed == true) {
                                          // Delete all borrows for this borrower
                                          for (final b in borrowsForPerson) {
                                            await _deleteBorrow(b.id);
                                          }
                                        }
                                      },
                                    ),
                                  ),
                                ),

                                // INDIVIDUAL BORROWS
                                ...borrowsForPerson.asMap().entries.map((e) {
                                  final index = e.key;
                                  final borrow = e.value;
                                  final isSelected =
                                      _selectedBorrowIndex ==
                                      borrow.id.hashCode;

                                  return GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _selectedBorrowIndex = isSelected
                                            ? null
                                            : borrow.id.hashCode;
                                      });
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 4,
                                      ),
                                      child: Card(
                                        color: isSelected
                                            ? Color.fromARGB(255, 220, 240, 220)
                                            : const Color.fromARGB(109, 220, 240, 220),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        elevation: isSelected ? 1 : 0,
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 10,
                                          ),
                                          child: Row(
                                            children: [
                                              CircleAvatar(
                                                backgroundColor:
                                                    Colors.green.shade100,
                                                    radius: 17,
                                                    
                                                child: const Icon(
                                                  Icons.wallet,
                                                  color: Colors.green,
                                                  size: 16,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      formatExpenseTime(
                                                        borrow.date,
                                                      ),
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors
                                                            .grey
                                                            .shade600,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              IntrinsicWidth(
                                                child: AnimatedSwitcher(
                                                  duration: const Duration(
                                                    milliseconds: 200,
                                                  ),
                                                  transitionBuilder:
                                                      (child, animation) =>
                                                          ScaleTransition(
                                                            scale: animation,
                                                            child: child,
                                                          ),
                                                  child: isSelected
                                                      ? TextButton.icon(
                                                          key: const ValueKey(
                                                            'pay',
                                                          ),
                                                          icon: const Icon(
                                                            Icons
                                                                .payments_outlined,
                                                            color: Colors.green,
                                                            size: 20,
                                                          ),
                                                          label: const Text(
                                                            'Pay',
                                                            style: TextStyle(
                                                              color:
                                                                  Colors.green,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                            ),
                                                          ),
                                                          onPressed: () =>
                                                              _confirmRepay(
                                                                borrow,
                                                              ),
                                                        )
                                                      : Align(
                                                          key: const ValueKey(
                                                            'amount',
                                                          ),
                                                          alignment: Alignment
                                                              .centerRight,
                                                          child: Text(
                                                            '₹${borrow.amount.toStringAsFixed(2)}',
                                                            maxLines: 1,
                                                            softWrap: false,
                                                            textAlign:
                                                                TextAlign.right,
                                                            style:
                                                                const TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
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
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
