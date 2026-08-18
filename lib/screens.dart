import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'db.dart';

String money(num n) => '৳${n.toStringAsFixed(2)}';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int tab = 0;

  void refresh() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      Dashboard(key: ValueKey('dashboard-$tab')),
      MedicinePage(key: ValueKey('medicine-$tab')),
      SalePage(key: ValueKey('sale-$tab')),
      ReportPage(key: ValueKey('report-$tab')),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pharmacy POS'),
        centerTitle: true,
      ),
      body: pages[tab],
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (i) {
          setState(() => tab = i);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.medication_outlined),
            selectedIcon: Icon(Icons.medication),
            label: 'Medicine',
          ),
          NavigationDestination(
            icon: Icon(Icons.point_of_sale_outlined),
            selectedIcon: Icon(Icons.point_of_sale),
            label: 'Sale',
          ),
          NavigationDestination(
            icon: Icon(Icons.analytics_outlined),
            selectedIcon: Icon(Icons.analytics),
            label: 'Reports',
          ),
        ],
      ),
      floatingActionButton: tab == 1
          ? FloatingActionButton.extended(
              onPressed: () async {
                await medicineForm(context);

                if (mounted) {
                  setState(() {});
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Medicine'),
            )
          : null,
    );
  }
}

// ============================================================
// DASHBOARD
// ============================================================

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  Map<String, double> data = {};

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final result = await AppDb.instance.dashboard();

      if (!mounted) return;

      setState(() {
        data = result;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Dashboard error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final sales = data['sales'] ?? 0;
    final expense = data['expense'] ?? 0;
    final due = data['due'] ?? 0;
    final stock = data['stock'] ?? 0;

    return RefreshIndicator(
      onRefresh: load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'আজকের সারাংশ',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            'Pharmacy Management',
            style: TextStyle(
              color: Colors.grey.shade600,
            ),
          ),

          const SizedBox(height: 20),

          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.35,
            children: [
              dashboardCard(
                'আজকের বিক্রি',
                sales,
                Icons.point_of_sale,
              ),
              dashboardCard(
                'আজকের খরচ',
                expense,
                Icons.payments,
              ),
              dashboardCard(
                'মোট পাওনা',
                due,
                Icons.account_balance_wallet,
              ),
              dashboardCard(
                'স্টকের মূল্য',
                stock,
                Icons.inventory,
              ),
            ],
          ),

          const SizedBox(height: 20),

          Card(
            child: ListTile(
              leading: const Icon(Icons.refresh),
              title: const Text('ড্যাশবোর্ড Refresh'),
              subtitle: const Text(
                'নতুন বিক্রি বা খরচের পর Refresh করতে পারো',
              ),
              trailing: IconButton(
                onPressed: load,
                icon: const Icon(Icons.refresh),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget dashboardCard(
    String title,
    double value,
    IconData icon,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, size: 30),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
              ),
            ),
            Text(
              money(value),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// MEDICINE
// ============================================================

class MedicinePage extends StatefulWidget {
  const MedicinePage({super.key});

  @override
  State<MedicinePage> createState() => _MedicinePageState();
}

class _MedicinePageState extends State<MedicinePage> {
  final searchController = TextEditingController();

  List<Map<String, Object?>> medicines = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> load() async {
    try {
      final result = await AppDb.instance.medicines(
        q: searchController.text,
      );

      if (!mounted) return;

      setState(() {
        medicines = result;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Medicine loading error: $e')),
      );
    }
  }

  Future<void> addMedicine() async {
    final saved = await medicineForm(context);

    if (saved == true) {
      await load();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Medicine saved successfully'),
        ),
      );
    }
  }

  Future<void> editMedicine(
    Map<String, Object?> medicine,
  ) async {
    final saved = await medicineForm(
      context,
      existing: medicine,
    );

    if (saved == true) {
      await load();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Medicine updated successfully'),
        ),
      );
    }
  }

  Future<void> deleteMedicine(
    Map<String, Object?> medicine,
  ) async {
    final id = medicine['id'];

    if (id is! int) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Medicine?'),
          content: Text(
            'আপনি কি "${medicine['name']}" delete করতে চান?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    await AppDb.instance.deleteMedicine(id);

    await load();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Medicine deleted'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            12,
            12,
            12,
            4,
          ),
          child: TextField(
            controller: searchController,
            onChanged: (_) => load(),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              suffixIcon: searchController.text.isNotEmpty
                  ? IconButton(
                      onPressed: () {
                        searchController.clear();
                        load();
                      },
                      icon: const Icon(Icons.clear),
                    )
                  : null,
              hintText: 'Medicine / Generic / Barcode',
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
                  ? RefreshIndicator(
                      onRefresh: load,
                      child: ListView(
                        physics:
                            const AlwaysScrollableScrollPhysics(),
                        children: const [
                          SizedBox(height: 150),
                          Icon(
                            Icons.medication_outlined,
                            size: 70,
                          ),
                          SizedBox(height: 10),
                          Center(
                            child: Text(
                              'কোনো medicine পাওয়া যায়নি',
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: load,
                      child: ListView.builder(
                        physics:
                            const AlwaysScrollableScrollPhysics(),
                        itemCount: medicines.length,
                        itemBuilder: (context, index) {
                          final medicine = medicines[index];

                          final stock =
                              (medicine['stock'] as num?)
                                      ?.toDouble() ??
                                  0;

                          final sale =
                              (medicine['sale'] as num?)
                                      ?.toDouble() ??
                                  0;

                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                child: Text(
                                  stock.toInt().toString(),
                                ),
                              ),
                              title: Text(
                                '${medicine['name'] ?? ''}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                'Batch: ${medicine['batch'] ?? '-'}\n'
                                'Expiry: ${medicine['expiry'] ?? '-'}\n'
                                'Sale: ${money(sale)}',
                              ),
                              isThreeLine: true,
                              trailing: PopupMenuButton<String>(
                                onSelected: (value) async {
                                  if (value == 'edit') {
                                    await editMedicine(medicine);
                                  }

                                  if (value == 'delete') {
                                    await deleteMedicine(medicine);
                                  }
                                },
                                itemBuilder: (_) => const [
                                  PopupMenuItem(
                                    value: 'edit',
                                    child: Row(
                                      children: [
                                        Icon(Icons.edit),
                                        SizedBox(width: 8),
                                        Text('Edit'),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete),
                                        SizedBox(width: 8),
                                        Text('Delete'),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              onTap: () => editMedicine(medicine),
                            ),
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }
}

// ============================================================
// MEDICINE FORM
// ============================================================

Future<bool?> medicineForm(
  BuildContext context, {
  Map<String, Object?>? existing,
}) async {
  final name = TextEditingController(
    text: '${existing?['name'] ?? ''}',
  );

  final generic = TextEditingController(
    text: '${existing?['generic'] ?? ''}',
  );

  final company = TextEditingController(
    text: '${existing?['company'] ?? ''}',
  );

  final barcode = TextEditingController(
    text: '${existing?['barcode'] ?? ''}',
  );

  final batch = TextEditingController(
    text: '${existing?['batch'] ?? ''}',
  );

  final expiry = TextEditingController(
    text: '${existing?['expiry'] ?? ''}',
  );

  final purchase = TextEditingController(
    text: '${existing?['purchase'] ?? ''}',
  );

  final sale = TextEditingController(
    text: '${existing?['sale'] ?? ''}',
  );

  final stock = TextEditingController(
    text: '${existing?['stock'] ?? ''}',
  );

  final formKey = GlobalKey<FormState>();

  try {
    return await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            existing == null
                ? 'নতুন Medicine'
                : 'Medicine Edit',
          ),
          content: SizedBox(
            width: 500,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    formField(
                      name,
                      'Medicine Name',
                      required: true,
                    ),
                    formField(
                      generic,
                      'Generic',
                    ),
                    formField(
                      company,
                      'Company',
                    ),
                    formField(
                      barcode,
                      'Barcode',
                    ),
                    formField(
                      batch,
                      'Batch',
                    ),
                    formField(
                      expiry,
                      'Expiry YYYY-MM-DD',
                    ),
                    formField(
                      purchase,
                      'Purchase Price',
                      keyboard:
                          TextInputType.number,
                    ),
                    formField(
                      sale,
                      'Sale Price',
                      keyboard:
                          TextInputType.number,
                    ),
                    formField(
                      stock,
                      'Stock Quantity',
                      keyboard:
                          TextInputType.number,
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text('Cancel'),
            ),
            FilledButton.icon(
              icon: const Icon(Icons.save),
              label: const Text('Save'),
              onPressed: () async {
                if (!formKey.currentState!.validate()) {
                  return;
                }

                final purchasePrice =
                    double.tryParse(
                          purchase.text.trim(),
                        ) ??
                        0;

                final salePrice =
                    double.tryParse(
                          sale.text.trim(),
                        ) ??
                        0;

                final stockQty =
                    double.tryParse(
                          stock.text.trim(),
                        ) ??
                        0;

                if (purchasePrice < 0 ||
                    salePrice < 0 ||
                    stockQty < 0) {
                  ScaffoldMessenger.of(
                    dialogContext,
                  ).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Price/Stock negative হতে পারবে না',
                      ),
                    ),
                  );
                  return;
                }

                final medicine = <String, Object?>{
                  'name': name.text.trim(),
                  'generic': generic.text.trim(),
                  'company': company.text.trim(),
                  'barcode': barcode.text.trim(),
                  'batch': batch.text.trim(),
                  'expiry': expiry.text.trim(),
                  'purchase': purchasePrice,
                  'sale': salePrice,
                  'stock': stockQty,
                };

                try {
                  if (existing == null) {
                    await AppDb.instance.addMedicine(
                      medicine,
                    );
                  } else {
                    final id = existing['id'];

                    if (id is int) {
                      await AppDb.instance.updateMedicine(
                        id,
                        medicine,
                      );
                    }
                  }

                  if (dialogContext.mounted) {
                    Navigator.pop(
                      dialogContext,
                      true,
                    );
                  }
                } catch (e) {
                  if (!dialogContext.mounted) return;

                  ScaffoldMessenger.of(
                    dialogContext,
                  ).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Save failed: $e',
                      ),
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  } finally {
    name.dispose();
    generic.dispose();
    company.dispose();
    barcode.dispose();
    batch.dispose();
    expiry.dispose();
    purchase.dispose();
    sale.dispose();
    stock.dispose();
  }
}

Widget formField(
  TextEditingController controller,
  String label, {
  bool required = false,
  TextInputType? keyboard,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: TextFormField(
      controller: controller,
      keyboardType: keyboard,
      validator: required
          ? (value) {
              if (value == null ||
                  value.trim().isEmpty) {
                return '$label required';
              }
              return null;
            }
          : null,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    ),
  );
}

// ============================================================
// SALES
// ============================================================

class SalePage extends StatefulWidget {
  const SalePage({super.key});

  @override
  State<SalePage> createState() => _SalePageState();
}

class _SalePageState extends State<SalePage> {
  final searchController = TextEditingController();

  List<Map<String, Object?>> found = [];
  List<Map<String, Object?>> cart = [];

  bool searching = false;

  double get total {
    return cart.fold(
      0,
      (sum, item) {
        final qty =
            (item['qty'] as num?)?.toDouble() ?? 0;

        final sale =
            (item['sale'] as num?)?.toDouble() ?? 0;

        return sum + (qty * sale);
      },
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> find() async {
    final text = searchController.text.trim();

    if (text.isEmpty) {
      setState(() {
        found = [];
        searching = false;
      });
      return;
    }

    setState(() {
      searching = true;
    });

    try {
      final result =
          await AppDb.instance.medicines(q: text);

      if (!mounted) return;

      setState(() {
        found = result;
        searching = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        searching = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Search error: $e'),
        ),
      );
    }
  }

  void addToCart(
    Map<String, Object?> medicine,
  ) {
    final stock =
        (medicine['stock'] as num?)?.toDouble() ?? 0;

    if (stock <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('এই medicine-এর stock শেষ'),
        ),
      );
      return;
    }

    final id = medicine['id'];

    final existingIndex = cart.indexWhere(
      (item) => item['id'] == id,
    );

    if (existingIndex >= 0) {
      final current =
          (cart[existingIndex]['qty'] as num?)
                  ?.toDouble() ??
              0;

      if (current + 1 > stock) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Available stock-এর বেশি নেওয়া যাবে না'),
          ),
        );
        return;
      }

      setState(() {
        cart[existingIndex]['qty'] = current + 1;
      });
    } else {
      final item =
          Map<String, Object?>.from(medicine);

      item['qty'] = 1.0;

      setState(() {
        cart.add(item);
      });
    }

    searchController.clear();

    setState(() {
      found = [];
    });
  }

  void changeQty(
    int index,
    double newQty,
  ) {
    final item = cart[index];

    final stock =
        (item['stock'] as num?)?.toDouble() ?? 0;

    if (newQty <= 0) {
      setState(() {
        cart.removeAt(index);
      });
      return;
    }

    if (newQty > stock) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Available stock-এর বেশি quantity দেওয়া যাবে না',
          ),
        ),
      );
      return;
    }

    setState(() {
      cart[index]['qty'] = newQty;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: searchController,
                  onChanged: (_) => find(),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Medicine / Barcode',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => Scanner(
                        onCode: (value) {
                          Navigator.pop(context);

                          searchController.text =
                              value;

                          find();
                        },
                      ),
                    ),
                  );
                },
                icon: const Icon(
                  Icons.qr_code_scanner,
                ),
                tooltip: 'Barcode Scanner',
              ),
            ],
          ),
        ),

        if (searching)
          const LinearProgressIndicator(),

        if (found.isNotEmpty)
          SizedBox(
            height: 180,
            child: Card(
              margin: const EdgeInsets.symmetric(
                horizontal: 12,
              ),
              child: ListView.builder(
                itemCount: found.length > 10
                    ? 10
                    : found.length,
                itemBuilder: (_, index) {
                  final medicine = found[index];

                  final stock =
                      (medicine['stock'] as num?)
                              ?.toDouble() ??
                          0;

                  final sale =
                      (medicine['sale'] as num?)
                              ?.toDouble() ??
                          0;

                  return ListTile(
                    leading: const Icon(
                      Icons.medication,
                    ),
                    title: Text(
                      '${medicine['name'] ?? ''}',
                    ),
                    subtitle: Text(
                      'Stock: ${stock.toInt()} • '
                      '${money(sale)}',
                    ),
                    trailing: const Icon(
                      Icons.add_circle_outline,
                    ),
                    onTap: () {
                      addToCart(medicine);
                    },
                  );
                },
              ),
            ),
          ),

        Expanded(
          child: cart.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment:
                        MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.shopping_cart_outlined,
                        size: 70,
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Cart empty',
                        style: TextStyle(
                          fontSize: 18,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'উপরের search থেকে medicine যোগ করুন',
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: cart.length,
                  itemBuilder: (_, index) {
                    final item = cart[index];

                    final qty =
                        (item['qty'] as num?)
                                ?.toDouble() ??
                            0;

                    final price =
                        (item['sale'] as num?)
                                ?.toDouble() ??
                            0;

                    return Card(
                      margin:
                          const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      child: ListTile(
                        title: Text(
                          '${item['name'] ?? ''}',
                        ),
                        subtitle: Text(
                          '${money(price)} × ${qty.toInt()}',
                        ),
                        trailing: SizedBox(
                          width: 150,
                          child: Row(
                            mainAxisAlignment:
                                MainAxisAlignment.end,
                            children: [
                              IconButton(
                                onPressed: () {
                                  changeQty(
                                    index,
                                    qty - 1,
                                  );
                                },
                                icon: const Icon(
                                  Icons.remove_circle_outline,
                                ),
                              ),
                              Text(
                                qty.toInt().toString(),
                                style: const TextStyle(
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                onPressed: () {
                                  changeQty(
                                    index,
                                    qty + 1,
                                  );
                                },
                                icon: const Icon(
                                  Icons.add_circle_outline,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),

        SafeArea(
          child: Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const Text('Total'),
                        Text(
                          money(total),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: cart.isEmpty
                        ? null
                        : () => checkout(context),
                    icon: const Icon(
                      Icons.payment,
                    ),
                    label: const Text(
                      'Checkout',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> checkout(
    BuildContext context,
  ) async {
    final paidController =
        TextEditingController(
      text: total.toStringAsFixed(2),
    );

    final customerController =
        TextEditingController();

    final formKey =
        GlobalKey<FormState>();

    try {
      final saved = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Checkout'),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Total: ${money(total)}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 15),

                  formField(
                    paidController,
                    'Paid Amount',
                    keyboard:
                        TextInputType.number,
                  ),

                  formField(
                    customerController,
                    'Customer Name',
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(
                    dialogContext,
                    false,
                  );
                },
                child: const Text('Cancel'),
              ),
              FilledButton.icon(
                icon: const Icon(Icons.save),
                label: const Text('Save Sale'),
                onPressed: () async {
                  if (!formKey.currentState!
                      .validate()) {
                    return;
                  }

                  final paid =
                      double.tryParse(
                            paidController.text
                                .trim(),
                          ) ??
                          0;

                  if (paid < 0) {
                    ScaffoldMessenger.of(
                      dialogContext,
                    ).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Paid amount invalid',
                        ),
                      ),
                    );
                    return;
                  }

                  if (paid > total) {
                    ScaffoldMessenger.of(
                      dialogContext,
                    ).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Paid amount total-এর বেশি হতে পারবে না',
                        ),
                      ),
                    );
                    return;
                  }

                  try {
                    await AppDb.instance.saveSale(
                      cart,
                      paid,
                      'Cash',
                      customerController.text
                          .trim(),
                    );

                    if (dialogContext.mounted) {
                      Navigator.pop(
                        dialogContext,
                        true,
                      );
                    }
                  } catch (e) {
                    if (!dialogContext.mounted) {
                      return;
                    }

                    ScaffoldMessenger.of(
                      dialogContext,
                    ).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Sale failed: $e',
                        ),
                      ),
                    );
                  }
                },
              ),
            ],
          );
        },
      );

      if (saved == true) {
        setState(() {
          cart.clear();
          found.clear();
        });

        searchController.clear();

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Sale saved successfully',
            ),
          ),
        );
      }
    } finally {
      paidController.dispose();
      customerController.dispose();
    }
  }
}

// ============================================================
// BARCODE SCANNER
// ============================================================

class Scanner extends StatelessWidget {
  final void Function(String) onCode;

  const Scanner({
    super.key,
    required this.onCode,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Barcode Scanner'),
      ),
      body: MobileScanner(
        onDetect: (capture) {
          if (capture.barcodes.isEmpty) return;

          final code =
              capture.barcodes.first.rawValue;

          if (code != null &&
              code.trim().isNotEmpty) {
            onCode(code);
          }
        },
      ),
    );
  }
}

// ============================================================
// REPORT
// ============================================================

class ReportPage extends StatefulWidget {
  const ReportPage({super.key});

  @override
  State<ReportPage> createState() =>
      _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  Future<void>openExpense() async {
    final saved = await expenseForm(context);

    if (saved == true && mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Reports',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 15),

        Card(
          child: ListTile(
            leading: const CircleAvatar(
              child: Icon(Icons.receipt_long),
            ),
            title: const Text(
              'Daily Sales',
            ),
            subtitle: const Text(
              'Dashboard-এ আজকের বিক্রি দেখা যাবে',
            ),
          ),
        ),

        Card(
          child: ListTile(
            leading: const CircleAvatar(
              child: Icon(Icons.inventory),
            ),
            title: const Text(
              'Stock',
            ),
            subtitle: const Text(
              'Medicine section থেকে stock manage করুন',
            ),
          ),
        ),

        Card(
          child: ListTile(
            leading: const CircleAvatar(
              child: Icon(Icons.warning),
            ),
            title: const Text(
              'Expiry / Low Stock',
            ),
            subtitle: const Text(
              'Medicine-এর expiry এবং stock দেখুন',
            ),
          ),
        ),

        Card(
          child: ListTile(
            leading: const CircleAvatar(
              child: Icon(Icons.money_off),
            ),
            title: const Text(
              'Expense',
            ),
            subtitle: const Text(
              'Pharmacy expense database-এ save করুন',
            ),
            trailing: const Icon(
              Icons.arrow_forward_ios,
            ),
            onTap: openExpense,
          ),
        ),
      ],
    );
  }
}

// ============================================================
// EXPENSE
// ============================================================

Future<bool?> expenseForm(
  BuildContext context,
) async {
  final titleController =
      TextEditingController();

  final amountController =
      TextEditingController();

  final formKey =
      GlobalKey<FormState>();

  try {
    return await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'খরচ যোগ করুন',
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                formField(
                  titleController,
                  'Expense Description',
                  required: true,
                ),
                formField(
                  amountController,
                  'Amount',
                  required: true,
                  keyboard:
                      TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text('Cancel'),
            ),
            FilledButton.icon(
              icon: const Icon(Icons.save),
              label: const Text('Save'),
              onPressed: () async {
                if (!formKey.currentState!
                    .validate()) {
                  return;
                }

                final amount =
                    double.tryParse(
                          amountController.text
                              .trim(),
                        ) ??
                        0;

                if (amount <= 0) {
                  ScaffoldMessenger.of(
                    dialogContext,
                  ).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Amount অবশ্যই 0-এর বেশি হতে হবে',
                      ),
                    ),
                  );
                  return;
                }

                try {
                  await AppDb.instance.addExpense(
                    titleController.text.trim(),
                    amount,
                    'Cash',
                  );

                  if (dialogContext.mounted) {
                    Navigator.pop(
                      dialogContext,
                      true,
                    );
                  }
                } catch (e) {
                  if (!dialogContext.mounted) {
                    return;
                  }

                  ScaffoldMessenger.of(
                    dialogContext,
                  ).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Expense save failed: $e',
                      ),
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  } finally {
    titleController.dispose();
    amountController.dispose();
  }
}