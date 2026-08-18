import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class AppDb {
  AppDb._();
  static final instance = AppDb._();

  late Database db;

  Future<void> init() async {
    final path = join(await getDatabasesPath(), 'pharmacy_pos_v2.db');

    db = await openDatabase(
      path,
      version: 2,
      onCreate: (database, version) async {
        await _createTables(database);
      },
      onUpgrade: (database, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _createTables(database);
        }
      },
    );
  }

  Future<void> _createTables(Database d) async {
    await d.execute('''
      CREATE TABLE IF NOT EXISTS medicines(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        generic TEXT,
        company TEXT,
        barcode TEXT,
        batch TEXT,
        expiry TEXT,
        purchase REAL DEFAULT 0,
        sale REAL DEFAULT 0,
        stock REAL DEFAULT 0
      )
    ''');

    await d.execute('''
      CREATE TABLE IF NOT EXISTS sales(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        created_at TEXT NOT NULL,
        total REAL DEFAULT 0,
        paid REAL DEFAULT 0,
        due REAL DEFAULT 0,
        payment TEXT,
        customer TEXT
      )
    ''');

    await d.execute('''
      CREATE TABLE IF NOT EXISTS sale_items(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sale_id INTEGER,
        medicine_id INTEGER,
        qty REAL,
        price REAL,
        cost REAL
      )
    ''');

    await d.execute('''
      CREATE TABLE IF NOT EXISTS purchases(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        created_at TEXT,
        supplier TEXT,
        invoice TEXT,
        total REAL,
        paid REAL,
        due REAL
      )
    ''');

    await d.execute('''
      CREATE TABLE IF NOT EXISTS expenses(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        created_at TEXT,
        title TEXT,
        amount REAL,
        payment TEXT
      )
    ''');

    await d.execute('''
      CREATE TABLE IF NOT EXISTS customer_dues(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        created_at TEXT,
        customer TEXT,
        phone TEXT,
        amount REAL,
        paid REAL,
        note TEXT
      )
    ''');
  }

  Future<List<Map<String, Object?>>> medicines({String q = ''}) async {
    final search = q.trim();

    if (search.isEmpty) {
      return db.query(
        'medicines',
        orderBy: 'name COLLATE NOCASE ASC',
      );
    }

    return db.query(
      'medicines',
      where: '''
        name LIKE ?
        OR generic LIKE ?
        OR company LIKE ?
        OR barcode LIKE ?
        OR batch LIKE ?
      ''',
      whereArgs: [
        '%$search%',
        '%$search%',
        '%$search%',
        '%$search%',
        '%$search%',
      ],
      orderBy: 'name COLLATE NOCASE ASC',
    );
  }

  Future<int> addMedicine(Map<String, Object?> medicine) async {
    return db.insert('medicines', medicine);
  }

  Future<int> updateMedicine(
    int id,
    Map<String, Object?> medicine,
  ) async {
    return db.update(
      'medicines',
      medicine,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteMedicine(int id) async {
    return db.delete(
      'medicines',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> saveSale(
    List<Map<String, Object?>> items,
    double paid,
    String payment,
    String customer,
  ) async {
    if (items.isEmpty) return;

    await db.transaction((tx) async {
      double total = 0;

      for (final item in items) {
        final qty = (item['qty'] as num).toDouble();
        final sale = (item['sale'] as num).toDouble();

        total += qty * sale;
      }

      final due = total - paid;

      final saleId = await tx.insert('sales', {
        'created_at': DateTime.now().toIso8601String(),
        'total': total,
        'paid': paid,
        'due': due > 0 ? due : 0,
        'payment': payment,
        'customer': customer,
      });

      for (final item in items) {
        final medicineId = item['id'] as int;
        final qty = (item['qty'] as num).toDouble();

        final result = await tx.query(
          'medicines',
          columns: ['stock'],
          where: 'id = ?',
          whereArgs: [medicineId],
          limit: 1,
        );

        if (result.isEmpty) {
          throw Exception('Medicine not found');
        }

        final currentStock =
            (result.first['stock'] as num?)?.toDouble() ?? 0;

        if (qty > currentStock) {
          throw Exception(
            'Not enough stock for ${item['name']}',
          );
        }

        await tx.insert('sale_items', {
          'sale_id': saleId,
          'medicine_id': medicineId,
          'qty': qty,
          'price': item['sale'],
          'cost': item['purchase'],
        });

        await tx.update(
          'medicines',
          {
            'stock': currentStock - qty,
          },
          where: 'id = ?',
          whereArgs: [medicineId],
        );
      }

      if (due > 0 && customer.trim().isNotEmpty) {
        await tx.insert('customer_dues', {
          'created_at': DateTime.now().toIso8601String(),
          'customer': customer.trim(),
          'phone': '',
          'amount': due,
          'paid': 0,
          'note': 'Sale #$saleId',
        });
      }
    });
  }

  Future<void> addExpense(
    String title,
    double amount,
    String payment,
  ) async {
    await db.insert('expenses', {
      'created_at': DateTime.now().toIso8601String(),
      'title': title,
      'amount': amount,
      'payment': payment,
    });
  }

  Future<Map<String, double>> dashboard() async {
    final day = DateTime.now()
        .toIso8601String()
        .substring(0, 10);

    final sales = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(total), 0) AS value
      FROM sales
      WHERE substr(created_at, 1, 10) = ?
      ''',
      [day],
    );

    final expenses = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(amount), 0) AS value
      FROM expenses
      WHERE substr(created_at, 1, 10) = ?
      ''',
      [day],
    );

    final stock = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(stock * purchase), 0) AS value
      FROM medicines
      ''',
    );

    final dues = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(amount - paid), 0) AS value
      FROM customer_dues
      ''',
    );

    return {
      'sales':
          (sales.first['value'] as num?)?.toDouble() ?? 0,
      'expense':
          (expenses.first['value'] as num?)?.toDouble() ?? 0,
      'stock':
          (stock.first['value'] as num?)?.toDouble() ?? 0,
      'due':
          (dues.first['value'] as num?)?.toDouble() ?? 0,
    };
  }
}