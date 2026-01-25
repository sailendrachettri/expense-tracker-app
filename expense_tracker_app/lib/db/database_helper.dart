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
}
