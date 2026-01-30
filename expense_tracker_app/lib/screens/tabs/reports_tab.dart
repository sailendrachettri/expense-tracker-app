import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../db/database_helper.dart';

class ReportsTab extends StatefulWidget {
  const ReportsTab({super.key});

  @override
  State<ReportsTab> createState() => _ReportsTabState();
}

class _ReportsTabState extends State<ReportsTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _db = DatabaseHelper.instance;
  final _now = DateTime.now();

  double _totalExpense = 0;

  // Data
  Map<int, double> _weekly = {};
  Map<String, double> _monthly = {};
  Map<String, double> _yearly = {};
  Map<String, double> _categories = {};

  int? _selectedWeek;
  int? _selectedMonth;
  String? _selectedYear;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChange);
    _loadWeekly(); // default
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _totalExpenseLabel() {
    if (_selectedWeek != null) {
      return 'TOTAL EXPENSE · WEEK $_selectedWeek';
    }

    if (_selectedMonth != null) {
      return 'TOTAL EXPENSE · ${_monthLabels()[_selectedMonth! - 1].toUpperCase()}';
    }

    if (_selectedYear != null) {
      return 'TOTAL EXPENSE · $_selectedYear';
    }

    return 'TOTAL EXPENSE';
  }

  // ================= LOADERS =================

  Future<void> _onTabChange() async {
    if (_tabController.indexIsChanging) return;

    switch (_tabController.index) {
      case 0:
        await _loadWeekly();
        break;
      case 1:
        await _loadMonthly();
        break;
      case 2:
        await _loadYearly();
        break;
    }
  }

  Future<void> _loadWeekly() async {
    final week = ((_now.day - 1) ~/ 7) + 1;

    final weekly = await _db.getWeeklyExpenses(_now.year, _now.month);
    final categories = await _db.getCategoryWiseExpenseByWeek(
      _now.year,
      _now.month,
      week,
    );
    final total = await _db.getTotalExpenseByWeek(_now.year, _now.month, week);

    if (!mounted) return;

    setState(() {
      _weekly = weekly;
      _categories = categories;
      _totalExpense = total;
      _selectedWeek = week;
      _selectedMonth = null;
      _selectedYear = null;
    });
  }

  Future<void> _loadMonthly() async {
    final monthly = await _db.getMonthlyExpenses(_now.year);
    final categories = await _db.getCategoryWiseExpenseByMonth(
      _now.year,
      _now.month,
    );
    final total = await _db.getTotalExpenseByMonth(_now.year, _now.month);

    if (!mounted) return;

    setState(() {
      _monthly = monthly;
      _categories = categories;
      _totalExpense = total;
      _selectedMonth = _now.month;
      _selectedWeek = null;
      _selectedYear = null;
    });
  }

  final Map<String, IconData> _categoryIcons = {
    'food': Icons.restaurant,
    'groceries': Icons.shopping_cart,
    'shopping': Icons.shopping_bag,
    'travel': Icons.flight,
    'health': Icons.local_hospital,
    'entertainment': Icons.movie,
    'rent': Icons.home,
    'fuel': Icons.local_gas_station,
    'education': Icons.school,
    'subscriptions': Icons.subscriptions,
  };

  IconData _categoryIcon(String category) {
    return _categoryIcons[category.toLowerCase()] ?? Icons.category;
  }

  Future<void> _loadYearly() async {
    final yearly = await _db.getYearlyExpenses();
    final categories = await _db.getCategoryWiseExpenseByYear(_now.year);
    final total = await _db.getTotalExpenseByYear(_now.year);

    if (!mounted) return;

    setState(() {
      _yearly = yearly;
      _categories = categories;
      _totalExpense = total;
      _selectedYear = _now.year.toString();
      _selectedWeek = null;
      _selectedMonth = null;
    });
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _totalExpenseCard(),
        const SizedBox(height: 12),
        _pillTabs(),
        const SizedBox(height: 20),
        SizedBox(
          height: 260,
          child: TabBarView(
            controller: _tabController,
            physics: const NeverScrollableScrollPhysics(),
            children: [_weeklyChart(), _monthlyChart(), _yearlyChart()],
          ),
        ),
        const SizedBox(height: 20),
        _categoryReport(),
      ],
    );
  }

  // ================= TOTAL =================

  Widget _totalExpenseCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _totalExpenseLabel(),
          style: TextStyle(
            fontSize: 12,
            letterSpacing: 1.2,
            color: Colors.green.shade400,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '₹ ${_totalExpense.toStringAsFixed(0)}',
          style: const TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w700,
            color: Color.fromARGB(255, 115, 214, 119),
          ),
        ),
      ],
    );
  }

  // ================= PILL TABS =================

  Widget _pillTabs() {
    return Container(
      height: 44,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.green.withOpacity(0.12),
            Colors.green.withOpacity(0.06),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.green.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        dividerColor: Colors.transparent,
        splashBorderRadius: BorderRadius.circular(999),
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color.fromARGB(255, 115, 214, 119),
              Color.fromARGB(255, 88, 190, 103),
            ],
          ),
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(
              color: Colors.green.withOpacity(0.35),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.green.shade800,
        labelStyle: const TextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        tabs: const [
          Tab(text: 'Weekly'),
          Tab(text: 'Monthly'),
          Tab(text: 'Yearly'),
        ],
      ),
    );
  }

  // ================= CHARTS =================

  Widget _weeklyChart() {
    final values = List.generate(5, (i) => _weekly[i + 1] ?? 0);
    return _barChart(
      values,
      List.generate(5, (i) => 'W${i + 1}'),
      onTap: (i) async {
        final week = i + 1;
        final cats = await _db.getCategoryWiseExpenseByWeek(
          _now.year,
          _now.month,
          week,
        );
        final total = await _db.getTotalExpenseByWeek(
          _now.year,
          _now.month,
          week,
        );

        setState(() {
          _selectedWeek = week;
          _categories = cats;
          _totalExpense = total;
        });
      },
    );
  }

  Widget _monthlyChart() {
    final values = List.generate(
      12,
      (i) => _monthly['${i + 1}'.padLeft(2, '0')] ?? 0,
    );
    return _barChart(
      values,
      _monthLabels(),
      onTap: (i) async {
        final cats = await _db.getCategoryWiseExpenseByMonth(_now.year, i + 1);
        final total = await _db.getTotalExpenseByMonth(_now.year, i + 1);

        setState(() {
          _selectedMonth = i + 1;
          _categories = cats;
          _totalExpense = total;
        });
      },
    );
  }

  Widget _yearlyChart() {
    final years = _yearly.keys.toList()..sort();
    final values = years.map((y) => _yearly[y] ?? 0).toList();

    return _barChart(
      values,
      years,
      onTap: (i) async {
        final year = int.parse(years[i]);
        final cats = await _db.getCategoryWiseExpenseByYear(year);
        final total = await _db.getTotalExpenseByYear(year);

        setState(() {
          _selectedYear = years[i];
          _categories = cats;
          _totalExpense = total;
        });
      },
    );
  }

  Widget _barChart(
    List<double> values,
    List<String> labels, {
    required Function(int) onTap,
  }) {
    final maxY = values.isEmpty
        ? 1.0
        : values.reduce((a, b) => a > b ? a : b).clamp(1.0, double.infinity);

    return BarChart(
      BarChartData(
        maxY: maxY,
        barTouchData: BarTouchData(
          handleBuiltInTouches: true,
          touchCallback: (event, res) {
            if (res?.spot == null) return;
            onTap(res!.spot!.touchedBarGroupIndex);
          },
        ),
        barGroups: List.generate(values.length, (i) {
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: values[i],
                width: 18,
                color: const Color.fromARGB(255, 115, 214, 119),
                borderRadius: BorderRadius.circular(6),
              ),
            ],
          );
        }),
        titlesData: _bottomTitles(labels),
        gridData: FlGridData(show: false),
        borderData: FlBorderData(show: false),
      ),
    );
  }

  FlTitlesData _bottomTitles(List<String> labels) {
    return FlTitlesData(
      leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          getTitlesWidget: (v, _) =>
              Text(labels[v.toInt()], style: const TextStyle(fontSize: 10)),
        ),
      ),
    );
  }

  // ================= CATEGORY =================

  Widget _categoryReport() {
    final total = _categories.values.fold(0.0, (a, b) => a + b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Text(
          _selectedWeek != null
              ? 'Category – Week $_selectedWeek'
              : _selectedMonth != null
              ? 'Category – ${_monthLabels()[_selectedMonth! - 1]}'
              : _selectedYear != null
              ? 'Category – $_selectedYear'
              : 'Category',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 14),

        /// Category rows
        ..._categories.entries.map((e) {
          final percent = total == 0 ? 0.0 : e.value / total;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                /// Icon
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.green.shade100,
                  child: Icon(
                    _categoryIcon(e.key),
                    size: 16,
                    color: Colors.green.shade700,
                  ),
                ),

                const SizedBox(width: 10),

                /// Name + Progress
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// Title row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            e.key,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            '₹ ${e.value.toStringAsFixed(0)}',
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 6),

                      /// Progress bar
                      LinearProgressIndicator(
                        value: percent,
                        minHeight: 6,
                        borderRadius: BorderRadius.circular(6),
                        backgroundColor: Colors.grey.shade300,
                        valueColor: const AlwaysStoppedAnimation(
                          Color.fromARGB(255, 115, 214, 119),
                        ),
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

  List<String> _monthLabels() => const [
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
}
