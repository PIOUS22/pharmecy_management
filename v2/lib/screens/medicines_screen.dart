import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../database/app_database.dart';

class MedicinesScreen extends StatefulWidget {
  const MedicinesScreen({super.key});

  @override
  State<MedicinesScreen> createState() =>
      _MedicinesScreenState();
}

class _MedicinesScreenState
    extends State<MedicinesScreen> {
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

    List<Map<String, Object?>> result;

    if (search.isEmpty) {
      result = await db.query(
        'medicines',
        orderBy: 'name COLLATE NOCASE ASC',
      );
    } else {
      result = await db.query(
        'medicines',
        where: '''
          name LIKE ?
          OR generic_name LIKE ?
          OR barcode LIKE ?
          OR batch_no LIKE ?
        ''',
        whereArgs: [
          '%$search%',
          '%$search%',
          '%$search%',
          '%$search%',
        ],
        orderBy: 'name COLLATE NOCASE ASC',
      );
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
              onPressed: () =>
                  Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(context, true),
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
    if (value == null ||
        value.toString().isEmpty) {
      return '-';
    }

    try {
      final date =
          DateTime.parse(value.toString());

      return DateFormat('dd/MM/yyyy').format(date);
    } catch (_) {
      return value.toString();
    }
  }

  bool isExpired(Object? value) {
    if (value == null) return false;

    try {
      final date =
          DateTime.parse(value.toString());

      return date.isBefore(DateTime.now());
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: searchController,
                    onChanged: (_) =>
                        loadMedicines(),
                    decoration:
                        InputDecoration(
                      hintText:
                          'Search medicine...',
                      prefixIcon:
                          const Icon(
                        Icons.search,
                      ),
                      suffixIcon:
                          searchController
                                  .text
                                  .isNotEmpty
                              ? IconButton(
                                  onPressed: () {
                                    searchController
                                        .clear();
                                    loadMedicines();
                                  },
                                  icon:
                                      const Icon(
                                    Icons.clear,
                                  ),
                                )
                              : null,
                      border:
                          const OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                FilledButton.icon(
                  onPressed: () =>
                      openMedicineForm(),
                  icon:
                      const Icon(Icons.add),
                  label:
                      const Text('Add'),
                ),
              ],
            ),
          ),

          Expanded(
            child: loading
                ? const Center(
                    child:
                        CircularProgressIndicator(),
                  )
                : medicines.isEmpty
                    ? const Center(
                        child: Text(
                          'No medicines found',
                          style:
                              TextStyle(
                            fontSize: 18,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding:
                            const EdgeInsets
                                .fromLTRB(
                          12,
                          0,
                          12,
                          20,
                        ),
                        itemCount:
                            medicines.length,
                        itemBuilder:
                            (context, index) {
                          final medicine =
                              medicines[index];

                          final name =
                              medicine['name']
                                      ?.toString() ??
                                  '';

                          final generic =
                              medicine[
                                          'generic_name']
                                      ?.toString() ??
                                  '';

                          final batch =
                              medicine['batch_no']
                                      ?.toString() ??
                                  '-';

                          final stock =
                              double.tryParse(
                                    medicine[
                                                'stock']
                                            ?.toString() ??
                                        '0',
                                  ) ??
                                  0;

                          final minStock =
                              double.tryParse(
                                    medicine[
                                                'min_stock']
                                            ?.toString() ??
                                        '0',
                                  ) ??
                                  0;

                          final salePrice =
                              double.tryParse(
                                    medicine[
                                                'sale_price']
                                            ?.toString() ??
                                        '0',
                                  ) ??
                                  0;

                          final expiry =
                              medicine[
                                  'expiry_date'];

                          final lowStock =
                              stock <= minStock;

                          final expired =
                              isExpired(expiry);

                          return Card(
                            margin:
                                const EdgeInsets
                                    .only(
                              bottom: 10,
                            ),
                            child: ListTile(
                              leading:
                                  CircleAvatar(
                                child: Icon(
                                  expired
                                      ? Icons
                                          .warning
                                      : Icons
                                          .medication,
                                ),
                              ),
                              title: Text(
                                name,
                                style:
                                    const TextStyle(
                                  fontWeight:
                                      FontWeight
                                          .bold,
                                ),
                              ),
                              subtitle:
                                  Padding(
                                padding:
                                    const EdgeInsets
                                        .only(
                                  top: 5,
                                ),
                                child:
                                    Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment
                                          .start,
                                  children: [
                                    if (generic
                                        .isNotEmpty)
                                      Text(
                                        generic,
                                      ),
                                    Text(
                                      'Batch: $batch',
                                    ),
                                    Text(
                                      'Expiry: '
                                      '${formatDate(expiry)}',
                                    ),
                                    const SizedBox(
                                      height: 4,
                                    ),
                                    Row(
                                      children: [
                                        Text(
                                          'Stock: '
                                          '${stock.toStringAsFixed(0)}',
                                          style:
                                              TextStyle(
                                            fontWeight:
                                                FontWeight
                                                    .bold,
                                            color: lowStock
                                                ? Colors
                                                    .red
                                                : null,
                                          ),
                                        ),
                                        const SizedBox(
                                          width: 15,
                                        ),
                                        Text(
                                          'Price: '
                                          '৳${salePrice.toStringAsFixed(2)}',
                                        ),
                                      ],
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
                                      'edit') {
                                    openMedicineForm(
                                      medicine:
                                          medicine,
                                    );
                                  }

                                  if (value ==
                                      'delete') {
                                    deleteMedicine(
                                      medicine,
                                    );
                                  }
                                },
                                itemBuilder:
                                    (_) => const [
                                  PopupMenuItem(
                                    value:
                                        'edit',
                                    child: Text(
                                        'Edit'),
                                  ),
                                  PopupMenuItem(
                                    value:
                                        'delete',
                                    child: Text(
                                        'Delete'),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class MedicineFormDialog
    extends StatefulWidget {
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

  final nameController =
      TextEditingController();

  final genericController =
      TextEditingController();

  final companyController =
      TextEditingController();

  final barcodeController =
      TextEditingController();

  final batchController =
      TextEditingController();

  final expiryController =
      TextEditingController();

  final purchasePriceController =
      TextEditingController();

  final salePriceController =
      TextEditingController();

  final stockController =
      TextEditingController();

  final minStockController =
      TextEditingController();

  bool saving = false;

  bool get isEditing =>
      widget.medicine != null;

  @override
  void initState() {
    super.initState();

    final medicine = widget.medicine;

    if (medicine != null) {
      nameController.text =
          medicine['name']?.toString() ?? '';

      genericController.text =
          medicine['generic_name']
                  ?.toString() ??
              '';

      companyController.text =
          medicine['company_id']
                  ?.toString() ??
              '';

      barcodeController.text =
          medicine['barcode']?.toString() ??
              '';

      batchController.text =
          medicine['batch_no']?.toString() ??
              '';

      expiryController.text =
          medicine['expiry_date']?.toString() ??
              '';

      purchasePriceController.text =
          medicine['purchase_price']
                  ?.toString() ??
              '0';

      salePriceController.text =
          medicine['sale_price']?.toString() ??
              '0';

      stockController.text =
          medicine['stock']?.toString() ?? '0';

      minStockController.text =
          medicine['min_stock']?.toString() ??
              '0';
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    genericController.dispose();
    companyController.dispose();
    barcodeController.dispose();
    batchController.dispose();
    expiryController.dispose();
    purchasePriceController.dispose();
    salePriceController.dispose();
    stockController.dispose();
    minStockController.dispose();

    super.dispose();
  }

  double number(
    String value,
  ) {
    return double.tryParse(value) ?? 0;
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

    final now =
        DateTime.now().toIso8601String();

    final data = {
      'name': nameController.text.trim(),
      'generic_name':
          genericController.text.trim(),
      'company_id':
          companyController.text.trim().isEmpty
              ? null
              : int.tryParse(
                  companyController.text
                      .trim(),
                ),
      'barcode':
          barcodeController.text.trim(),
      'batch_no':
          batchController.text.trim(),
      'expiry_date':
          expiryController.text.trim().isEmpty
              ? null
              : expiryController.text.trim(),
      'purchase_price':
          number(
        purchasePriceController.text,
      ),
      'sale_price':
          number(
        salePriceController.text,
      ),
      'stock':
          number(
        stockController.text,
      ),
      'min_stock':
          number(
        minStockController.text,
      ),
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

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content:
              Text('Error: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        isEditing
            ? 'Edit Medicine'
            : 'Add Medicine',
      ),
      content: SizedBox(
        width: 500,
        child: Form(
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
                        'Medicine Name *',
                  ),
                  validator: (value) {
                    if (value == null ||
                        value.trim().isEmpty) {
                      return 'Medicine name is required';
                    }
                    return null;
                  },
                ),

                TextFormField(
                  controller:
                      genericController,
                  decoration:
                      const InputDecoration(
                    labelText:
                        'Generic Name',
                  ),
                ),

                TextFormField(
                  controller:
                      companyController,
                  keyboardType:
                      TextInputType.number,
                  decoration:
                      const InputDecoration(
                    labelText:
                        'Company ID',
                    hintText:
                        'Supplier module will replace this later',
                  ),
                ),

                TextFormField(
                  controller:
                      barcodeController,
                  decoration:
                      const InputDecoration(
                    labelText:
                        'Barcode',
                  ),
                ),

                TextFormField(
                  controller:
                      batchController,
                  decoration:
                      const InputDecoration(
                    labelText:
                        'Batch Number',
                  ),
                ),

                TextFormField(
                  controller:
                      expiryController,
                  decoration:
                      const InputDecoration(
                    labelText:
                        'Expiry Date',
                    hintText:
                        'YYYY-MM-DD',
                  ),
                ),

                TextFormField(
                  controller:
                      purchasePriceController,
                  keyboardType:
                      const TextInputType
                          .numberWithOptions(
                    decimal: true,
                  ),
                  decoration:
                      const InputDecoration(
                    labelText:
                        'Purchase Price',
                    prefixText: '৳ ',
                  ),
                ),

                TextFormField(
                  controller:
                      salePriceController,
                  keyboardType:
                      const TextInputType
                          .numberWithOptions(
                    decimal: true,
                  ),
                  decoration:
                      const InputDecoration(
                    labelText:
                        'Sale Price',
                    prefixText: '৳ ',
                  ),
                ),

                TextFormField(
                  controller:
                      stockController,
                  keyboardType:
                      const TextInputType
                          .numberWithOptions(
                    decimal: true,
                  ),
                  decoration:
                      const InputDecoration(
                    labelText:
                        'Current Stock',
                  ),
                ),

                TextFormField(
                  controller:
                      minStockController,
                  keyboardType:
                      const TextInputType
                          .numberWithOptions(
                    decimal: true,
                  ),
                  decoration:
                      const InputDecoration(
                    labelText:
                        'Minimum Stock',
                  ),
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
              : () => Navigator.pop(
                    context,
                    false,
                  ),
          child:
              const Text('Cancel'),
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
