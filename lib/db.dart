import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class AppDb {
  AppDb._();
  static final instance = AppDb._();
  late Database db;

  Future<void> init() async {
    final p = join(await getDatabasesPath(), 'pharmacy_pos_v1.db');
    db = await openDatabase(p, version: 1, onCreate: (d, v) async {
      await d.execute('CREATE TABLE medicines(id INTEGER PRIMARY KEY AUTOINCREMENT,name TEXT NOT NULL,generic TEXT,company TEXT,barcode TEXT,batch TEXT,expiry TEXT,purchase REAL DEFAULT 0,sale REAL DEFAULT 0,stock REAL DEFAULT 0)');
      await d.execute('CREATE TABLE sales(id INTEGER PRIMARY KEY AUTOINCREMENT,created_at TEXT,total REAL,paid REAL,due REAL,payment TEXT,customer TEXT)');
      await d.execute('CREATE TABLE sale_items(id INTEGER PRIMARY KEY AUTOINCREMENT,sale_id INTEGER,medicine_id INTEGER,qty REAL,price REAL,cost REAL)');
      await d.execute('CREATE TABLE purchases(id INTEGER PRIMARY KEY AUTOINCREMENT,created_at TEXT,supplier TEXT,invoice TEXT,total REAL,paid REAL,due REAL)');
      await d.execute('CREATE TABLE expenses(id INTEGER PRIMARY KEY AUTOINCREMENT,created_at TEXT,title TEXT,amount REAL,payment TEXT)');
      await d.execute('CREATE TABLE customer_dues(id INTEGER PRIMARY KEY AUTOINCREMENT,created_at TEXT,customer TEXT,phone TEXT,amount REAL,paid REAL,note TEXT)');
    });
  }

  Future<List<Map<String,Object?>>> medicines({String q=''}) {
    if (q.trim().isEmpty) return db.query('medicines', orderBy:'name COLLATE NOCASE');
    return db.query('medicines',
      where:'name LIKE ? OR generic LIKE ? OR barcode LIKE ?',
      whereArgs:['%$q%','%$q%','%$q%']);
  }

  Future<int> addMedicine(Map<String,Object?> m) => db.insert('medicines',m);

  Future<int> updateMedicine(int id, Map<String,Object?> m) =>
      db.update('medicines',m,where:'id=?',whereArgs:[id]);

  Future<void> saveSale(List<Map<String,Object?>> items,double paid,String payment,String customer) async {
    if(items.isEmpty) return;
    await db.transaction((tx) async {
      double total=0;
      for(final x in items) total += (x['qty'] as num)*(x['sale'] as num);
      final id=await tx.insert('sales',{
        'created_at':DateTime.now().toIso8601String(),'total':total,
        'paid':paid,'due':total-paid,'payment':payment,'customer':customer});
      for(final x in items){
        final qty=(x['qty'] as num).toDouble();
        await tx.insert('sale_items',{
          'sale_id':id,'medicine_id':x['id'],'qty':qty,
          'price':x['sale'],'cost':x['purchase']});
        await tx.rawUpdate('UPDATE medicines SET stock=stock-? WHERE id=?',[qty,x['id']]);
      }
      if(total>paid && customer.trim().isNotEmpty){
        await tx.insert('customer_dues',{
          'created_at':DateTime.now().toIso8601String(),
          'customer':customer,'phone':'','amount':total-paid,'paid':0,'note':'Sale #$id'});
      }
    });
  }

  Future<void> addExpense(String title,double amount,String payment) =>
      db.insert('expenses',{'created_at':DateTime.now().toIso8601String(),'title':title,'amount':amount,'payment':payment});

  Future<Map<String,double>> dashboard() async {
    final day=DateTime.now().toIso8601String().substring(0,10);
    final a=await db.rawQuery("SELECT COALESCE(SUM(total),0) v FROM sales WHERE substr(created_at,1,10)=?",[day]);
    final b=await db.rawQuery("SELECT COALESCE(SUM(amount),0) v FROM expenses WHERE substr(created_at,1,10)=?",[day]);
    final c=await db.rawQuery("SELECT COALESCE(SUM(stock*purchase),0) v FROM medicines");
    final d=await db.rawQuery("SELECT COALESCE(SUM(amount-paid),0) v FROM customer_dues");
    return {'sales':(a.first['v'] as num).toDouble(),'expense':(b.first['v'] as num).toDouble(),'stock':(c.first['v'] as num).toDouble(),'due':(d.first['v'] as num).toDouble()};
  }
}
