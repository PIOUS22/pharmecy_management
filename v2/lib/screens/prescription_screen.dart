import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../database/app_database.dart';

class PrescriptionScreen extends StatefulWidget {
  const PrescriptionScreen({super.key});

  @override
  State<PrescriptionScreen> createState() =>
      _PrescriptionScreenState();
}

class _PrescriptionScreenState
    extends State<PrescriptionScreen> {
  List<Map<String, Object?>> prescriptions = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadPrescriptions();
  }

  Future<void> loadPrescriptions() async {
    setState(() {
      loading = true;
    });

    final db = await AppDatabase.instance.database;

    final result = await db.query(
      'prescriptions',
      orderBy: 'id DESC',
    );

    if (!mounted) return;

    setState(() {
      prescriptions = result;
      loading = false;
    });
  }

  String money(Object? value) {
    final amount =
        double.tryParse(value?.toString() ?? '0') ?? 0;

    return '৳${amount.toStringAsFixed(2)}';
  }

  String formatDate(Object? value) {
    if (value == null) return '-';

    try {
      final date = DateTime.parse(value.toString());

      return DateFormat('dd/MM/yyyy').format(date);
    } catch (_) {
      return value.toString();
    }
  }

  Future<void> createPrescription() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const PrescriptionCreateScreen(),
      ),
    );

    if (result == true) {
      await loadPrescriptions();
    }
  }

  Future<void> showPrescription(
    Map<String, Object?> prescription,
  ) async {
    final db = await AppDatabase.instance.database;

    final items = await db.query(
      'prescription_items',
      where: 'prescription_id = ?',
      whereArgs: [prescription['id']],
    );

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text(
            'Prescription ${prescription['prescription_no']}',
          ),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    'Patient: '
                    '${prescription['patient_name']}',
                  ),
                  if ((prescription['patient_phone']
                              ?.toString() ??
                          '')
                      .isNotEmpty)
                    Text(
                      'Phone: '
                      '${prescription['patient_phone']}',
                    ),
                  if ((prescription['doctor_name']
                              ?.toString() ??
                          '')
                      .isNotEmpty)
                    Text(
                      'Doctor: '
                      '${prescription['doctor_name']}',
                    ),
                  Text(
                    'Date: '
                    '${formatDate(prescription['sale_date'])}',
                  ),
                  const Divider(),

                  ...items.map(
                    (item) {
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
                              '${item['quantity']} × '
                              '${money(item['unit_price'])}',
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  const Divider(),

                  _summaryRow(
                    'Subtotal',
                    money(prescription['subtotal']),
                  ),
                  _summaryRow(
                    'Discount',
                    money(prescription['discount']),
                  ),
                  _summaryRow(
                    'Total',
                    money(prescription['total']),
                  ),
                  _summaryRow(
                    'Paid',
                    money(prescription['paid']),
                  ),
                  _summaryRow(
                    'Due',
                    money(prescription['due']),
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
        );
      },
    );
  }

  Widget _summaryRow(
    String title,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 3,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Text(value),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton:
          FloatingActionButton.extended(
        onPressed: createPrescription,
        icon: const Icon(Icons.add),
        label: const Text('New Prescription'),
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : prescriptions.isEmpty
              ? const Center(
                  child: Text(
                    'No prescription sales yet',
                    style: TextStyle(fontSize: 18),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: loadPrescriptions,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(
                      12,
                      12,
                      12,
                      90,
                    ),
                    itemCount: prescriptions.length,
                    itemBuilder: (context, index) {
                      final prescription =
                          prescriptions[index];

                      final due =
                          double.tryParse(
                                prescription['due']
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
                              showPrescription(
                            prescription,
                          ),
                          leading: CircleAvatar(
                            child: const Icon(
                              Icons.receipt_long,
                            ),
                          ),
                          title: Text(
                            prescription[
                                        'prescription_no']
                                    ?.toString() ??
                                '',
                            style: const TextStyle(
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Patient: '
                                '${prescription['patient_name']}',
                              ),
                              Text(
                                'Date: '
                                '${formatDate(prescription['sale_date'])}',
                              ),
                              Text(
                                'Total: '
                                '${money(prescription['total'])}',
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

class PrescriptionCreateScreen
    extends StatefulWidget {
  const PrescriptionCreateScreen({
    super.key,
  });

  @override
  State<PrescriptionCreateScreen> createState() =>
      _PrescriptionCreateScreenState();
}

class _PrescriptionCreateScreenState
    extends State<PrescriptionCreateScreen> {
  final patientNameController =
      TextEditingController();

  final patientPhoneController =
      TextEditingController();

  final doctorController =
      TextEditingController();

  final discountController =
      TextEditingController(text: '0');

  final paidController =
      TextEditingController(text: '0');

  final searchController =
      TextEditingController();

  List<Map<String, Object?>> medicines = [];

  List<Map<String, Object?>> cart = [];

  bool loadingMedicines = true;
  bool saving = false;

  String paymentMethod = 'Cash';

  @override
  void initState() {
    super.initState();
    loadMedicines();
  }

  @override
  void dispose() {
    patientNameController.dispose();
    patientPhoneController.dispose();
    doctorController.dispose();
    discountController.dispose();
    paidController.dispose();
    searchController.dispose();

    super.dispose();
  }

  Future<void> loadMedicines() async {
    final db =
        await AppDatabase.instance.database;

    final search =
        searchController.text.trim();

    List<Map<String, Object?>> result;

    if (search.isEmpty) {
      result = await db.query(
        'medicines',
        where: 'stock > ?',
        whereArgs: [0],
        orderBy:
            'name COLLATE NOCASE ASC',
      );
    } else {
      result = await db.query(
        'medicines',
        where: '''
          stock > ?
          AND (
            name LIKE ?
            OR generic_name LIKE ?
            OR barcode LIKE ?
          )
        ''',
        whereArgs: [
          0,
          '%$search%',
          '%$search%',
          '%$search%',
        ],
        orderBy:
            'name COLLATE NOCASE ASC',
      );
    }

    if (!mounted) return;

    setState(() {
      medicines = result;
      loadingMedicines = false;
    });
  }

  double number(String value) {
    return double.tryParse(
          value.trim(),
        ) ??
        0;
  }

  double get subtotal {
    return cart.fold<double>(
      0,
      (sum, item) {
        final quantity =
            number(item['quantity'].toString());

        final price =
            number(item['unit_price'].toString());

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

  void addMedicine(
    Map<String, Object?> medicine,
  ) {
    final id = medicine['id'];

    final index = cart.indexWhere(
      (item) => item['medicine_id'] == id,
    );

    final stock =
        number(medicine['stock'].toString());

    if (index >= 0) {
      final current =
          number(
        cart[index]['quantity'].toString(),
      );

      if (current + 1 > stock) {
        showMessage(
          'Not enough stock',
        );
        return;
      }

      setState(() {
        cart[index]['quantity'] =
            current + 1;
      });

      return;
    }

    setState(() {
      cart.add({
        'medicine_id': id,
        'medicine_name':
            medicine['name']?.toString() ?? '',
        'quantity': 1.0,
        'unit_price':
            number(
          medicine['sale_price']?.toString() ??
              '0',
        ),
        'purchase_price':
            number(
          medicine['purchase_price']
                  ?.toString() ??
              '0',
        ),
        'stock': stock,
      });
    });
  }

  void removeMedicine(int index) {
    setState(() {
      cart.removeAt(index);
    });
  }

  void changeQuantity(
    int index,
    double quantity,
  ) {
    final stock =
        number(
      cart[index]['stock'].toString(),
    );

    if (quantity <= 0) {
      removeMedicine(index);
      return;
    }

    if (quantity > stock) {
      showMessage(
        'Available stock: ${stock.toStringAsFixed(0)}',
      );
      return;
    }

    setState(() {
      cart[index]['quantity'] =
          quantity;
    });
  }

  String generatePrescriptionNo() {
    final now = DateTime.now();

    return 'RX-${DateFormat('yyyyMMddHHmmss').format(now)}';
  }

  Future<void> savePrescription() async {
    if (patientNameController.text
        .trim()
        .isEmpty) {
      showMessage(
        'Patient name is required',
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

    final prescriptionNo =
        generatePrescriptionNo();

    try {
      await db.transaction(
        (txn) async {
          final prescriptionId =
              await txn.insert(
            'prescriptions',
            {
              'prescription_no':
                  prescriptionNo,
              'patient_name':
                  patientNameController
                      .text
                      .trim(),
              'patient_phone':
                  patientPhoneController
                      .text
                      .trim(),
              'doctor_name':
                  doctorController.text
                      .trim(),
              'sale_date': now,
              'subtotal': subtotal,
              'discount': discount,
              'total': total,
              'paid': paid,
              'due': due,
              'payment_method':
                  paymentMethod,
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

            final unitPrice =
                number(
              item['unit_price'].toString(),
            );

            final purchasePrice =
                number(
              item['purchase_price']
                      .toString(),
            );

            final itemTotal =
                quantity * unitPrice;

            final stockResult =
                await txn.query(
              'medicines',
              columns: ['stock'],
              where: 'id = ?',
              whereArgs: [medicineId],
              limit: 1,
            );

            if (stockResult.isEmpty) {
              throw Exception(
                'Medicine not found',
              );
            }

            final currentStock =
                number(
              stockResult.first['stock']
                      ?.toString() ??
                  '0',
            );

            if (currentStock <
                quantity) {
              throw Exception(
                'Insufficient stock for '
                '${item['medicine_name']}',
              );
            }

            await txn.insert(
              'prescription_items',
              {
                'prescription_id':
                    prescriptionId,
                'medicine_id':
                    medicineId,
                'medicine_name':
                    item['medicine_name'],
                'quantity': quantity,
                'unit_price':
                    unitPrice,
                'purchase_price':
                    purchasePrice,
                'total': itemTotal,
              },
            );

            await txn.update(
              'medicines',
              {
                'stock':
                    currentStock -
                        quantity,
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
                'type': 'SALE',
                'quantity':
                    -quantity,
                'reference_id':
                    prescriptionId,
                'note':
                    'Prescription sale $prescriptionNo',
                'created_at': now,
              },
            );
          }

          if (due > 0) {
            await txn.insert(
              'customer_dues',
              {
                'prescription_id':
                    prescriptionId,
                'customer_name':
                    patientNameController
                        .text
                        .trim(),
                'phone':
                    patientPhoneController
                        .text
                        .trim(),
                'amount': total,
                'paid': paid,
                'due': due,
                'created_at': now,
              },
            );
          }
        },
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Prescription saved: $prescriptionNo',
          ),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        saving = false;
      });

      showMessage(
        'Error: $e',
      );
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
    return Scaffold(
      appBar: AppBar(
        title:
            const Text('New Prescription Sale'),
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
                    'Patient Information',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  TextField(
                    controller:
                        patientNameController,
                    decoration:
                        const InputDecoration(
                      labelText:
                          'Patient Name *',
                      border:
                          OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 10),

                  TextField(
                    controller:
                        patientPhoneController,
                    keyboardType:
                        TextInputType.phone,
                    decoration:
                        const InputDecoration(
                      labelText:
                          'Patient Phone',
                      border:
                          OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 10),

                  TextField(
                    controller:
                        doctorController,
                    decoration:
                        const InputDecoration(
                      labelText:
                          'Doctor Name',
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
                        loadMedicines(),
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

                  if (loadingMedicines)
                    const Center(
                      child:
                          CircularProgressIndicator(),
                    )
                  else
                    ...medicines.take(8).map(
                      (medicine) {
                        final stock =
                            number(
                          medicine['stock']
                                  ?.toString() ??
                              '0',
                        );

                        return Card(
                          child: ListTile(
                            title: Text(
                              medicine['name']
                                      ?.toString() ??
                                  '',
                            ),
                            subtitle: Text(
                              'Stock: '
                              '${stock.toStringAsFixed(0)}'
                              ' • '
                              '৳${number(medicine['sale_price']?.toString() ?? '0').toStringAsFixed(2)}',
                            ),
                            trailing:
                                IconButton(
                              icon: const Icon(
                                Icons.add_circle,
                              ),
                              onPressed: () =>
                                  addMedicine(
                                medicine,
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                  const SizedBox(height: 20),

                  const Text(
                    'Selected Medicines',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  if (cart.isEmpty)
                    const Padding(
                      padding:
                          EdgeInsets.all(20),
                      child: Center(
                        child: Text(
                          'No medicine added',
                        ),
                      ),
                    )
                  else
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
                          item['unit_price']
                                  .toString(),
                        );

                        return Card(
                          child: Padding(
                            padding:
                                const EdgeInsets
                                    .all(10),
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment
                                      .start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child:
                                          Text(
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
                                              removeMedicine(
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
                                          Text(
                                        money(
                                          price,
                                        ),
                                      ),
                                    ),

                                    SizedBox(
                                      width:
                                          130,
                                      child:
                                          TextFormField(
                                        initialValue:
                                            quantity
                                                .toStringAsFixed(
                                          0,
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
                                              'Qty',
                                          border:
                                              OutlineInputBorder(),
                                        ),
                                        onChanged:
                                            (value) {
                                          changeQuantity(
                                            index,
                                            number(
                                              value,
                                            ),
                                          );
                                        },
                                      ),
                                    ),

                                    const SizedBox(
                                      width:
                                          10,
                                    ),

                                    Text(
                                      money(
                                        quantity *
                                            price,
                                      ),
                                      style:
                                          const TextStyle(
                                        fontWeight:
                                            FontWeight.bold,
                                      ),
                                    ),
                                  ],
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

                  DropdownButtonFormField<
                      String>(
                    initialValue:
                        paymentMethod,
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
                      labelText: 'Paid Amount',
                      prefixText: '৳ ',
                      border:
                          OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 20),

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
                            'Due',
                            due,
                            color: due > 0
                                ? Colors.red
                                : null,
                            bold: true,
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
                          : savePrescription,
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
                        : 'Complete Sale',
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
                fontWeight: bold
                    ? FontWeight.bold
                    : null,
              ),
            ),
          ),
          Text(
            money(value),
            style: TextStyle(
              fontWeight: bold
                  ? FontWeight.bold
                  : null,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
