import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../database/app_database.dart';

class MedicinesScreen extends StatefulWidget {
  const MedicinesScreen({super.key});

  @override
  State<MedicinesScreen> createState() => _MedicinesScreenState();
}

class _MedicinesScreenState extends State<MedicinesScreen> {
  final searchController = TextEditingController();

  List<Map<String, Object?>> medicines = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadMedicines();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> loadMedicines() async {
    setState(() {
      loading = true;
    });

    final db = await AppDatabase.instance.database;
    final search = searchController.text.trim();

    final List<Map<String, Object?>> result;

    if (search.isEmpty) {
      result = await db.rawQuery('''
        SELECT
          medicines.*,
          suppliers.name AS company_name
        FROM medicines
        LEFT JOIN suppliers
          ON medicines.company_id = suppliers.id
        ORDER BY medicines.name COLLATE NOCASE ASC
      ''');
    } else {
      result = await db.rawQuery('''
        SELECT
          medicines.*,
          suppliers.name AS company_name
        FROM medicines
        LEFT JOIN suppliers
          ON medicines.company_id = suppliers.id
        WHERE
          medicines.name LIKE ?
          OR medicines.generic_name LIKE ?
          OR medicines.barcode LIKE ?
          OR medicines.batch_no LIKE ?
          OR suppliers.name LIKE ?
        ORDER BY medicines.name COLLATE NOCASE ASC
      ''', [
        '%$search%',
        '%$search%',
        '%$search%',
        '%$search%',
        '%$search%',
      ]);
    }

    if (!mounted) return;

    setState(() {
      medicines = result;
      loading = false;
    });
  }

  Future<void> deleteMedicine(
    Map<String, Object?> medicine,
  ) async {
    final name = medicine['name']?.toString() ?? '';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Medicine'),
          content: Text(
            'Are you sure you want to delete "$name"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    final db = await AppDatabase.instance.database;

    await db.delete(
      'medicines',
      where: 'id = ?',
      whereArgs: [medicine['id']],
    );

    await loadMedicines();
  }

  Future<void> openMedicineForm({
    Map<String, Object?>? medicine,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) {
        return MedicineFormDialog(
          medicine: medicine,
        );
      },
    );

    if (result == true) {
      await loadMedicines();
    }
  }

  String formatDate(Object? value) {
    if (value == null || value.toString().isEmpty) {
      return '-';
    }

    try {
      final date = DateTime.parse(value.toString());

      return DateFormat('dd/MM/yyyy').format(date);
    } catch (_) {
      return value.toString();
    }
  }

  bool isExpired(Object? value) {
    if (value == null) return false;

    try {
      final date = DateTime.parse(value.toString());

      return date.isBefore(DateTime.now());
    } catch (_) {
      return false;
    }
  }

  bool isExpiringSoon(Object? value) {
    if (value == null) return false;

    try {
      final expiry = DateTime.parse(value.toString());
      final today = DateTime.now();
      final difference = expiry.difference(today).inDays;

      return difference >= 0 && difference <= 30;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => openMedicineForm(),
        icon: const Icon(Icons.add),
        label: const Text('Add Medicine'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: searchController,
              onChanged: (_) => loadMedicines(),
              decoration: InputDecoration(
                hintText:
                    'Search medicine, generic, company, barcode...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchController.text.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          searchController.clear();
                          loadMedicines();
                        },
                        icon: const Icon(Icons.clear),
                      )
                    : null,
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: loading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : medicines.isEmpty
                    ? const Center(
                        child: Text(
                          'No medicines found',
                          style: TextStyle(fontSize: 18),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: loadMedicines,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(
                            12,
                            0,
                            12,
                            90,
                          ),
                          itemCount: medicines.length,
                          itemBuilder: (context, index) {
                            final medicine = medicines[index];

                            final name =
                                medicine['name']?.toString() ?? '';

                            final generic =
                                medicine['generic_name']
                                        ?.toString() ??
                                    '';

                            final company =
                                medicine['company_name']
                                        ?.toString() ??
                                    '';

                            final batch =
                                medicine['batch_no']?.toString() ??
                                    '-';

                            final stock = double.tryParse(
                                  medicine['stock']?.toString() ?? '0',
                                ) ??
                                0;

                            final minStock = double.tryParse(
                                  medicine['min_stock']?.toString() ??
                                      '0',
                                ) ??
                                0;

                            final salePrice = double.tryParse(
                                  medicine['sale_price']?.toString() ??
                                      '0',
                                ) ??
                                0;

                            final purchasePrice = double.tryParse(
                                  medicine['purchase_price']
                                          ?.toString() ??
                                      '0',
                                ) ??
                                0;

                            final expiry =
                                medicine['expiry_date'];

                            final lowStock = stock <= minStock;
                            final expired = isExpired(expiry);
                            final expiringSoon =
                                isExpiringSoon(expiry);

                            return Card(
                              margin: const EdgeInsets.only(
                                bottom: 10,
                              ),
                              child: ListTile(
                                contentPadding:
                                    const EdgeInsets.all(12),
                                leading: CircleAvatar(
                                  child: Icon(
                                    expired
                                        ? Icons.warning
                                        : Icons.medication,
                                  ),
                                ),
                                title: Text(
                                  name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Padding(
                                  padding:
                                      const EdgeInsets.only(top: 6),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (generic.isNotEmpty)
                                        Text(
                                          generic,
                                          style: const TextStyle(
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      if (company.isNotEmpty)
                                        Text(
                                          'Company: $company',
                                        ),
                                      Text(
                                        'Batch: $batch',
                                      ),
                                      Text(
                                        'Expiry: ${formatDate(expiry)}',
                                        style: TextStyle(
                                          color: expired
                                              ? Colors.red
                                              : expiringSoon
                                                  ? Colors.orange
                                                  : null,
                                          fontWeight:
                                              expired || expiringSoon
                                                  ? FontWeight.bold
                                                  : null,
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Wrap(
                                        spacing: 15,
                                        runSpacing: 4,
                                        children: [
                                          Text(
                                            'Stock: ${stock.toStringAsFixed(0)}',
                                            style: TextStyle(
                                              fontWeight:
                                                  FontWeight.bold,
                                              color: lowStock
                                                  ? Colors.red
                                                  : null,
                                            ),
                                          ),
                                          Text(
                                            'Buy: ৳${purchasePrice.toStringAsFixed(2)}',
                                          ),
                                          Text(
                                            'Sell: ৳${salePrice.toStringAsFixed(2)}',
                                          ),
                                        ],
                                      ),
                                      if (lowStock)
                                        const Padding(
                                          padding:
                                              EdgeInsets.only(top: 4),
                                          child: Text(
                                            'LOW STOCK',
                                            style: TextStyle(
                                              color: Colors.red,
                                              fontWeight:
                                                  FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      if (expired)
                                        const Padding(
                                          padding:
                                              EdgeInsets.only(top: 4),
                                          child: Text(
                                            'EXPIRED',
                                            style: TextStyle(
                                              color: Colors.red,
                                              fontWeight:
                                                  FontWeight.bold,
                                            ),
                                          ),
                                        )
                                      else if (expiringSoon)
                                        const Padding(
                                          padding:
                                              EdgeInsets.only(top: 4),
                                          child: Text(
                                            'EXPIRING WITHIN 30 DAYS',
                                            style: TextStyle(
                                              color: Colors.orange,
                                              fontWeight:
                                                  FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                trailing:
                                    PopupMenuButton<String>(
                                  onSelected: (value) {
                                    if (value == 'edit') {
                                      openMedicineForm(
                                        medicine: medicine,
                                      );
                                    }

                                    if (value == 'delete') {
                                      deleteMedicine(medicine);
                                    }
                                  },
                                  itemBuilder: (_) => const [
                                    PopupMenuItem(
                                      value: 'edit',
                                      child: Text('Edit'),
                                    ),
                                    PopupMenuItem(
                                      value: 'delete',
                                      child: Text('Delete'),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class MedicineFormDialog extends StatefulWidget {
  final Map<String, Object?>? medicine;

  const MedicineFormDialog({
    super.key,
    this.medicine,
  });

  @override
  State<MedicineFormDialog> createState() =>
      _MedicineFormDialogState();
}

class _MedicineFormDialogState
    extends State<MedicineFormDialog> {
  final formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final genericController = TextEditingController();
  final barcodeController = TextEditingController();
  final batchController = TextEditingController();
  final expiryController = TextEditingController();
  final purchasePriceController = TextEditingController();
  final salePriceController = TextEditingController();
  final stockController = TextEditingController();
  final minStockController = TextEditingController();

  List<Map<String, Object?>> suppliers = [];

  int? selectedSupplierId;
  bool loadingSuppliers = true;
  bool saving = false;

  bool get isEditing => widget.medicine != null;

  @override
  void initState() {
    super.initState();

    final medicine = widget.medicine;

    if (medicine != null) {
      nameController.text =
          medicine['name']?.toString() ?? '';

      genericController.text =
          medicine['generic_name']?.toString() ?? '';

      barcodeController.text =
          medicine['barcode']?.toString() ?? '';

      batchController.text =
          medicine['batch_no']?.toString() ?? '';

      expiryController.text =
          medicine['expiry_date']?.toString() ?? '';

      purchasePriceController.text =
          medicine['purchase_price']?.toString() ?? '0';

      salePriceController.text =
          medicine['sale_price']?.toString() ?? '0';

      stockController.text =
          medicine['stock']?.toString() ?? '0';

      minStockController.text =
          medicine['min_stock']?.toString() ?? '0';

      final companyId = medicine['company_id'];

      if (companyId != null) {
        selectedSupplierId = int.tryParse(
          companyId.toString(),
        );
      }
    }

    loadSuppliers();
  }

  Future<void> loadSuppliers() async {
    final db = await AppDatabase.instance.database;

    final result = await db.query(
      'suppliers',
      orderBy: 'name COLLATE NOCASE ASC',
    );

    if (!mounted) return;

    setState(() {
      suppliers = result;
      loadingSuppliers = false;
    });
  }

  @override
  void dispose() {
    nameController.dispose();
    genericController.dispose();
    barcodeController.dispose();
    batchController.dispose();
    expiryController.dispose();
    purchasePriceController.dispose();
    salePriceController.dispose();
    stockController.dispose();
    minStockController.dispose();

    super.dispose();
  }

  double number(String value) {
    return double.tryParse(value.trim()) ?? 0;
  }

  Future<void> selectExpiryDate() async {
    DateTime initialDate = DateTime.now();

    if (expiryController.text.isNotEmpty) {
      try {
        initialDate = DateTime.parse(
          expiryController.text,
        );
      } catch (_) {}
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (picked == null) return;

    expiryController.text =
        DateFormat('yyyy-MM-dd').format(picked);
  }

  Future<void> save() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    if (number(purchasePriceController.text) < 0 ||
        number(salePriceController.text) < 0 ||
        number(stockController.text) < 0 ||
        number(minStockController.text) < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Price and stock cannot be negative',
          ),
        ),
      );
      return;
    }

    setState(() {
      saving = true;
    });

    final db = await AppDatabase.instance.database;
    final now = DateTime.now().toIso8601String();

    final data = {
      'name': nameController.text.trim(),
      'generic_name': genericController.text.trim(),
      'company_id': selectedSupplierId,
      'barcode': barcodeController.text.trim().isEmpty
          ? null
          : barcodeController.text.trim(),
      'batch_no': batchController.text.trim().isEmpty
          ? null
          : batchController.text.trim(),
      'expiry_date': expiryController.text.trim().isEmpty
          ? null
          : expiryController.text.trim(),
      'purchase_price':
          number(purchasePriceController.text),
      'sale_price':
          number(salePriceController.text),
      'stock': number(stockController.text),
      'min_stock': number(minStockController.text),
      'updated_at': now,
    };

    try {
      if (isEditing) {
        await db.update(
          'medicines',
          data,
          where: 'id = ?',
          whereArgs: [
            widget.medicine!['id'],
          ],
        );
      } else {
        await db.insert(
          'medicines',
          {
            ...data,
            'created_at': now,
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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
        ),
      );
    }
  }

  InputDecoration decoration(String label) {
    return InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        isEditing ? 'Edit Medicine' : 'Add Medicine',
      ),
      content: SizedBox(
        width: 500,
        child: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  controller: nameController,
                  decoration:
                      decoration('Medicine Name *'),
                  validator: (value) {
                    if (value == null ||
                        value.trim().isEmpty) {
                      return 'Medicine name is required';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 12),

                TextFormField(
                  controller: genericController,
                  decoration:
                      decoration('Generic Name'),
                ),

                const SizedBox(height: 12),

                if (loadingSuppliers)
                  const LinearProgressIndicator()
                else
                  DropdownButtonFormField<int?>(
                    value: selectedSupplierId,
                    decoration:
                        decoration('Company / Supplier'),
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('No Company'),
                      ),
                      ...suppliers.map(
                        (supplier) {
                          final id = int.parse(
                            supplier['id'].toString(),
                          );

                          return DropdownMenuItem<int?>(
                            value: id,
                            child: Text(
                              supplier['name']?.toString() ??
                                  '',
                            ),
                          );
                        },
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        selectedSupplierId = value;
                      });
                    },
                  ),

                const SizedBox(height: 12),

                TextFormField(
                  controller: barcodeController,
                  decoration:
                      decoration('Barcode'),
                ),

                const SizedBox(height: 12),

                TextFormField(
                  controller: batchController,
                  decoration:
                      decoration('Batch Number'),
                ),

                const SizedBox(height: 12),

                TextFormField(
                  controller: expiryController,
                  readOnly: true,
                  onTap: selectExpiryDate,
                  decoration: decoration(
                    'Expiry Date',
                  ).copyWith(
                    suffixIcon:
                        const Icon(Icons.calendar_month),
                  ),
                ),

                const SizedBox(height: 12),

                TextFormField(
                  controller: purchasePriceController,
                  keyboardType:
                      const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration:
                      decoration('Purchase Price')
                          .copyWith(
                    prefixText: '৳ ',
                  ),
                ),

                const SizedBox(height: 12),

                TextFormField(
                  controller: salePriceController,
                  keyboardType:
                      const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration:
                      decoration('Sale Price')
                          .copyWith(
                    prefixText: '৳ ',
                  ),
                ),

                const SizedBox(height: 12),

                TextFormField(
                  controller: stockController,
                  keyboardType:
                      const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration:
                      decoration('Current Stock'),
                ),

                const SizedBox(height: 12),

                TextFormField(
                  controller: minStockController,
                  keyboardType:
                      const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration:
                      decoration('Minimum Stock'),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: saving
              ? null
              : () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: saving ? null : save,
          child: saving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}
