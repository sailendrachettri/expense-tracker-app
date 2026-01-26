import 'package:flutter/material.dart';
import '../../models/expense.dart';
import '../../db/database_helper.dart';
import '../../utils/formate_date_time.dart';
import '../../utils/formate_pretty_date.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final TextEditingController _amountController = TextEditingController();

  String? _selectedCategory;

  double get totalExpenseAmountToday {
    return _expensesByDate.fold(0.0, (sum, e) => sum + e.amount);
  }

  final List<Expense> _expensesByDate = [];
  List<String> _categories = [];

  bool get _canAddExpense =>
      _amountController.text.isNotEmpty && _selectedCategory != null;

  @override
  void initState() {
    super.initState();
    _loadExpensesByDate();
    _loadCategories();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _showAddCategoryDialog() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Category'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'e.g. Entertainment, Bills',
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

              await DatabaseHelper.instance.insertCategory(
                controller.text.trim(),
              );

              Navigator.pop(context);
              _loadCategories();
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  DateTime _selectedDate = DateTime.now();

  Future<void> _loadExpensesByDate() async {
    final expenses = await DatabaseHelper.instance.getExpensesByDate(
      _selectedDate,
    );
    setState(() {
      _expensesByDate
        ..clear()
        ..addAll(expenses);
    });
  }

  Future<void> _loadCategories() async {
    final data = await DatabaseHelper.instance.getCategories();
    setState(() {
      _categories = data;
    });
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
      _expensesByDate.insert(0, expense);
      _amountController.clear();
      _selectedCategory = null;
    });
  }

  Future<void> _deleteExpense(String id) async {
    await DatabaseHelper.instance.deleteExpense(id);
    setState(() {
      _expensesByDate.removeWhere((e) => e.id == id);
    });
  }

  Future<void> _confirmDeleteExpense(Expense expense) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Mark as Delete?'),
        content: Text(
          'Delete this expense of ₹${expense.amount.toStringAsFixed(2)} for ${expense.category} ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes, Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _deleteExpense(expense.id);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(), // disable future dates
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _loadExpensesByDate();
      });
    }
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  int? _selectedExpenseIndex;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Daily Expense',
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
                      if (_canAddExpense) {
                        _addExpense();
                      }
                      else if(_amountController.text.isEmpty){
                         ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Please enter a valid amount.',
                            ),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      } else if(_selectedCategory == null){
                         ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Please select category',
                            ),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                       else {
                        // Show info
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Please enter valid amount and select category',
                            ),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _canAddExpense
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
              textBaseline: TextBaseline.alphabetic,
              children: [
                const Text(
                  'Select Category',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
                const SizedBox(width: 10),
                InkWell(
                  onTap: _showAddCategoryDialog,
                  borderRadius: BorderRadius.circular(999),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Icon(Icons.add_circle, size: 17),
                  ),
                ),
              ],
            ),

            // Wrap(
            //   spacing: 10,
            //   children: _categories.map((category) {
            //     return ChoiceChip(
            //       label: Text(category, style: TextStyle(fontSize: 10)),
            //       selected: _selectedCategory == category,
            //       shape: RoundedRectangleBorder(
            //         borderRadius: BorderRadius.circular(20),
            //       ),
            //       onSelected: (_) {
            //         setState(() {
            //           _selectedCategory = category;
            //         });
            //       },
            //     );
            //   }).toList(),
            // ),

            Wrap(
              spacing: 10,
              children: _categories.map((category) {
                return GestureDetector(
                  onLongPress: () async {
                    final shouldDelete = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Delete Category'),
                        content: Text('Delete "$category"?'),
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
                      await DatabaseHelper.instance.deleteBorrower(category);

                      setState(() {
                        _categories.remove(category);

                        // reset selection if deleted borrower was selected
                        if (_selectedCategory == category) {
                          _selectedCategory = null;
                        }
                      });
                    }
                  },
                  child: ChoiceChip(
                    label: Text(category, style: const TextStyle(fontSize: 10)),
                    selected: _selectedCategory == category,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    onSelected: (_) {
                      setState(() {
                        _selectedCategory = category;
                      });
                    },
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_left),
                  onPressed: () {
                    setState(() {
                      _selectedDate = _selectedDate.subtract(
                        const Duration(days: 1),
                      );
                      _loadExpensesByDate();
                    });
                  },
                ),
                InkWell(
                  onTap: _pickDate,
                  child: Row(
                    children: [
                      Text(
                        _isToday(_selectedDate)
                            ? 'Today'
                            : formatPrettyDate(_selectedDate),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(width: 4),
                      const Icon(Icons.calendar_month, size: 18),
                    ],
                  ),
                ),

                if (!_isToday(_selectedDate))
                  IconButton(
                    icon: const Icon(Icons.arrow_right),
                    onPressed: () {
                      setState(() {
                        _selectedDate = _selectedDate.add(
                          const Duration(days: 1),
                        );
                        _loadExpensesByDate();
                      });
                    },
                  ),
                const Spacer(),
                Text(
                  '₹${_expensesByDate.fold(0.0, (sum, e) => sum + e.amount).toStringAsFixed(2)}',
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

            // DAILY EXPENSE HISTORY
            Expanded(
              child: _expensesByDate.isEmpty
                  ? const Center(
                      child: Text(
                        'No expenses added today',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _expensesByDate.length,
                      itemBuilder: (context, index) {
                        final expense = _expensesByDate[index];
                        final isSelected = _selectedExpenseIndex == index;

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedExpenseIndex = isSelected ? null : index;
                            });
                          },
                          child: Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            elevation: isSelected ? 3 : 1.5,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              child: Row(
                                children: [
                                  // Icon
                                  CircleAvatar(
                                    radius: 22,
                                    backgroundColor: Colors.teal.shade100,
                                    child: const Icon(
                                      Icons.currency_rupee,
                                      color: Colors.teal,
                                      size: 20,
                                    ),
                                  ),

                                  const SizedBox(width: 12),

                                  // Category + Time
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          expense.category,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 15,
                                          ),
                                        ),
                                        // const SizedBox(height: 2),
                                        Text(
                                          formatExpenseTime(expense.date),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Amount / Delete
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
                                                size: 27,
                                              ),
                                              splashRadius: 18,
                                              onPressed: () =>
                                                  _confirmDeleteExpense(
                                                    expense,
                                                  ),
                                            )
                                          : Align(
                                              key: const ValueKey('amount'),
                                              alignment: Alignment.centerRight,
                                              child: Text(
                                                '₹${expense.amount.toStringAsFixed(2)}',
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

            // if (_canAddExpense)
            //   SizedBox(
            //     width: double.infinity,
            //     child: ElevatedButton(
            //       onPressed: _addExpense,
            //       child: const Text('Add Expense'),
            //     ),
            //   ),
          ],
        ),
      ),
    );
  }
}
