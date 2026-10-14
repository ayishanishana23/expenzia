import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

import '../models/expense.dart';


class ExpenseDatabase {
  ExpenseDatabase._();

  static final ExpenseDatabase instance = ExpenseDatabase._();

  Future<Database>? _databaseFuture;

  Future<Database> get database {
    return _databaseFuture ??= _openDatabase();
  }

  Future<Database> _openDatabase() async {
    try {
      final directory = await getDatabasesPath();
      final databasePath = path.join(directory, 'expenzia.db');

      return await openDatabase(
        databasePath,
        version: 3,
        onCreate: (db, version) async {
          await db.execute('''
          CREATE TABLE expenses (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL
              CHECK(length(trim(title)) > 0),
            amount_paise INTEGER NOT NULL
              CHECK(amount_paise > 0),
            category TEXT NOT NULL
              CHECK(length(trim(category)) > 0),
            date TEXT NOT NULL,
            description TEXT,
            transaction_type TEXT NOT NULL DEFAULT 'outward'
              CHECK(transaction_type IN ('inward', 'outward'))
          )
        ''');

          await _createAdditionalTables(db);
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          if (oldVersion < 2) {
            await _createAdditionalTables(db);
          }

          if (oldVersion < 3) {
            await db.execute('''
            ALTER TABLE expenses
            ADD COLUMN transaction_type TEXT NOT NULL
            DEFAULT 'outward'
            CHECK(transaction_type IN ('inward', 'outward'))
          ''');
          }
        },
      );
    } catch (_) {
      _databaseFuture = null;
      rethrow;
    }
  }

  void _validateExpense(Expense expense) {
    if (expense.title.trim().isEmpty) {
      throw ArgumentError('Expense title is required.');
    }

    if (expense.amountPaise <= 0) {
      throw ArgumentError('Amount must be greater than zero.');
    }

    if (expense.category.trim().isEmpty) {
      throw ArgumentError('Category is required.');
    }

    if (!['inward', 'outward'].contains(expense.transactionType)) {
      throw ArgumentError('Select a valid transaction type.');
    }
  }

  Future<int> addExpense(Expense expense) async {
    _validateExpense(expense);

    final db = await database;
    final values = expense.toMap();

    // SQLite generates the ID for a new expense.
    values.remove('id');

    return db.insert('expenses', values);
  }

  Future<List<Expense>> getExpenses() async {
    final db = await database;

    final rows = await db.query(
      'expenses',
      orderBy: 'date DESC, id DESC',
    );

    return rows.map(Expense.fromMap).toList();
  }

  Future<void> updateExpense(Expense expense) async {
    _validateExpense(expense);

    final id = expense.id;

    if (id == null) {
      throw ArgumentError('An expense ID is required for editing.');
    }

    final db = await database;
    final values = expense.toMap();
    values.remove('id');

    final updatedRows = await db.update(
      'expenses',
      values,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (updatedRows == 0) {
      throw StateError('This expense no longer exists.');
    }
  }

  Future<void> deleteExpense(int id) async {
    final db = await database;

    final deletedRows = await db.delete(
      'expenses',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (deletedRows == 0) {
      throw StateError('This expense no longer exists.');
    }
  }

  Future<void> _createAdditionalTables(Database db) async {
    await db.execute('''
    CREATE TABLE credits (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      credit_type TEXT NOT NULL,
      recipient TEXT NOT NULL CHECK(length(trim(recipient)) > 0),
      due_date TEXT NOT NULL,
      plan_type TEXT NOT NULL,
      amount_paise INTEGER NOT NULL CHECK(amount_paise > 0)
    )
  ''');

    await db.execute('''
    CREATE TABLE user_profile (
      id INTEGER PRIMARY KEY CHECK(id = 1),
      name TEXT NOT NULL
    )
  ''');

    await db.insert('user_profile', {
      'id': 1,
      'name': 'Your name',
    });
  }

  Future<int> addCredit({
    required String creditType,
    required String recipient,
    required DateTime dueDate,
    required String planType,
    required int amountPaise,
  }) async {
    if (recipient.trim().isEmpty || amountPaise <= 0) {
      throw ArgumentError('Enter a recipient and a positive amount.');
    }

    final db = await database;

    return db.insert('credits', {
      'credit_type': creditType,
      'recipient': recipient.trim(),
      'due_date': dueDate.toIso8601String(),
      'plan_type': planType,
      'amount_paise': amountPaise,
    });
  }

  Future<List<Map<String, Object?>>> getCredits() async {
    final db = await database;

    return db.query(
      'credits',
      orderBy: 'due_date ASC, id DESC',
    );
  }

  Future<String> getProfileName() async {
    final db = await database;

    final rows = await db.query(
      'user_profile',
      where: 'id = ?',
      whereArgs: [1],
    );

    return rows.isEmpty ? 'Your name' : rows.first['name'] as String;
  }

  Future<void> saveProfileName(String name) async {
    final trimmed = name.trim();

    if (trimmed.isEmpty) {
      throw ArgumentError('Name cannot be empty.');
    }

    final db = await database;

    await db.insert(
      'user_profile',
      {'id': 1, 'name': trimmed},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> clearStorage() async {
    final db = await database;

    await db.transaction((txn) async {
      await txn.delete('expenses');
      await txn.delete('credits');
      await txn.delete('user_profile');

      await txn.insert('user_profile', {
        'id': 1,
        'name': 'Your name',
      });
    });
  }
}