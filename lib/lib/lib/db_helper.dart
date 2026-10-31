import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/expense_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('kharcha_dost.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE expenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        day TEXT NOT NULL,
        rickshaw REAL NOT NULL,
        lunch REAL NOT NULL,
        tea REAL NOT NULL,
        general REAL NOT NULL,
        extra REAL NOT NULL,
        extraDetails TEXT,
        paymentMode TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE budget_settings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        month_year TEXT NOT NULL UNIQUE,
        total_salary REAL NOT NULL,
        fixed_bills REAL NOT NULL
      )
    ''');
  }

  Future<int> insertExpense(Expense expense) async {
    final db = await instance.database;
    return await db.insert('expenses', expense.toMap());
  }

  Future<List<Expense>> getMonthlyExpenses(String yearMonth) async {
    final db = await instance.database;
    final result = await db.query(
      'expenses',
      where: 'date LIKE ?',
      whereArgs: ['$yearMonth%'],
      orderBy: 'date ASC',
    );
    return result.map((json) => Expense.fromMap(json)).toList();
  }

  Future<int> setBudget(String monthYear, double salary, double fixedBills) async {
    final db = await instance.database;
    return await db.insert(
      'budget_settings',
      {'month_year': monthYear, 'total_salary': salary, 'fixed_bills': fixedBills},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, double>> getBudget(String monthYear) async {
    final db = await instance.database;
    final res = await db.query('budget_settings', where: 'month_year = ?', whereArgs: [monthYear]);
    if (res.isNotEmpty) {
      return {
        'salary': (res.first['total_salary'] as num).toDouble(),
        'fixed_bills': (res.first['fixed_bills'] as num).toDouble(),
      };
    }
    return {'salary': 23000.0, 'fixed_bills': 0.0};
  }
}
