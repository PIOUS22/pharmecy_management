import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();

    final path = join(
      databasesPath,
      'pharmacy_management_v2.db',
    );

    return openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(
    Database db,
    int version,
  ) async {
    // =========================================================
    // USERS
    // =========================================================

    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL UNIQUE,
        password_hash TEXT NOT NULL,
        name TEXT NOT NULL,
        role TEXT NOT NULL,
        active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL
      )
    ''');

    // =========================================================
    // MEDICINES
    // =========================================================

    await db.execute('''
      CREATE TABLE medicines (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        generic_name TEXT,
        company_id INTEGER,
        barcode TEXT,
        batch_no TEXT,
        expiry_date TEXT,
        purchase_price REAL NOT NULL DEFAULT 0,
        sale_price REAL NOT NULL DEFAULT 0,
        stock REAL NOT NULL DEFAULT 0,
        min_stock REAL NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // =========================================================
    // SUPPLIERS / COMPANIES
    // =========================================================

    await db.execute('''
      CREATE TABLE suppliers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT,
        address TEXT,
        opening_due REAL NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // =========================================================
    // PRESCRIPTIONS
    // =========================================================

    await db.execute('''
      CREATE TABLE prescriptions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        prescription_no TEXT NOT NULL UNIQUE,
        patient_name TEXT NOT NULL,
        patient_phone TEXT,
        doctor_name TEXT,
        sale_date TEXT NOT NULL,
        subtotal REAL NOT NULL DEFAULT 0,
        discount REAL NOT NULL DEFAULT 0,
        total REAL NOT NULL DEFAULT 0,
        paid REAL NOT NULL DEFAULT 0,
        due REAL NOT NULL DEFAULT 0,
        payment_method TEXT NOT NULL DEFAULT 'Cash',
        created_by INTEGER,
        created_at TEXT NOT NULL
      )
    ''');

    // =========================================================
    // PRESCRIPTION ITEMS
    // =========================================================

    await db.execute('''
      CREATE TABLE prescription_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        prescription_id INTEGER NOT NULL,
        medicine_id INTEGER NOT NULL,
        medicine_name TEXT NOT NULL,
        quantity REAL NOT NULL,
        unit_price REAL NOT NULL,
        purchase_price REAL NOT NULL,
        total REAL NOT NULL
      )
    ''');

    // =========================================================
    // PURCHASES
    // =========================================================

    await db.execute('''
      CREATE TABLE purchases (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        invoice_no TEXT,
        supplier_id INTEGER NOT NULL,
        purchase_date TEXT NOT NULL,
        subtotal REAL NOT NULL DEFAULT 0,
        discount REAL NOT NULL DEFAULT 0,
        total REAL NOT NULL DEFAULT 0,
        paid REAL NOT NULL DEFAULT 0,
        due REAL NOT NULL DEFAULT 0,
        created_by INTEGER,
        created_at TEXT NOT NULL
      )
    ''');

    // =========================================================
    // PURCHASE ITEMS
    // =========================================================

    await db.execute('''
      CREATE TABLE purchase_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        purchase_id INTEGER NOT NULL,
        medicine_id INTEGER NOT NULL,
        medicine_name TEXT NOT NULL,
        quantity REAL NOT NULL,
        purchase_price REAL NOT NULL,
        total REAL NOT NULL,
        batch_no TEXT,
        expiry_date TEXT
      )
    ''');

    // =========================================================
    // SUPPLIER PAYMENTS
    // =========================================================

    await db.execute('''
      CREATE TABLE supplier_payments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        supplier_id INTEGER NOT NULL,
        payment_date TEXT NOT NULL,
        amount REAL NOT NULL,
        payment_method TEXT NOT NULL DEFAULT 'Cash',
        note TEXT,
        created_by INTEGER,
        created_at TEXT NOT NULL
      )
    ''');

    // =========================================================
    // CUSTOMER DUES
    // =========================================================

    await db.execute('''
      CREATE TABLE customer_dues (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        prescription_id INTEGER,
        customer_name TEXT NOT NULL,
        phone TEXT,
        amount REAL NOT NULL,
        paid REAL NOT NULL DEFAULT 0,
        due REAL NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');

    // =========================================================
    // CUSTOMER PAYMENTS
    // =========================================================

    await db.execute('''
      CREATE TABLE customer_payments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customer_name TEXT NOT NULL,
        phone TEXT,
        amount REAL NOT NULL,
        payment_date TEXT NOT NULL,
        note TEXT,
        created_by INTEGER,
        created_at TEXT NOT NULL
      )
    ''');

    // =========================================================
    // EXPENSES
    // =========================================================

    await db.execute('''
      CREATE TABLE expenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category TEXT NOT NULL,
        description TEXT,
        amount REAL NOT NULL,
        expense_date TEXT NOT NULL,
        payment_method TEXT NOT NULL DEFAULT 'Cash',
        created_by INTEGER,
        created_at TEXT NOT NULL
      )
    ''');

    // =========================================================
    // STOCK MOVEMENTS
    // =========================================================

    await db.execute('''
      CREATE TABLE stock_movements (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        medicine_id INTEGER NOT NULL,
        type TEXT NOT NULL,
        quantity REAL NOT NULL,
        reference_id INTEGER,
        note TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    // =========================================================
    // INDEXES
    // =========================================================

    await db.execute('''
      CREATE INDEX idx_medicines_name
      ON medicines(name)
    ''');

    await db.execute('''
      CREATE INDEX idx_medicines_barcode
      ON medicines(barcode)
    ''');

    await db.execute('''
      CREATE INDEX idx_medicines_company
      ON medicines(company_id)
    ''');

    await db.execute('''
      CREATE INDEX idx_prescriptions_date
      ON prescriptions(sale_date)
    ''');

    await db.execute('''
      CREATE INDEX idx_prescriptions_patient
      ON prescriptions(patient_name)
    ''');

    await db.execute('''
      CREATE INDEX idx_purchases_date
      ON purchases(purchase_date)
    ''');

    await db.execute('''
      CREATE INDEX idx_purchases_supplier
      ON purchases(supplier_id)
    ''');

    await db.execute('''
      CREATE INDEX idx_expenses_date
      ON expenses(expense_date)
    ''');

    await db.execute('''
      CREATE INDEX idx_stock_medicine
      ON stock_movements(medicine_id)
    ''');

    // =========================================================
    // DEFAULT ADMIN
    // =========================================================

    await db.insert(
      'users',
      {
        'username': 'admin',
        'password_hash': 'CHANGE_ME',
        'name': 'Administrator',
        'role': 'admin',
        'active': 1,
        'created_at': DateTime.now().toIso8601String(),
      },
    );
  }

  // ===========================================================
  // BASIC HELPERS
  // ===========================================================

  Future<int> insert(
    String table,
    Map<String, Object?> values,
  ) async {
    final db = await database;

    return db.insert(
      table,
      values,
      conflictAlgorithm:
          ConflictAlgorithm.abort,
    );
  }

  Future<int> update(
    String table,
    Map<String, Object?> values, {
    required String where,
    required List<Object?> whereArgs,
  }) async {
    final db = await database;

    return db.update(
      table,
      values,
      where: where,
      whereArgs: whereArgs,
    );
  }

  Future<int> delete(
    String table, {
    required String where,
    required List<Object?> whereArgs,
  }) async {
    final db = await database;

    return db.delete(
      table,
      where: where,
      whereArgs: whereArgs,
    );
  }

  Future<List<Map<String, Object?>>> query(
    String table, {
    String? where,
    List<Object?>? whereArgs,
    String? orderBy,
  }) async {
    final db = await database;

    return db.query(
      table,
      where: where,
      whereArgs: whereArgs,
      orderBy: orderBy,
    );
  }

  // ===========================================================
  // TRANSACTION HELPER
  // ===========================================================

  Future<T> transaction<T>(
    Future<T> Function(Transaction tx) action,
  ) async {
    final db = await database;

    return db.transaction(action);
  }

  // ===========================================================
  // CLOSE DATABASE
  // ===========================================================

  Future<void> close() async {
    final db = _database;

    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
