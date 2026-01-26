import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../db/database_helper.dart';

class ReportsTab extends StatefulWidget {
  const ReportsTab({super.key});

  @override
  State<ReportsTab> createState() => _ReportsTabState();
}

class _ReportsTabState extends State<ReportsTab> {
  double _totalExpense = 0;
  Map<String, double> _monthly = {};
  int? _selectedMonth; // 0–11
  Map<String, double> _filteredCategories = {};
  String _monthName(int index) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[index];
  }

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  // Map of common categories → icons
  final Map<String, IconData> _defaultCategoryIcons = {
    'food': Icons.restaurant,
    'groceries': Icons.shopping_cart,
    'shopping': Icons.shopping_bag,
    'taxi fare': Icons.local_taxi,
    'sweets': Icons.cake,
    'entertainment': Icons.movie,
    'health': Icons.local_hospital,
    'utilities': Icons.lightbulb,
    'travel': Icons.flight,
    'other': Icons.category,
  };

  IconData _categoryIcon(String category) {
    // Try to find icon for lowercased category
    return _defaultCategoryIcons[category.toLowerCase()] ?? Icons.category;
  }

  Future<void> _loadReports() async {
    final db = DatabaseHelper.instance;

    final total = await db.getTotalExpense();
    final monthly = await db.getMonthlyExpenses();
    final categories = await db.getCategoryWiseExpense();

    setState(() {
      _totalExpense = total;
      _monthly = monthly;
      _filteredCategories = categories; // default
      _selectedMonth = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _totalExpenseCard(),
        const SizedBox(height: 20),
        _monthlyExpenseChart(),
        const SizedBox(height: 20),
        _categoryReport(),
      ],
    );
  }

  Widget _totalExpenseCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TOTAL EXPENSE',
            style: TextStyle(
              fontSize: 12,
              letterSpacing: 1.2,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '₹ ${_totalExpense.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 38,
              fontWeight: FontWeight.w700,
              color: Colors.lightBlue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _monthlyExpenseChart() {
    final now = DateTime.now();
    final year = now.year;

    // Prepare 12 months data (Jan–Dec)
    final List<double> monthValues = List.filled(12, 0);

    _monthly.forEach((key, value) {
      // key format: yyyy-MM
      final month = int.parse(key.substring(5, 7));
      monthValues[month - 1] = value;
    });

    final maxY = monthValues
        .reduce((a, b) => a > b ? a : b)
        .clamp(1.0, double.infinity);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Monthly Expense ($year)',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 240,
              child: BarChart(
                BarChartData(
                  maxY: maxY,

                  barTouchData: BarTouchData(
                    enabled: true,
                    handleBuiltInTouches: true,
                    touchCallback: (event, response) async {
                      if (response == null ||
                          response.spot == null ||
                          !event.isInterestedForInteractions) {
                        return;
                      }

                      final index = response.spot!.touchedBarGroupIndex;
                      final now = DateTime.now();

                      final data = await DatabaseHelper.instance
                          .getCategoryWiseExpenseByMonth(now.year, index + 1);

                      if (!mounted) return;

                      setState(() {
                        _selectedMonth = index;
                        _filteredCategories = data;
                      });
                    },
                    touchTooltipData: BarTouchTooltipData(
                      tooltipBgColor: Colors.black87,
                      getTooltipItem: (group, _, rod, __) {
                        const months = [
                          'Jan',
                          'Feb',
                          'Mar',
                          'Apr',
                          'May',
                          'Jun',
                          'Jul',
                          'Aug',
                          'Sep',
                          'Oct',
                          'Nov',
                          'Dec',
                        ];
                        return BarTooltipItem(
                          '${months[group.x.toInt()]}\n₹ ${rod.toY.toStringAsFixed(2)}',
                          const TextStyle(color: Colors.white),
                        );
                      },
                    ),
                  ),

                  barGroups: List.generate(12, (index) {
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: monthValues[index],
                          width: 14,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ],
                    );
                  }),

                  gridData: FlGridData(show: false),
                  borderData: FlBorderData(show: false),

                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          const months = [
                            'Jan',
                            'Feb',
                            'Mar',
                            'Apr',
                            'May',
                            'Jun',
                            'Jul',
                            'Aug',
                            'Sep',
                            'Oct',
                            'Nov',
                            'Dec',
                          ];
                          return Text(
                            months[value.toInt()],
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _categoryReport() {
    final total = _filteredCategories.values.fold(0.0, (a, b) => a + b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _selectedMonth == null
              ? 'Expense by Category (All Time)'
              : 'Expense by Category (${_monthName(_selectedMonth!)})',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),

        if (_filteredCategories.isEmpty)
          const Text('No expense for this period'),

        ..._filteredCategories.entries.map((e) {
          final percent = total == 0 ? 0.0 : (e.value / total);
          final percentText = (percent * 100).toStringAsFixed(1);

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.grey.shade200,
                  child: Icon(
                    _categoryIcon(e.key),
                    size: 16,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(width: 8),

                // Expanded column for label, percentage, progress
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Row: Category + Percentage + Amount
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(
                                e.key,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '$percentText%',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '₹ ${e.value.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 6),

                      // Progress bar below the row
                      LayoutBuilder(
                        builder: (context, constraints) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: percent,
                              minHeight: 6,
                              backgroundColor: Colors.grey.shade300,
                              valueColor: const AlwaysStoppedAnimation(
                                Colors.blue,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
