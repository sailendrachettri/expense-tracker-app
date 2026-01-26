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
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Total Expense',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              '₹ ${_totalExpense.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.redAccent,
              ),
            ),
          ],
        ),
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
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
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
              const Text('No expense for this month'),

            ..._filteredCategories.entries.map(
              (e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(e.key),
                    Text(
                      '₹ ${e.value.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
