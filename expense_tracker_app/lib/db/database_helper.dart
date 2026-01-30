import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../models/expense.dart';
import '../../models/borrow.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<void> _ensureDefaults(Database db) async {
    // Check if categories table is empty
    final categoryCount =
        Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM categories'),
        ) ??
        0;
    if (categoryCount == 0) {
      await _insertDefaultCategories(db);
    }

    // Check if borrowers table is empty
    final borrowerCount =
        Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM borrowers'),
        ) ??
        0;
    if (borrowerCount == 0) {
      await _insertDefaultBorrowers(db);
    }
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'expenses.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
      onOpen: (db) async {
        // This runs every time the database is opened
        // Insert defaults only if tables are empty
        await _ensureDefaults(db);
      },
    );
  }

  Future<void> _insertDefaultBorrowers(Database db) async {
    final defaults = ['Friend', 'Family', 'Office Colleague', 'Bank', 'Other'];

    for (final name in defaults) {
      await db.insert('borrowers', {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'name': name,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
  }

  Future<void> _insertDefaultCategories(Database db) async {
    final defaults = [
      'Groceries',
      'Taxi Fare',
      'Sweets',
      'Food',
      'Shopping',
      'Other',
    ];

    for (final name in defaults) {
      await db.insert(
        'categories',
        {'id': DateTime.now().millisecondsSinceEpoch.toString(), 'name': name},
        conflictAlgorithm: ConflictAlgorithm.ignore, // avoids duplicates
      );
    }
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE expenses (
        id TEXT PRIMARY KEY,
        category TEXT,
        amount REAL,
        date TEXT
      )
    ''');
    await db.execute('''
  CREATE TABLE categories (
    id TEXT PRIMARY KEY,
    name TEXT UNIQUE
  )
''');

    await db.execute('''
  CREATE TABLE borrows (
    id TEXT PRIMARY KEY,
    person TEXT,
    amount REAL,
    date TEXT
  )
''');

    await db.execute('''
    CREATE TABLE borrowers (
      id TEXT PRIMARY KEY,
      name TEXT UNIQUE
    )
  ''');

    await _insertDefaultBorrowers(db);
    await _insertDefaultCategories(db);
  }

  // ---------------------------------Borrowing---------------------------------
  // GET BORROWERS: peoples
  Future<List<String>> getBorrowers() async {
    final db = await database;
    final result = await db.query('borrowers', orderBy: 'name ASC');
    return result.map((e) => e['name'] as String).toList();
  }

  // ADD BORROWER
  Future<void> insertBorrower(String name) async {
    final db = await database;
    await db.insert('borrowers', {
      'id': DateTime.now().toString(),
      'name': name,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  // DELETE BORROWER (optional)
  Future<void> deleteBorrower(String name) async {
    final db = await database;
    await db.delete('borrowers', where: 'name = ?', whereArgs: [name]);
  }

  // INSERT BORROW
  Future<void> insertBorrow(Borrow borrow) async {
    final db = await database;
    await db.insert('borrows', borrow.toMap());
  }

  // GET ALL BORROWS
  Future<List<Borrow>> getBorrows() async {
    final db = await database;
    final result = await db.query('borrows', orderBy: 'date DESC');
    return result.map((e) => Borrow.fromMap(e)).toList();
  }

  Future<void> deleteBorrow(String id) async {
    final db = await database;
    await db.delete('borrows', where: 'id = ?', whereArgs: [id]);
  }

  //--------------------------------- Expense---------------------------------

  // GET all categories
  Future<List<String>> getCategories() async {
    final db = await database;
    final result = await db.query('categories', orderBy: 'name ASC');
    return result.map((e) => e['name'] as String).toList();
  }

  // ADD a new category
  Future<void> insertCategory(String name) async {
    final db = await database;
    await db.insert('categories', {
      'id': DateTime.now().toString(),
      'name': name,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  // DELETE category (optional)
  Future<void> deleteCategory(String name) async {
    final db = await database;
    await db.delete('categories', where: 'name = ?', whereArgs: [name]);
  }

  // INSERT
  Future<void> insertExpense(Expense expense) async {
    final db = await database;
    await db.insert(
      'expenses',
      expense.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // READ (by date)
  Future<List<Expense>> getExpensesByDate(DateTime date) async {
    final db = await database;
    final formattedDate = date.toIso8601String().substring(0, 10);

    final result = await db.query(
      'expenses',
      where: "date LIKE ?",
      whereArgs: ['$formattedDate%'],
      orderBy: 'date DESC',
    );

    return result.map((e) => Expense.fromMap(e)).toList();
  }

  // DELETE
  Future<void> deleteExpense(String id) async {
    final db = await database;
    await db.delete('expenses', where: 'id = ?', whereArgs: [id]);
  }

  /* Report for expense */
  Future<double> getTotalExpense() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT SUM(amount) as total FROM expenses',
    );
    return (result.first['total'] as double?) ?? 0.0;
  }

  // ---------------- TOTALS ----------------

  Future<double> getTotalExpenseByWeek(int year, int month, int week) async {
    final db = await database;
    final start = DateTime(year, month, (week - 1) * 7 + 1);
    final end = start.add(const Duration(days: 7));

    final res = await db.rawQuery(
      '''
    SELECT SUM(amount) as total FROM expenses
    WHERE date >= ? AND date < ?
  ''',
      [start.toIso8601String(), end.toIso8601String()],
    );

    return (res.first['total'] as num?)?.toDouble() ?? 0;
  }

  Future<double> getTotalExpenseByMonth(int year, int month) async {
    final db = await database;
    final res = await db.rawQuery(
      '''
    SELECT SUM(amount) as total FROM expenses
    WHERE strftime('%Y', date) = ?
    AND strftime('%m', date) = ?
  ''',
      [year.toString(), month.toString().padLeft(2, '0')],
    );

    return (res.first['total'] as num?)?.toDouble() ?? 0;
  }

  Future<double> getTotalExpenseByYear(int year) async {
    final db = await database;
    final res = await db.rawQuery(
      '''
    SELECT SUM(amount) as total FROM expenses
    WHERE strftime('%Y', date) = ?
  ''',
      [year.toString()],
    );

    return (res.first['total'] as num?)?.toDouble() ?? 0;
  }

  // ---------------- BARS ----------------

  Future<Map<int, double>> getWeeklyExpenses(int year, int month) async {
    final db = await database;
    final res = await db.rawQuery(
      '''
    SELECT ((CAST(strftime('%d', date) AS INT)-1)/7)+1 as week,
           SUM(amount) as total
    FROM expenses
    WHERE strftime('%Y', date)=? AND strftime('%m', date)=?
    GROUP BY week
  ''',
      [year.toString(), month.toString().padLeft(2, '0')],
    );

    return {
      for (var r in res) r['week'] as int: (r['total'] as num).toDouble(),
    };
  }

  Future<Map<String, double>> getMonthlyExpenses(int year) async {
    final db = await database;
    final res = await db.rawQuery(
      '''
    SELECT strftime('%m', date) as month, SUM(amount) as total
    FROM expenses
    WHERE strftime('%Y', date)=?
    GROUP BY month
  ''',
      [year.toString()],
    );

    return {
      for (var r in res) r['month'] as String: (r['total'] as num).toDouble(),
    };
  }

  Future<Map<String, double>> getYearlyExpenses() async {
    final db = await database;
    final res = await db.rawQuery('''
    SELECT strftime('%Y', date) as year, SUM(amount) as total
    FROM expenses
    GROUP BY year
  ''');

    return {
      for (var r in res) r['year'] as String: (r['total'] as num).toDouble(),
    };
  }

  // ---------------- CATEGORY ----------------

  Future<Map<String, double>> getCategoryWiseExpenseByWeek(
    int year,
    int month,
    int week,
  ) async {
    final db = await database;
    final start = DateTime(year, month, (week - 1) * 7 + 1);
    final lastDayOfMonth = DateTime(
      year,
      month + 1,
      0,
    ).day; // last day of month
    final endDay = ((week - 1) * 7 + 7) > lastDayOfMonth
        ? lastDayOfMonth
        : (week - 1) * 7 + 7;
    final end = DateTime(year, month, endDay + 1); // exclusive

    final res = await db.rawQuery(
      '''
    SELECT category, SUM(amount) as total
    FROM expenses
    WHERE date >= ? AND date < ?
    GROUP BY category
    ORDER BY total DESC
  ''',
      [start.toIso8601String(), end.toIso8601String()],
    );

    return {
      for (var r in res)
        r['category'] as String: (r['total'] as num).toDouble(),
    };
  }

  Future<Map<String, double>> getCategoryWiseExpenseByMonth(
    int year,
    int month,
  ) async {
    final db = await database;
    final res = await db.rawQuery(
      '''
    SELECT category, SUM(amount) as total
    FROM expenses
    WHERE strftime('%Y', date)=?
    AND strftime('%m', date)=?
    GROUP BY category
    ORDER BY total DESC
  ''',
      [year.toString(), month.toString().padLeft(2, '0')],
    );

    return {
      for (var r in res)
        r['category'] as String: (r['total'] as num).toDouble(),
    };
  }

  Future<Map<String, double>> getCategoryWiseExpenseByYear(int year) async {
    final db = await database;
    final res = await db.rawQuery(
      '''
    SELECT category, SUM(amount) as total
    FROM expenses
    WHERE strftime('%Y', date)=?
    GROUP BY category
    ORDER BY total DESC
  ''',
      [year.toString()],
    );

    return {
      for (var r in res)
        r['category'] as String: (r['total'] as num).toDouble(),
    };
  }
}
