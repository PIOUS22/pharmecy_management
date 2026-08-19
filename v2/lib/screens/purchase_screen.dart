import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../database/app_database.dart';

class PurchaseScreen extends StatefulWidget {
  const PurchaseScreen({super.key});

  @override
  State<PurchaseScreen> createState() => _PurchaseScreenState();
}

class _PurchaseScreenState extends State<PurchaseScreen> {
  List<Map<String, Object?>> purchases = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadPurchases();
  }

  Future<void> loadPurchases() async {
    setState(() {
      loading = true;
    });

    final db = await AppDatabase.instance.database;

    final result = await db.rawQuery('''
      SELECT
        purchases.*,
        suppliers.name AS supplier_name
      FROM purchases
      LEFT JOIN suppliers
        ON suppliers.id = purchases.supplier_id
      ORDER BY purchases.id DESC
    ''');

    if (!mounted) return;

    setState(() {
      purchases = result;
      loading = false;
    });
  }

  String money(Object? value) {
    final amount =
        double.tryParse(value?.toString() ?? '0') ?? 0;

    return '৳${amount.toStringAsFixed(2)}';
  }

  String date(Object? value) {
    if (value == null) return '-';

    try {
      return DateFormat('dd/MM/yyyy')
          .format(DateTime.parse(value.toString()));
    } catch (_) {
      return value.toString();
    }
  }

  Future<void> newPurchase() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const PurchaseCreateScreen(),
      ),
    );

    if (result == true) {
      await loadPurchases();
    }
  }

  Future<void> showPurchase(
    Map<String, Object?> purchase,
  ) async {
    final db = await AppDatabase.instance.database;

    final items = await db.query(
      'purchase_items',
      where: 'purchase_id = ?',
      whereArgs: [purchase['id']],
    );

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          'Purchase ${purchase['invoice_no'] ?? ''}',
        ),
        content: SizedBox(
          width: 550,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Supplier: '
                  '${purchase['supplier_name'] ?? '-'}',
                ),
                Text(
                  'Date: ${date(purchase['purchase_date'])}',
                ),
                const Divider(),

                ...items.map(
                  (item) {
                    final quantity =
                        double.tryParse(
                              item['quantity']
                                      ?.toString() ??
                                  '0',
                            ) ??
                            0;

                    final price =
                        double.tryParse(
                              item['purchase_price']
                                      ?.toString() ??
                                  '0',
                            ) ??
                            0;

                    return Padding(
                      padding:
                          const EdgeInsets.symmetric(
                        vertical: 5,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              item['medicine_name']
                                      ?.toString() ??
                                  '',
                            ),
                          ),
                          Text(
                            '${quantity.toStringAsFixed(0)} × '
                            '${money(price)}',
                          ),
                        ],
                      ),
                    );
                  },
                ),

                const Divider(),

                _row(
                  'Subtotal',
                  money(purchase['subtotal']),
                ),
                _row(
                  'Discount',
                  money(purchase['discount']),
                ),
                _row(
                  'Total',
                  money(purchase['total']),
                  bold: true,
                ),
                _row(
                  'Paid',
                  money(purchase['paid']),
                ),
                _row(
                  'Due',
                  money(purchase['due']),
                  bold: true,
                  color: (double.tryParse(
                                purchase['due']
                                        ?.toString() ??
                                    '0',
                              ) ??
                              0) >
                          0
                      ? Colors.red
                      : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _row(
    String title,
    String value, {
    bool bold = false,
    Color? color,
  }) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontWeight:
                    bold ? FontWeight.bold : null,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight:
                  bold ? FontWeight.bold : null,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton:
          FloatingActionButton.extended(
        onPressed: newPurchase,
        icon: const Icon(Icons.add),
        label: const Text('New Purchase'),
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : purchases.isEmpty
              ? const Center(
                  child: Text(
                    'No purchases found',
                    style: TextStyle(fontSize: 18),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: loadPurchases,
                  child: ListView.builder(
                    padding:
                        const EdgeInsets.fromLTRB(
                      12,
                      12,
                      12,
                      90,
                    ),
                    itemCount: purchases.length,
                    itemBuilder:
                        (context, index) {
                      final purchase =
                          purchases[index];

                      final due =
                          double.tryParse(
                                purchase['due']
                                        ?.toString() ??
                                    '0',
                              ) ??
                              0;

                      return Card(
                        margin:
                            const EdgeInsets.only(
                          bottom: 10,
                        ),
                        child: ListTile(
                          onTap: () =>
                              showPurchase(
                            purchase,
                          ),
                          leading:
                              const CircleAvatar(
                            child: Icon(
                              Icons.shopping_cart,
                            ),
                          ),
                          title: Text(
                            purchase['invoice_no']
                                    ?.toString() ??
                                'Purchase #${purchase['id']}',
                            style:
                                const TextStyle(
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,
                            children: [
                              Text(
                                'Supplier: '
                                '${purchase['supplier_name'] ?? '-'}',
                              ),
                              Text(
                                'Date: '
                                '${date(purchase['purchase_date'])}',
                              ),
                              Text(
                                'Total: '
                                '${money(purchase['total'])}',
                              ),
                              if (due > 0)
                                Text(
                                  'Due: ${money(due)}',
                                  style:
                                      const TextStyle(
                                    color: Colors.red,
                                    fontWeight:
                                        FontWeight.bold,
                                  ),
                                ),
                            ],
                          ),
                          trailing:
                              const Icon(
                            Icons.chevron_right,
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

class PurchaseCreateScreen extends StatefulWidget {
  const PurchaseCreateScreen({super.key});

  @override
  State<PurchaseCreateScreen> createState() =>
      _PurchaseCreateScreenState();
}

class _PurchaseCreateScreenState
    extends State<PurchaseCreateScreen> {
  final invoiceController =
      TextEditingController();

  final searchController =
      TextEditingController();

  final discountController =
      TextEditingController(text: '0');

  final paidController =
      TextEditingController(text: '0');

  List<Map<String, Object?>> suppliers = [];
  List<Map<String, Object?>> medicines = [];

  List<Map<String, Object?>> cart = [];

  int? selectedSupplierId;

  String paymentMethod = 'Cash';

  bool loading = true;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    final db =
        await AppDatabase.instance.database;

    final supplierResult = await db.query(
      'suppliers',
      orderBy: 'name COLLATE NOCASE ASC',
    );

    final medicineResult = await db.query(
      'medicines',
      orderBy: 'name COLLATE NOCASE ASC',
    );

    if (!mounted) return;

    setState(() {
      suppliers = supplierResult;
      medicines = medicineResult;
      loading = false;
    });
  }

  @override
  void dispose() {
    invoiceController.dispose();
    searchController.dispose();
    discountController.dispose();
    paidController.dispose();

    super.dispose();
  }

  double number(String value) {
    return double.tryParse(value.trim()) ?? 0;
  }

  double get subtotal {
    return cart.fold<double>(
      0,
      (sum, item) {
        final quantity =
            number(
          item['quantity'].toString(),
        );

        final price =
            number(
          item['purchase_price'].toString(),
        );

        return sum + quantity * price;
      },
    );
  }

  double get discount {
    final value =
        number(discountController.text);

    return value < 0 ? 0 : value;
  }

  double get total {
    final result = subtotal - discount;

    return result < 0 ? 0 : result;
  }

  double get paid {
    final value =
        number(paidController.text);

    return value < 0 ? 0 : value;
  }

  double get due {
    final result = total - paid;

    return result < 0 ? 0 : result;
  }

  List<Map<String, Object?>> get filteredMedicines {
    final search =
        searchController.text.trim().toLowerCase();

    if (search.isEmpty) {
      return medicines.take(8).toList();
    }

    return medicines.where((medicine) {
      final name =
          medicine['name']
                  ?.toString()
                  .toLowerCase() ??
              '';

      final generic =
          medicine['generic_name']
                  ?.toString()
                  .toLowerCase() ??
              '';

      final barcode =
          medicine['barcode']
                  ?.toString()
                  .toLowerCase() ??
              '';

      return name.contains(search) ||
          generic.contains(search) ||
          barcode.contains(search);
    }).take(8).toList();
  }

  void addMedicine(
    Map<String, Object?> medicine,
  ) {
    final id = medicine['id'];

    final index = cart.indexWhere(
      (item) => item['medicine_id'] == id,
    );

    if (index >= 0) {
      setState(() {
        cart[index]['quantity'] =
            number(
              cart[index]['quantity'].toString(),
            ) +
            1;
      });

      return;
    }

    setState(() {
      cart.add({
        'medicine_id': id,
        'medicine_name':
            medicine['name']?.toString() ?? '',
        'quantity': 1.0,
        'purchase_price':
            number(
          medicine['purchase_price']
                  ?.toString() ??
              '0',
        ),
        'batch_no':
            medicine['batch_no']?.toString() ?? '',
        'expiry_date':
            medicine['expiry_date']?.toString() ?? '',
      });
    });
  }

  void removeItem(int index) {
    setState(() {
      cart.removeAt(index);
    });
  }

  Future<void> savePurchase() async {
    if (selectedSupplierId == null) {
      showMessage(
        'Please select a supplier/company',
      );
      return;
    }

    if (cart.isEmpty) {
      showMessage(
        'Please add at least one medicine',
      );
      return;
    }

    if (paid > total) {
      showMessage(
        'Paid amount cannot be greater than total',
      );
      return;
    }

    setState(() {
      saving = true;
    });

    final db =
        await AppDatabase.instance.database;

    final now =
        DateTime.now().toIso8601String();

    try {
      await db.transaction(
        (txn) async {
          final purchaseId =
              await txn.insert(
            'purchases',
            {
              'invoice_no':
                  invoiceController.text
                          .trim()
                          .isEmpty
                      ? null
                      : invoiceController
                          .text
                          .trim(),
              'supplier_id':
                  selectedSupplierId,
              'purchase_date': now,
              'subtotal': subtotal,
              'discount': discount,
              'total': total,
              'paid': paid,
              'due': due,
              'created_at': now,
            },
          );

          for (final item in cart) {
            final medicineId =
                item['medicine_id'];

            final quantity =
                number(
              item['quantity'].toString(),
            );

            final purchasePrice =
                number(
              item['purchase_price']
                      .toString(),
            );

            final itemTotal =
                quantity * purchasePrice;

            final medicineResult =
                await txn.query(
              'medicines',
              columns: [
                'stock',
                'sale_price',
              ],
              where: 'id = ?',
              whereArgs: [medicineId],
              limit: 1,
            );

            if (medicineResult.isEmpty) {
              throw Exception(
                'Medicine not found',
              );
            }

            final currentStock =
                number(
              medicineResult.first['stock']
                      ?.toString() ??
                  '0',
            );

            await txn.insert(
              'purchase_items',
              {
                'purchase_id':
                    purchaseId,
                'medicine_id':
                    medicineId,
                'medicine_name':
                    item['medicine_name'],
                'quantity': quantity,
                'purchase_price':
                    purchasePrice,
                'total': itemTotal,
                'batch_no':
                    item['batch_no'],
                'expiry_date':
                    item['expiry_date'],
              },
            );

            await txn.update(
              'medicines',
              {
                'stock':
                    currentStock +
                        quantity,
                'purchase_price':
                    purchasePrice,
                'batch_no':
                    item['batch_no'],
                'expiry_date':
                    item['expiry_date'],
                'updated_at': now,
              },
              where: 'id = ?',
              whereArgs: [medicineId],
            );

            await txn.insert(
              'stock_movements',
              {
                'medicine_id':
                    medicineId,
                'type': 'PURCHASE',
                'quantity': quantity,
                'reference_id':
                    purchaseId,
                'note':
                    'Purchase',
                'created_at': now,
              },
            );
          }
        },
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Purchase saved successfully',
          ),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        saving = false;
      });

      showMessage('Error: $e');
    }
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  String money(double value) {
    return '৳${value.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title:
            const Text('New Purchase'),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding:
                  const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Purchase Information',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  DropdownButtonFormField<int>(
                    initialValue:
                        selectedSupplierId,
                    decoration:
                        const InputDecoration(
                      labelText:
                          'Supplier / Company *',
                      border:
                          OutlineInputBorder(),
                    ),
                    items: suppliers.map(
                      (supplier) {
                        return DropdownMenuItem<int>(
                          value:
                              supplier['id'] as int,
                          child: Text(
                            supplier['name']
                                    ?.toString() ??
                                '',
                          ),
                        );
                      },
                    ).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedSupplierId =
                            value;
                      });
                    },
                  ),

                  const SizedBox(height: 10),

                  TextField(
                    controller:
                        invoiceController,
                    decoration:
                        const InputDecoration(
                      labelText:
                          'Invoice Number',
                      border:
                          OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    'Add Medicine',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  TextField(
                    controller:
                        searchController,
                    onChanged: (_) =>
                        setState(() {}),
                    decoration:
                        const InputDecoration(
                      labelText:
                          'Search medicine',
                      prefixIcon:
                          Icon(Icons.search),
                      border:
                          OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 8),

                  ...filteredMedicines.map(
                    (medicine) {
                      return Card(
                        child: ListTile(
                          title: Text(
                            medicine['name']
                                    ?.toString() ??
                                '',
                          ),
                          subtitle: Text(
                            'Current stock: '
                            '${number(medicine['stock']?.toString() ?? '0').toStringAsFixed(0)}'
                            ' • Purchase: '
                            '${money(number(medicine['purchase_price']?.toString() ?? '0'))}',
                          ),
                          trailing:
                              IconButton(
                            onPressed: () =>
                                addMedicine(
                              medicine,
                            ),
                            icon:
                                const Icon(
                              Icons.add_circle,
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 15),

                  const Text(
                    'Purchase Items',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  if (cart.isEmpty)
                    const Center(
                      child: Padding(
                        padding:
                            EdgeInsets.all(20),
                        child: Text(
                          'No items added',
                        ),
                      ),
                    ),

                  ...cart.asMap().entries.map(
                    (entry) {
                      final index =
                          entry.key;
                      final item =
                          entry.value;

                      final quantity =
                          number(
                        item['quantity']
                                .toString(),
                      );

                      final price =
                          number(
                        item['purchase_price']
                                .toString(),
                      );

                      return Card(
                        child: Padding(
                          padding:
                              const EdgeInsets
                                  .all(10),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      item['medicine_name']
                                              ?.toString() ??
                                          '',
                                      style:
                                          const TextStyle(
                                        fontWeight:
                                            FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    onPressed:
                                        () =>
                                            removeItem(
                                      index,
                                    ),
                                    icon:
                                        const Icon(
                                      Icons
                                          .delete_outline,
                                    ),
                                  ),
                                ],
                              ),

                              Row(
                                children: [
                                  Expanded(
                                    child:
                                        TextField(
                                      controller:
                                          TextEditingController(
                                        text:
                                            quantity.toStringAsFixed(
                                          0,
                                        ),
                                      ),
                                      keyboardType:
                                          TextInputType
                                              .number,
                                      decoration:
                                          const InputDecoration(
                                        labelText:
                                            'Quantity',
                                        border:
                                            OutlineInputBorder(),
                                      ),
                                      onChanged:
                                          (value) {
                                        setState(
                                          () {
                                            cart[index]
                                                    ['quantity'] =
                                                number(
                                              value,
                                            );
                                          },
                                        );
                                      },
                                    ),
                                  ),

                                  const SizedBox(
                                    width: 8,
                                  ),

                                  Expanded(
                                    child:
                                        TextField(
                                      controller:
                                          TextEditingController(
                                        text:
                                            price.toStringAsFixed(
                                          2,
                                        ),
                                      ),
                                      keyboardType:
                                          const TextInputType
                                              .numberWithOptions(
                                        decimal:
                                            true,
                                      ),
                                      decoration:
                                          const InputDecoration(
                                        labelText:
                                            'Purchase Price',
                                        prefixText:
                                            '৳ ',
                                        border:
                                            OutlineInputBorder(),
                                      ),
                                      onChanged:
                                          (value) {
                                        setState(
                                          () {
                                            cart[index]
                                                    ['purchase_price'] =
                                                number(
                                              value,
                                            );
                                          },
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(
                                height: 8,
                              ),

                              Row(
                                children: [
                                  Expanded(
                                    child:
                                        TextField(
                                      controller:
                                          TextEditingController(
                                        text:
                                            item['batch_no']
                                                    ?.toString() ??
                                                '',
                                      ),
                                      decoration:
                                          const InputDecoration(
                                        labelText:
                                            'Batch No',
                                        border:
                                            OutlineInputBorder(),
                                      ),
                                      onChanged:
                                          (value) {
                                        cart[index]
                                                ['batch_no'] =
                                            value;
                                      },
                                    ),
                                  ),

                                  const SizedBox(
                                    width: 8,
                                  ),

                                  Expanded(
                                    child:
                                        TextField(
                                      controller:
                                          TextEditingController(
                                        text:
                                            item['expiry_date']
                                                    ?.toString() ??
                                                '',
                                      ),
                                      decoration:
                                          const InputDecoration(
                                        labelText:
                                            'Expiry YYYY-MM-DD',
                                        border:
                                            OutlineInputBorder(),
                                      ),
                                      onChanged:
                                          (value) {
                                        cart[index]
                                                ['expiry_date'] =
                                            value;
                                      },
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(
                                height: 8,
                              ),

                              Align(
                                alignment:
                                    Alignment
                                        .centerRight,
                                child: Text(
                                  'Total: ${money(quantity * price)}',
                                  style:
                                      const TextStyle(
                                    fontWeight:
                                        FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 15),

                  TextField(
                    controller:
                        discountController,
                    keyboardType:
                        const TextInputType
                            .numberWithOptions(
                      decimal: true,
                    ),
                    onChanged: (_) =>
                        setState(() {}),
                    decoration:
                        const InputDecoration(
                      labelText: 'Discount',
                      prefixText: '৳ ',
                      border:
                          OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 10),

                  DropdownButtonFormField<String>(
                    initialValue: paymentMethod,
                    decoration:
                        const InputDecoration(
                      labelText:
                          'Payment Method',
                      border:
                          OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'Cash',
                        child: Text('Cash'),
                      ),
                      DropdownMenuItem(
                        value: 'Card',
                        child: Text('Card'),
                      ),
                      DropdownMenuItem(
                        value: 'Mobile Banking',
                        child: Text(
                          'Mobile Banking',
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;

                      setState(() {
                        paymentMethod =
                            value;
                      });
                    },
                  ),

                  const SizedBox(height: 10),

                  TextField(
                    controller:
                        paidController,
                    keyboardType:
                        const TextInputType
                            .numberWithOptions(
                      decimal: true,
                    ),
                    onChanged: (_) =>
                        setState(() {}),
                    decoration:
                        const InputDecoration(
                      labelText:
                          'Paid Amount',
                      prefixText: '৳ ',
                      border:
                          OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 15),

                  Card(
                    child: Padding(
                      padding:
                          const EdgeInsets.all(15),
                      child: Column(
                        children: [
                          summary(
                            'Subtotal',
                            subtotal,
                          ),
                          summary(
                            'Discount',
                            discount,
                          ),
                          const Divider(),
                          summary(
                            'Total',
                            total,
                            bold: true,
                          ),
                          summary(
                            'Paid',
                            paid,
                          ),
                          summary(
                            'Supplier Due',
                            due,
                            bold: true,
                            color: due > 0
                                ? Colors.red
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding:
                  const EdgeInsets.all(12),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  onPressed:
                      saving
                          ? null
                          : savePurchase,
                  icon: saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child:
                              CircularProgressIndicator(),
                        )
                      : const Icon(
                          Icons.save,
                        ),
                  label: Text(
                    saving
                        ? 'Saving...'
                        : 'Save Purchase',
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget summary(
    String title,
    double value, {
    bool bold = false,
    Color? color,
  }) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        vertical: 4,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontWeight:
                    bold ? FontWeight.bold : null,
              ),
            ),
          ),
          Text(
            money(value),
            style: TextStyle(
              fontWeight:
                  bold ? FontWeight.bold : null,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
