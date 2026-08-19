import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../database/app_database.dart';

class SuppliersScreen extends StatefulWidget {
  const SuppliersScreen({super.key});

  @override
  State<SuppliersScreen> createState() =>
      _SuppliersScreenState();
}

class _SuppliersScreenState
    extends State<SuppliersScreen> {
  List<Map<String, Object?>> suppliers = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadSuppliers();
  }

  Future<void> loadSuppliers() async {
    setState(() {
      loading = true;
    });

    final db = await AppDatabase.instance.database;

    final result = await db.rawQuery('''
      SELECT
        s.*,
        COALESCE(
          (
            SELECT SUM(p.total)
            FROM purchases p
            WHERE p.supplier_id = s.id
          ),
          0
        ) AS total_purchase,

        COALESCE(
          (
            SELECT SUM(p.paid)
            FROM purchases p
            WHERE p.supplier_id = s.id
          ),
          0
        ) AS total_paid,

        COALESCE(
          (
            SELECT SUM(p.due)
            FROM purchases p
            WHERE p.supplier_id = s.id
          ),
          0
        ) AS purchase_due,

        COALESCE(
          (
            SELECT SUM(sp.amount)
            FROM supplier_payments sp
            WHERE sp.supplier_id = s.id
          ),
          0
        ) AS payment_amount

      FROM suppliers s
      ORDER BY s.name COLLATE NOCASE ASC
    ''');

    if (!mounted) return;

    setState(() {
      suppliers = result;
      loading = false;
    });
  }

  double number(Object? value) {
    return double.tryParse(
          value?.toString() ?? '0',
        ) ??
        0;
  }

  String money(Object? value) {
    return '৳${number(value).toStringAsFixed(2)}';
  }

  Future<void> addSupplier() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) =>
          const SupplierFormDialog(),
    );

    if (result == true) {
      await loadSuppliers();
    }
  }

  Future<void> editSupplier(
    Map<String, Object?> supplier,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => SupplierFormDialog(
        supplier: supplier,
      ),
    );

    if (result == true) {
      await loadSuppliers();
    }
  }

  Future<void> makePayment(
    Map<String, Object?> supplier,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => SupplierPaymentDialog(
        supplier: supplier,
      ),
    );

    if (result == true) {
      await loadSuppliers();
    }
  }

  Future<void> showDetails(
    Map<String, Object?> supplier,
  ) async {
    final db =
        await AppDatabase.instance.database;

    final purchases = await db.rawQuery(
      '''
      SELECT *
      FROM purchases
      WHERE supplier_id = ?
      ORDER BY id DESC
      ''',
      [supplier['id']],
    );

    final payments = await db.query(
      'supplier_payments',
      where: 'supplier_id = ?',
      whereArgs: [supplier['id']],
      orderBy: 'id DESC',
    );

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          supplier['name']?.toString() ??
              'Supplier',
        ),
        content: SizedBox(
          width: 600,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Phone: '
                  '${supplier['phone'] ?? '-'}',
                ),
                Text(
                  'Address: '
                  '${supplier['address'] ?? '-'}',
                ),

                const SizedBox(height: 15),

                const Text(
                  'Purchase History',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                if (purchases.isEmpty)
                  const Text(
                    'No purchase found',
                  ),

                ...purchases.map(
                  (purchase) {
                    return ListTile(
                      dense: true,
                      contentPadding:
                          EdgeInsets.zero,
                      title: Text(
                        purchase['invoice_no']
                                ?.toString() ??
                            'Purchase #'
                                '${purchase['id']}',
                      ),
                      subtitle: Text(
                        'Total: '
                        '${money(purchase['total'])} '
                        ' | Paid: '
                        '${money(purchase['paid'])} '
                        ' | Due: '
                        '${money(purchase['due'])}',
                      ),
                    );
                  },
                ),

                const Divider(),

                const Text(
                  'Payment History',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                if (payments.isEmpty)
                  const Text(
                    'No payment found',
                  ),

                ...payments.map(
                  (payment) {
                    return ListTile(
                      dense: true,
                      contentPadding:
                          EdgeInsets.zero,
                      title: Text(
                        money(
                          payment['amount'],
                        ),
                      ),
                      subtitle: Text(
                        '${payment['payment_method'] ?? 'Cash'}'
                        ' • '
                        '${formatDate(payment['payment_date'])}',
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String formatDate(Object? value) {
    if (value == null) return '-';

    try {
      return DateFormat('dd/MM/yyyy').format(
        DateTime.parse(value.toString()),
      );
    } catch (_) {
      return value.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Suppliers / Companies',
        ),
      ),
      floatingActionButton:
          FloatingActionButton.extended(
        onPressed: addSupplier,
        icon: const Icon(Icons.add),
        label: const Text('Add Company'),
      ),
      body: loading
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : suppliers.isEmpty
              ? const Center(
                  child: Text(
                    'No companies found',
                    style: TextStyle(
                      fontSize: 18,
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: loadSuppliers,
                  child: ListView.builder(
                    padding:
                        const EdgeInsets.fromLTRB(
                      12,
                      12,
                      12,
                      90,
                    ),
                    itemCount:
                        suppliers.length,
                    itemBuilder:
                        (context, index) {
                      final supplier =
                          suppliers[index];

                      final totalPurchase =
                          number(
                        supplier[
                            'total_purchase'],
                      );

                      final totalPaid =
                          number(
                        supplier[
                            'total_paid'],
                      );

                      final purchaseDue =
                          number(
                        supplier[
                            'purchase_due'],
                      );

                      final paymentAmount =
                          number(
                        supplier[
                            'payment_amount'],
                      );

                      final due =
                          purchaseDue -
                          paymentAmount;

                      return Card(
                        margin:
                            const EdgeInsets.only(
                          bottom: 10,
                        ),
                        child: ListTile(
                          onTap: () =>
                              showDetails(
                            supplier,
                          ),
                          leading:
                              const CircleAvatar(
                            child: Icon(
                              Icons.business,
                            ),
                          ),
                          title: Text(
                            supplier['name']
                                    ?.toString() ??
                                '',
                            style:
                                const TextStyle(
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                          subtitle:
                              Padding(
                            padding:
                                const EdgeInsets
                                    .only(
                              top: 5,
                            ),
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment
                                      .start,
                              children: [
                                if (supplier[
                                            'phone']
                                        ?.toString()
                                        .isNotEmpty ==
                                    true)
                                  Text(
                                    'Phone: '
                                    '${supplier['phone']}',
                                  ),

                                Text(
                                  'Purchase: '
                                  '${money(totalPurchase)}',
                                ),

                                Text(
                                  'Paid: '
                                  '${money(totalPaid + paymentAmount)}',
                                ),

                                Text(
                                  'Due: '
                                  '${money(due)}',
                                  style:
                                      TextStyle(
                                    color: due > 0
                                        ? Colors.red
                                        : Colors.green,
                                    fontWeight:
                                        FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          trailing:
                              PopupMenuButton<
                                  String>(
                            onSelected:
                                (value) {
                              if (value ==
                                  'payment') {
                                makePayment(
                                  supplier,
                                );
                              }

                              if (value ==
                                  'edit') {
                                editSupplier(
                                  supplier,
                                );
                              }

                              if (value ==
                                  'details') {
                                showDetails(
                                  supplier,
                                );
                              }
                            },
                            itemBuilder:
                                (_) => const [
                              PopupMenuItem(
                                value:
                                    'payment',
                                child: Text(
                                  'Pay Due',
                                ),
                              ),
                              PopupMenuItem(
                                value:
                                    'details',
                                child: Text(
                                  'Details',
                                ),
                              ),
                              PopupMenuItem(
                                value: 'edit',
                                child: Text(
                                  'Edit',
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

class SupplierFormDialog
    extends StatefulWidget {
  final Map<String, Object?>? supplier;

  const SupplierFormDialog({
    super.key,
    this.supplier,
  });

  @override
  State<SupplierFormDialog> createState() =>
      _SupplierFormDialogState();
}

class _SupplierFormDialogState
    extends State<SupplierFormDialog> {
  final formKey =
      GlobalKey<FormState>();

  final nameController =
      TextEditingController();

  final phoneController =
      TextEditingController();

  final addressController =
      TextEditingController();

  bool saving = false;

  bool get editing =>
      widget.supplier != null;

  @override
  void initState() {
    super.initState();

    final supplier =
        widget.supplier;

    if (supplier != null) {
      nameController.text =
          supplier['name']
                  ?.toString() ??
              '';

      phoneController.text =
          supplier['phone']
                  ?.toString() ??
              '';

      addressController.text =
          supplier['address']
                  ?.toString() ??
              '';
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    addressController.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (!formKey.currentState!
        .validate()) {
      return;
    }

    setState(() {
      saving = true;
    });

    final db =
        await AppDatabase.instance.database;

    try {
      final data = {
        'name':
            nameController.text.trim(),
        'phone':
            phoneController.text.trim(),
        'address':
            addressController.text.trim(),
        'updated_at':
            DateTime.now()
                .toIso8601String(),
      };

      if (editing) {
        await db.update(
          'suppliers',
          data,
          where: 'id = ?',
          whereArgs: [
            widget.supplier!['id'],
          ],
        );
      } else {
        await db.insert(
          'suppliers',
          {
            ...data,
            'opening_due': 0,
            'created_at':
                DateTime.now()
                    .toIso8601String(),
          },
        );
      }

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        saving = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Error: $e',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        editing
            ? 'Edit Company'
            : 'Add Company',
      ),
      content: Form(
        key: formKey,
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextFormField(
                controller:
                    nameController,
                decoration:
                    const InputDecoration(
                  labelText:
                      'Company Name *',
                  border:
                      OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null ||
                      value.trim().isEmpty) {
                    return
                        'Company name is required';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 10),

              TextFormField(
                controller:
                    phoneController,
                keyboardType:
                    TextInputType.phone,
                decoration:
                    const InputDecoration(
                  labelText: 'Phone',
                  border:
                      OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 10),

              TextFormField(
                controller:
                    addressController,
                maxLines: 3,
                decoration:
                    const InputDecoration(
                  labelText: 'Address',
                  border:
                      OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: saving
              ? null
              : () =>
                  Navigator.pop(
                    context,
                    false,
                  ),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed:
              saving ? null : save,
          child: saving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child:
                      CircularProgressIndicator(),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}

class SupplierPaymentDialog
    extends StatefulWidget {
  final Map<String, Object?> supplier;

  const SupplierPaymentDialog({
    super.key,
    required this.supplier,
  });

  @override
  State<SupplierPaymentDialog> createState() =>
      _SupplierPaymentDialogState();
}

class _SupplierPaymentDialogState
    extends State<SupplierPaymentDialog> {
  final amountController =
      TextEditingController();

  final noteController =
      TextEditingController();

  String paymentMethod = 'Cash';

  bool saving = false;

  @override
  void dispose() {
    amountController.dispose();
    noteController.dispose();
    super.dispose();
  }

  double number(Object? value) {
    return double.tryParse(
          value?.toString() ?? '0',
        ) ??
        0;
  }

  Future<void> savePayment() async {
    final amount =
        number(amountController.text);

    if (amount <= 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content:
              Text('Enter a valid amount'),
        ),
      );
      return;
    }

    setState(() {
      saving = true;
    });

    final db =
        await AppDatabase.instance.database;

    try {
      await db.insert(
        'supplier_payments',
        {
          'supplier_id':
              widget.supplier['id'],
          'payment_date':
              DateTime.now()
                  .toIso8601String(),
          'amount': amount,
          'payment_method':
              paymentMethod,
          'note':
              noteController.text.trim(),
          'created_at':
              DateTime.now()
                  .toIso8601String(),
        },
      );

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        saving = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Error: $e',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'Pay ${widget.supplier['name'] ?? ''}',
      ),
      content: SingleChildScrollView(
        child: Column(
          children: [
            TextField(
              controller:
                  amountController,
              keyboardType:
                  const TextInputType
                      .numberWithOptions(
                decimal: true,
              ),
              decoration:
                  const InputDecoration(
                labelText:
                    'Payment Amount',
                prefixText: '৳ ',
                border:
                    OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 10),

            DropdownButtonFormField<String>(
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
                  noteController,
              maxLines: 2,
              decoration:
                  const InputDecoration(
                labelText: 'Note',
                border:
                    OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: saving
              ? null
              : () =>
                  Navigator.pop(
                    context,
                    false,
                  ),
          child:
              const Text('Cancel'),
        ),
        FilledButton(
          onPressed:
              saving
                  ? null
                  : savePayment,
          child: saving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child:
                      CircularProgressIndicator(),
                )
              : const Text(
                  'Save Payment',
                ),
        ),
      ],
    );
  }
}
