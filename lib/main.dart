import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// PDF
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

/* ----------------------------- MODELOS ----------------------------- */

class Product {
  final String id;
  final String name;
  final int stockQty;
  final double purchasePrice; // PRECIO COMPRA
  final double salePrice; // PRECIO VENTA

  const Product({
    required this.id,
    required this.name,
    required this.stockQty,
    required this.purchasePrice,
    required this.salePrice,
  });

  Product copyWith({
    String? id,
    String? name,
    int? stockQty,
    double? purchasePrice,
    double? salePrice,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      stockQty: stockQty ?? this.stockQty,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      salePrice: salePrice ?? this.salePrice,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'stockQty': stockQty,
    'purchasePrice': purchasePrice,
    'salePrice': salePrice,
  };

  factory Product.fromJson(Map<String, dynamic> json) => Product(
    id: (json['id'] ?? '').toString(),
    name: (json['name'] ?? '').toString(),
    stockQty: (json['stockQty'] ?? 0) as int,
    purchasePrice: (json['purchasePrice'] ?? 0).toDouble(),
    salePrice: (json['salePrice'] ?? 0).toDouble(),
  );
}

class SaleDraftItem {
  final String id;
  final String productId;
  final String productName;
  final int qty;
  final double unitPrice;
  final String method; // EFECTIVO | TRANSFERENCIA
  final int createdAtMs;

  const SaleDraftItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.qty,
    required this.unitPrice,
    required this.method,
    required this.createdAtMs,
  });

  double get total => qty * unitPrice;

  Map<String, dynamic> toJson() => {
    'id': id,
    'productId': productId,
    'productName': productName,
    'qty': qty,
    'unitPrice': unitPrice,
    'method': method,
    'createdAtMs': createdAtMs,
  };

  factory SaleDraftItem.fromJson(Map<String, dynamic> json) => SaleDraftItem(
    id: (json['id'] ?? '').toString(),
    productId: (json['productId'] ?? '').toString(),
    productName: (json['productName'] ?? '').toString(),
    qty: (json['qty'] ?? 0) as int,
    unitPrice: (json['unitPrice'] ?? 0).toDouble(),
    method: (json['method'] ?? 'EFECTIVO').toString(),
    createdAtMs: (json['createdAtMs'] ?? 0) as int,
  );
}

/* ----------------------------- STORAGE ----------------------------- */

class StorageService {
  static const _productsKey = 'products_v1';
  static const _salesDraftKey = 'sales_draft_v1';
  static const _salesHistoryKey = 'sales_history_v1';

  static Future<List<Product>> loadProducts() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_productsKey);
    if (raw == null || raw.trim().isEmpty) return [];
    final list = (jsonDecode(raw) as List).cast<dynamic>();
    return list
        .map((e) => Product.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
  }

  static Future<void> saveProducts(List<Product> products) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(products.map((p) => p.toJson()).toList());
    await prefs.setString(_productsKey, raw);
  }

  static Future<List<SaleDraftItem>> loadSalesDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_salesDraftKey);
    if (raw == null || raw.trim().isEmpty) return [];
    final list = (jsonDecode(raw) as List).cast<dynamic>();
    return list
        .map((e) => SaleDraftItem.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
  }

  static Future<void> saveSalesDraft(List<SaleDraftItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(items.map((i) => i.toJson()).toList());
    await prefs.setString(_salesDraftKey, raw);
  }

  static Future<List<Map<String, dynamic>>> loadSalesHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_salesHistoryKey);
    if (raw == null || raw.trim().isEmpty) return [];
    final list = (jsonDecode(raw) as List).cast<dynamic>();
    return list.map((e) => (e as Map).cast<String, dynamic>()).toList();
  }

  static Future<void> appendSalesHistory(
    List<SaleDraftItem> publishedItems,
  ) async {
    final history = await loadSalesHistory();
    final now = DateTime.now();
    for (final it in publishedItems) {
      history.add({
        ...it.toJson(),
        'publishedAtMs': now.millisecondsSinceEpoch,
        'publishedDate': '${now.year}-${_two(now.month)}-${_two(now.day)}',
      });
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_salesHistoryKey, jsonEncode(history));
  }

  static String _two(int v) => v.toString().padLeft(2, '0');
}

/* ----------------------------- UI APP ----------------------------- */

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF1B5E20);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Minimarket Bodega Angel Manrique',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: seed),
        scaffoldBackgroundColor: const Color(0xFFF7F9FC),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          filled: true,
          fillColor: Colors.white.withOpacity(0.97),
        ),
      ),
      home: const MainMenuPage(),
    );
  }
}

/* ----------------------------- UI HELPERS ----------------------------- */

class FancyBackground extends StatelessWidget {
  final Widget child;
  const FancyBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cs.primary.withOpacity(0.10),
            cs.secondary.withOpacity(0.08),
            Colors.white,
          ],
        ),
      ),
      child: child,
    );
  }
}

class SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const SectionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: Colors.white.withOpacity(0.94),
        boxShadow: [
          BoxShadow(
            blurRadius: 20,
            offset: const Offset(0, 10),
            color: Colors.black.withOpacity(0.06),
          ),
        ],
        border: Border.all(color: cs.primary.withOpacity(0.10)),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: cs.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: cs.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Expanded(
            child: child,
          ), // ✅ CLAVE: el contenido de la tarjeta ocupa altura
        ],
      ),
    );
  }
}

class BigActionButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final VoidCallback onTap;
  final Color? background;

  const BigActionButton({
    super.key,
    required this.text,
    required this.icon,
    required this.onTap,
    this.background,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg = background ?? cs.primary;

    return SizedBox(
      width: 360,
      height: 64,
      child: FilledButton.icon(
        onPressed: onTap,
        icon: Icon(icon),
        label: Text(
          text,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
        ),
        style: FilledButton.styleFrom(
          backgroundColor: bg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
    );
  }
}

/* ----------------------------- MENU PRINCIPAL ----------------------------- */

class MainMenuPage extends StatelessWidget {
  const MainMenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: FancyBackground(
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 880),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        color: Colors.white.withOpacity(0.94),
                        boxShadow: [
                          BoxShadow(
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                            color: Colors.black.withOpacity(0.06),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              gradient: LinearGradient(
                                colors: [cs.primary, cs.secondary],
                              ),
                            ),
                            child: const Icon(
                              Icons.storefront,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Text(
                              'Minimarket Bodega Angel Manrique',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 26),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 14,
                      runSpacing: 14,
                      children: [
                        BigActionButton(
                          text: 'Compra de Productos',
                          icon: Icons.add_shopping_cart,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const PurchasePage(),
                            ),
                          ),
                        ),
                        BigActionButton(
                          text: 'Venta del Día',
                          icon: Icons.point_of_sale,
                          background: cs.secondary,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SalesDayPage(),
                            ),
                          ),
                        ),
                        BigActionButton(
                          text: 'Stock',
                          icon: Icons.inventory_2,
                          background: Colors.black87,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const StockPage(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/* ----------------------------- COMPRA DE PRODUCTOS ----------------------------- */

class PurchasePage extends StatefulWidget {
  const PurchasePage({super.key});

  @override
  State<PurchasePage> createState() => _PurchasePageState();
}

class _PurchasePageState extends State<PurchasePage> {
  List<Product> _products = [];
  Product? _selectedProduct;

  final _purchaseQtyCtrl = TextEditingController();

  final _newNameCtrl = TextEditingController();
  final _newQtyCtrl = TextEditingController();

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final products = await StorageService.loadProducts();
    setState(() {
      _products = products;
      _selectedProduct = _products.isNotEmpty ? _products.first : null;
      _loading = false;
    });
  }

  String _newId() => DateTime.now().microsecondsSinceEpoch.toString();

  Future<void> _saveProducts() async => StorageService.saveProducts(_products);

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _publishPurchase() async {
    if (_selectedProduct == null) {
      _toast('Selecciona un producto.');
      return;
    }

    final qty = int.tryParse(_purchaseQtyCtrl.text.trim()) ?? 0;
    if (qty <= 0) {
      _toast('Cantidad inválida.');
      return;
    }

    final idx = _products.indexWhere((p) => p.id == _selectedProduct!.id);
    if (idx < 0) return;

    final current = _products[idx];
    _products[idx] = current.copyWith(stockQty: current.stockQty + qty);
    await _saveProducts();

    setState(() {
      _purchaseQtyCtrl.clear();
      _selectedProduct = _products[idx];
    });

    _toast('Compra publicada ✅ (+$qty al stock)');
  }

  Future<void> _registerNewProduct() async {
    final name = _newNameCtrl.text.trim();
    final qty = int.tryParse(_newQtyCtrl.text.trim()) ?? 0;

    if (name.isEmpty) {
      _toast('Escribe el nombre del producto.');
      return;
    }
    if (qty < 0) {
      _toast('Cantidad inválida.');
      return;
    }

    final exists = _products.any(
      (p) => p.name.toLowerCase() == name.toLowerCase(),
    );
    if (exists) {
      _toast('Ese producto ya existe.');
      return;
    }

    final product = Product(
      id: _newId(),
      name: name,
      stockQty: qty,
      purchasePrice: 0.0,
      salePrice: 0.0,
    );

    setState(() {
      _products.add(product);
      _selectedProduct = product;
      _newNameCtrl.clear();
      _newQtyCtrl.clear();
    });

    await _saveProducts();
    _toast('Producto registrado ✅');
  }

  @override
  void dispose() {
    _purchaseQtyCtrl.dispose();
    _newNameCtrl.dispose();
    _newQtyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bottomPad = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text('Compra de Productos'),
        backgroundColor: Colors.transparent,
      ),
      body: FancyBackground(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(18),
                child: LayoutBuilder(
                  builder: (_, constraints) {
                    final isWide = constraints.maxWidth >= 900;

                    final left = SectionCard(
                      title: 'Compra de Producto',
                      icon: Icons.add_shopping_cart,
                      child: SingleChildScrollView(
                        padding: EdgeInsets.only(bottom: bottomPad),
                        child: Column(
                          children: [
                            DropdownButtonFormField<Product>(
                              value: _selectedProduct,
                              items: _products
                                  .map(
                                    (p) => DropdownMenuItem<Product>(
                                      value: p,
                                      child: Text(p.name),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (p) =>
                                  setState(() => _selectedProduct = p),
                              decoration: const InputDecoration(
                                labelText: 'Nombre Producto',
                                prefixIcon: Icon(Icons.list_alt),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _purchaseQtyCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Cantidad',
                                prefixIcon: Icon(Icons.numbers),
                              ),
                            ),
                            const SizedBox(height: 14),
                            SizedBox(
                              width: double.infinity,
                              height: 54,
                              child: FilledButton(
                                onPressed: _publishPurchase,
                                style: FilledButton.styleFrom(
                                  backgroundColor: cs.primary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: const Text(
                                  'PUBLICAR',
                                  style: TextStyle(fontWeight: FontWeight.w900),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );

                    final right = SectionCard(
                      title: 'Registrar Nuevo Producto',
                      icon: Icons.playlist_add,
                      child: SingleChildScrollView(
                        padding: EdgeInsets.only(bottom: bottomPad),
                        child: Column(
                          children: [
                            TextField(
                              controller: _newNameCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Nombre Producto Nuevo',
                                prefixIcon: Icon(Icons.shopping_bag),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _newQtyCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Cantidad',
                                prefixIcon: Icon(Icons.inventory),
                              ),
                            ),
                            const SizedBox(height: 14),
                            SizedBox(
                              width: double.infinity,
                              height: 54,
                              child: FilledButton.tonal(
                                onPressed: _registerNewProduct,
                                style: FilledButton.styleFrom(
                                  backgroundColor: cs.secondary.withOpacity(
                                    0.20,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: Text(
                                  'PUBLICAR',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    color: cs.secondary,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );

                    if (!isWide) {
                      return Column(
                        children: [
                          Expanded(child: SizedBox.expand(child: left)),
                          const SizedBox(height: 14),
                          Expanded(child: SizedBox.expand(child: right)),
                        ],
                      );
                    }

                    return Row(
                      children: [
                        Expanded(child: SizedBox.expand(child: left)),
                        Container(
                          width: 22,
                          alignment: Alignment.center,
                          child: Container(
                            width: 1,
                            height: double.infinity,
                            color: cs.primary.withOpacity(0.18),
                          ),
                        ),
                        Expanded(child: SizedBox.expand(child: right)),
                      ],
                    );
                  },
                ),
              ),
      ),
    );
  }
}

/* ----------------------------- STOCK (igual que lo tenías) ----------------------------- */

class StockPage extends StatefulWidget {
  const StockPage({super.key});

  @override
  State<StockPage> createState() => _StockPageState();
}

class _StockPageState extends State<StockPage> {
  List<Product> _products = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final products = await StorageService.loadProducts();
    setState(() {
      _products = products;
      _loading = false;
    });
  }

  String _money(double v) => v.toStringAsFixed(2);

  double _totalPV() =>
      _products.fold(0.0, (a, p) => a + (p.stockQty * p.salePrice));
  double _totalPC() =>
      _products.fold(0.0, (a, p) => a + (p.stockQty * p.purchasePrice));

  Future<void> _updateSalePrice(Product p, double newPrice) async {
    final idx = _products.indexWhere((x) => x.id == p.id);
    if (idx < 0) return;
    setState(
      () => _products[idx] = _products[idx].copyWith(salePrice: newPrice),
    );
    await StorageService.saveProducts(_products);
  }

  Future<void> _updatePurchasePrice(Product p, double newPrice) async {
    final idx = _products.indexWhere((x) => x.id == p.id);
    if (idx < 0) return;
    setState(
      () => _products[idx] = _products[idx].copyWith(purchasePrice: newPrice),
    );
    await StorageService.saveProducts(_products);
  }

  Future<void> _deleteProduct(Product p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Borrar producto'),
        content: Text('¿Seguro que deseas borrar "${p.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Borrar'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    setState(() => _products.removeWhere((x) => x.id == p.id));
    await StorageService.saveProducts(_products);

    final draft = await StorageService.loadSalesDraft();
    final filteredDraft = draft.where((d) => d.productId != p.id).toList();
    await StorageService.saveSalesDraft(filteredDraft);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Producto "${p.name}" borrado ✅'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock'),
        backgroundColor: Colors.transparent,
      ),
      body: FancyBackground(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    Expanded(
                      child: SectionCard(
                        title: 'Inventario',
                        icon: Icons.inventory_2,
                        child: LayoutBuilder(
                          builder: (_, c) {
                            final isNarrow = c.maxWidth < 920;

                            final nameW = isNarrow
                                ? 320.0
                                : (c.maxWidth * 0.36).clamp(380.0, 640.0);
                            final stockW = isNarrow
                                ? 140.0
                                : (c.maxWidth * 0.12).clamp(160.0, 240.0);
                            final pcW = isNarrow
                                ? 190.0
                                : (c.maxWidth * 0.16).clamp(220.0, 320.0);
                            final pvW = isNarrow
                                ? 190.0
                                : (c.maxWidth * 0.16).clamp(220.0, 320.0);
                            final totalW = isNarrow
                                ? 200.0
                                : (c.maxWidth * 0.16).clamp(220.0, 320.0);
                            final actW = isNarrow ? 120.0 : 140.0;

                            final table = DataTable(
                              columnSpacing: 22,
                              headingTextStyle: const TextStyle(
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.9,
                              ),
                              columns: [
                                DataColumn(
                                  label: SizedBox(
                                    width: nameW,
                                    child: const Text('NOMBRE DE PRODUCTO'),
                                  ),
                                ),
                                DataColumn(
                                  label: SizedBox(
                                    width: stockW,
                                    child: const Text('STOCK'),
                                  ),
                                ),
                                DataColumn(
                                  label: SizedBox(
                                    width: pcW,
                                    child: const Text('PRECIO COMPRA'),
                                  ),
                                ),
                                DataColumn(
                                  label: SizedBox(
                                    width: pvW,
                                    child: const Text('PRECIO VENTA'),
                                  ),
                                ),
                                DataColumn(
                                  label: SizedBox(
                                    width: totalW,
                                    child: const Text('TOTAL (PV)'),
                                  ),
                                ),
                                DataColumn(
                                  label: SizedBox(
                                    width: actW,
                                    child: const Text('ACCIÓN'),
                                  ),
                                ),
                              ],
                              rows: _products.map((p) {
                                final totalPV = p.stockQty * p.salePrice;

                                final pcCtrl = TextEditingController(
                                  text: _money(p.purchasePrice),
                                );
                                final pvCtrl = TextEditingController(
                                  text: _money(p.salePrice),
                                );

                                return DataRow(
                                  cells: [
                                    DataCell(
                                      SizedBox(
                                        width: nameW,
                                        child: Text(p.name),
                                      ),
                                    ),
                                    DataCell(
                                      SizedBox(
                                        width: stockW,
                                        child: Text(p.stockQty.toString()),
                                      ),
                                    ),
                                    DataCell(
                                      SizedBox(
                                        width: pcW,
                                        child: TextField(
                                          controller: pcCtrl,
                                          keyboardType:
                                              const TextInputType.numberWithOptions(
                                                decimal: true,
                                              ),
                                          decoration: const InputDecoration(
                                            isDense: true,
                                            prefixText: 'S/ ',
                                          ),
                                          onSubmitted: (v) {
                                            final parsed =
                                                double.tryParse(
                                                  v.trim().replaceAll(',', '.'),
                                                ) ??
                                                p.purchasePrice;
                                            _updatePurchasePrice(p, parsed);
                                          },
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      SizedBox(
                                        width: pvW,
                                        child: TextField(
                                          controller: pvCtrl,
                                          keyboardType:
                                              const TextInputType.numberWithOptions(
                                                decimal: true,
                                              ),
                                          decoration: const InputDecoration(
                                            isDense: true,
                                            prefixText: 'S/ ',
                                          ),
                                          onSubmitted: (v) {
                                            final parsed =
                                                double.tryParse(
                                                  v.trim().replaceAll(',', '.'),
                                                ) ??
                                                p.salePrice;
                                            _updateSalePrice(p, parsed);
                                          },
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      SizedBox(
                                        width: totalW,
                                        child: Text('S/ ${_money(totalPV)}'),
                                      ),
                                    ),
                                    DataCell(
                                      SizedBox(
                                        width: actW,
                                        child: Align(
                                          alignment: Alignment.centerLeft,
                                          child: IconButton(
                                            tooltip: 'Borrar',
                                            onPressed: () => _deleteProduct(p),
                                            icon: const Icon(
                                              Icons.delete_outline,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            );

                            // ✅ 1) Scroll vertical SIEMPRE (para bajar en inventario)
                            // ✅ 2) Scroll horizontal SOLO cuando es angosto (tablet/cel)
                            final verticalScroll = SingleChildScrollView(
                              physics: const BouncingScrollPhysics(),
                              child: table,
                            );

                            if (isNarrow) {
                              return SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                physics: const BouncingScrollPhysics(),
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    minWidth: c.maxWidth,
                                  ),
                                  child: verticalScroll,
                                ),
                              );
                            }

                            return verticalScroll;
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _TotalBox(
                            title: 'TOTAL PV',
                            value: 'S/ ${_money(_totalPV())}',
                            icon: Icons.trending_up,
                            accent: const Color(0xFF1B5E20),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _TotalBox(
                            title: 'TOTAL PC',
                            value: 'S/ ${_money(_totalPC())}',
                            icon: Icons.shopping_basket,
                            accent: const Color(0xFF0D47A1),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _TotalBox extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color accent;

  const _TotalBox({
    required this.title,
    required this.value,
    required this.icon,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: Colors.white.withOpacity(0.95),
        boxShadow: [
          BoxShadow(
            blurRadius: 20,
            offset: const Offset(0, 10),
            color: Colors.black.withOpacity(0.06),
          ),
        ],
        border: Border.all(color: accent.withOpacity(0.20)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: accent.withOpacity(0.12),
            ),
            child: Icon(icon, color: accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                letterSpacing: 0.9,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
          ),
        ],
      ),
    );
  }
}

/* ----------------------------- VENTAS DEL DÍA (ARREGLADO) ----------------------------- */

enum SalesFilter { all, cash, transfer }

class SalesDayPage extends StatefulWidget {
  const SalesDayPage({super.key});

  @override
  State<SalesDayPage> createState() => _SalesDayPageState();
}

class _SalesDayPageState extends State<SalesDayPage> {
  List<Product> _products = [];
  List<SaleDraftItem> _draft = [];
  bool _loading = true;

  Product? _selectedProduct;

  final _qtyCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();

  SalesFilter _filter = SalesFilter.all;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final products = await StorageService.loadProducts();
    final draft = await StorageService.loadSalesDraft();
    setState(() {
      _products = products;
      _draft = draft;
      _selectedProduct = _products.isNotEmpty ? _products.first : null;
      if (_selectedProduct != null && _selectedProduct!.salePrice > 0) {
        _priceCtrl.text = _money(_selectedProduct!.salePrice);
      }
      _loading = false;
    });
  }

  String _newId() => DateTime.now().microsecondsSinceEpoch.toString();

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  List<SaleDraftItem> _filteredDraft() {
    if (_filter == SalesFilter.cash)
      return _draft.where((e) => e.method == 'EFECTIVO').toList();
    if (_filter == SalesFilter.transfer)
      return _draft.where((e) => e.method == 'TRANSFERENCIA').toList();
    return _draft;
  }

  double _sumFiltered() => _filteredDraft().fold(0.0, (a, b) => a + b.total);
  String _money(double v) => v.toStringAsFixed(2);

  Future<void> _saveDraft() async => StorageService.saveSalesDraft(_draft);

  void _onSelectedProduct(Product p) {
    setState(() {
      _selectedProduct = p;
      if (p.salePrice > 0) _priceCtrl.text = _money(p.salePrice);
    });
  }

  Future<void> _addSale(String method) async {
    final p = _selectedProduct;
    if (p == null) return _toast('Selecciona un producto.');

    final qty = int.tryParse(_qtyCtrl.text.trim()) ?? 0;
    final price =
        double.tryParse(_priceCtrl.text.trim().replaceAll(',', '.')) ?? 0;

    if (qty <= 0) return _toast('Cantidad inválida.');
    if (price <= 0) return _toast('Precio inválido.');

    final item = SaleDraftItem(
      id: _newId(),
      productId: p.id,
      productName: p.name,
      qty: qty,
      unitPrice: price,
      method: method,
      createdAtMs: DateTime.now().millisecondsSinceEpoch,
    );

    setState(() {
      _draft.insert(0, item);
      _qtyCtrl.clear();
    });
    await _saveDraft();
  }

  Future<void> _removeDraftItem(String id) async {
    setState(() => _draft.removeWhere((e) => e.id == id));
    await _saveDraft();
  }

  bool _publishing = false;

  Future<void> _publishSales() async {
    if (_publishing) return;

    if (_draft.isEmpty) {
      _toast('No hay ventas para publicar.');
      return;
    }

    if (!mounted) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirmar publicación'),
        content: const Text('¿Deseas seguir con la publicación de la venta?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sí'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      setState(() => _publishing = true);

      final productsMap = {for (final p in _products) p.id: p};
      final qtyByProduct = <String, int>{};

      for (final it in _draft) {
        qtyByProduct[it.productId] = (qtyByProduct[it.productId] ?? 0) + it.qty;
      }

      for (final entry in qtyByProduct.entries) {
        final p = productsMap[entry.key];
        if (p == null) {
          _toast('Producto no encontrado.');
          return;
        }
        if (entry.value > p.stockQty) {
          _toast(
            'Stock insuficiente para "${p.name}" (stock: ${p.stockQty}, pedido: ${entry.value})',
          );
          return;
        }
      }

      final updated = _products.map((p) {
        final sold = qtyByProduct[p.id] ?? 0;
        return sold == 0 ? p : p.copyWith(stockQty: p.stockQty - sold);
      }).toList();

      await StorageService.saveProducts(updated);
      await StorageService.appendSalesHistory(_draft);

      if (!mounted) return;

      setState(() {
        _products = updated;
        _draft = [];
        _filter = SalesFilter.all;
      });

      await _saveDraft();
      _toast('Ventas publicadas ✅ (Stock actualizado)');
    } catch (e) {
      _toast('Ocurrió un error al publicar: $e');
    } finally {
      if (mounted) setState(() => _publishing = false);
    }
  }

  Future<void> _printPdfTotals() async {
    if (_draft.isEmpty) return _toast('No hay ventas para el PDF.');

    final totalsByProduct = <String, double>{};
    for (final it in _draft) {
      totalsByProduct[it.productName] =
          (totalsByProduct[it.productName] ?? 0) + it.total;
    }

    final now = DateTime.now();
    final dateStr =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';

    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (_) => [
          pw.Container(
            padding: const pw.EdgeInsets.all(14),
            decoration: pw.BoxDecoration(
              borderRadius: pw.BorderRadius.circular(14),
              color: PdfColor.fromInt(0xFFE8F5E9),
              border: pw.Border.all(
                color: PdfColor.fromInt(0xFF1B5E20),
                width: 1,
              ),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'REPORTE - VENTAS DEL DÍA',
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Minimarket Bodega Angel Manrique',
                      style: const pw.TextStyle(fontSize: 11),
                    ),
                  ],
                ),
                pw.Text(
                  dateStr,
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 14),
          pw.Text(
            'Totales por producto (S/):',
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.Table(
            border: pw.TableBorder.all(
              color: PdfColor.fromInt(0xFFBDBDBD),
              width: 0.5,
            ),
            columnWidths: {
              0: const pw.FlexColumnWidth(3),
              1: const pw.FlexColumnWidth(1),
            },
            children: [
              pw.TableRow(
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromInt(0xFF1B5E20),
                ),
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(
                      'PRODUCTO',
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(
                      'TOTAL',
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              ...totalsByProduct.entries.map(
                (e) => pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(e.key),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('S/ ${e.value.toStringAsFixed(2)}'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 14),
          pw.Container(
            padding: const pw.EdgeInsets.all(14),
            decoration: pw.BoxDecoration(
              borderRadius: pw.BorderRadius.circular(14),
              color: PdfColor.fromInt(0xFFFFF8E1),
              border: pw.Border.all(
                color: PdfColor.fromInt(0xFFF9A825),
                width: 1,
              ),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'TOTAL GENERAL:',
                  style: pw.TextStyle(
                    fontSize: 13,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  'S/ ${_draft.fold(0.0, (a, b) => a + b.total).toStringAsFixed(2)}',
                  style: pw.TextStyle(
                    fontSize: 13,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (_) async => doc.save());
  }

  Color _methodColor(String method) =>
      method == 'EFECTIVO' ? const Color(0xFF1B5E20) : const Color(0xFF6A1B9A);

  String _filterLabel() {
    switch (_filter) {
      case SalesFilter.cash:
        return 'EFECTIVO';
      case SalesFilter.transfer:
        return 'TRANSFERENCIA';
      case SalesFilter.all:
      default:
        return 'TODO';
    }
  }

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final filtered = _filteredDraft();
    final bottomPad = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text('Venta del Día'),
        backgroundColor: Colors.transparent,
      ),
      body: FancyBackground(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(18),
                child: LayoutBuilder(
                  builder: (_, constraints) {
                    final isWide = constraints.maxWidth >= 900;

                    // ✅ Estructura con altura acotada: así el ListView y TextFields funcionan perfecto
                    return Column(
                      children: [
                        Expanded(
                          child: isWide
                              ? Row(
                                  children: [
                                    Expanded(
                                      child: SizedBox.expand(
                                        child: SectionCard(
                                          title: 'Registrar Venta',
                                          icon: Icons.point_of_sale,
                                          child: SingleChildScrollView(
                                            keyboardDismissBehavior:
                                                ScrollViewKeyboardDismissBehavior
                                                    .onDrag,
                                            padding: EdgeInsets.only(
                                              bottom: bottomPad,
                                            ),
                                            child: Column(
                                              children: [
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: FilledButton.tonalIcon(
                                                        onPressed:
                                                            _printPdfTotals,
                                                        icon: const Icon(
                                                          Icons.picture_as_pdf,
                                                        ),
                                                        label: const Text(
                                                          'PDF',
                                                        ),
                                                        style: FilledButton.styleFrom(
                                                          shape: RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  16,
                                                                ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 10),
                                                    Expanded(
                                                      child: FilledButton.icon(
                                                        onPressed:
                                                            _publishSales,
                                                        icon: const Icon(
                                                          Icons.publish,
                                                        ),
                                                        label: const Text(
                                                          'PUBLICAR VENTA',
                                                        ),
                                                        style: FilledButton.styleFrom(
                                                          backgroundColor:
                                                              Colors.black87,
                                                          foregroundColor:
                                                              Colors.white,
                                                          shape: RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  16,
                                                                ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 14),

                                                DropdownButtonFormField<
                                                  Product
                                                >(
                                                  value: _selectedProduct,
                                                  items: _products
                                                      .map(
                                                        (p) =>
                                                            DropdownMenuItem<
                                                              Product
                                                            >(
                                                              value: p,
                                                              child: Text(
                                                                p.name,
                                                              ),
                                                            ),
                                                      )
                                                      .toList(),
                                                  onChanged: (p) {
                                                    if (p == null) return;
                                                    _onSelectedProduct(p);
                                                  },
                                                  decoration:
                                                      const InputDecoration(
                                                        labelText: 'Nombre',
                                                        prefixIcon: Icon(
                                                          Icons.list_alt,
                                                        ),
                                                      ),
                                                ),

                                                const SizedBox(height: 12),
                                                TextField(
                                                  controller: _qtyCtrl,
                                                  keyboardType:
                                                      TextInputType.number,
                                                  decoration:
                                                      const InputDecoration(
                                                        labelText: 'Cantidad',
                                                        prefixIcon: Icon(
                                                          Icons.numbers,
                                                        ),
                                                      ),
                                                ),
                                                const SizedBox(height: 12),
                                                TextField(
                                                  controller: _priceCtrl,
                                                  keyboardType:
                                                      const TextInputType.numberWithOptions(
                                                        decimal: true,
                                                      ),
                                                  decoration:
                                                      const InputDecoration(
                                                        labelText: 'Precio',
                                                        prefixIcon: Icon(
                                                          Icons.attach_money,
                                                        ),
                                                        prefixText: 'S/ ',
                                                      ),
                                                ),
                                                const SizedBox(height: 14),
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: SizedBox(
                                                        height: 54,
                                                        child: FilledButton.icon(
                                                          onPressed: () =>
                                                              _addSale(
                                                                'EFECTIVO',
                                                              ),
                                                          icon: const Icon(
                                                            Icons.payments,
                                                          ),
                                                          label: const Text(
                                                            'EFECTIVO',
                                                          ),
                                                          style: FilledButton.styleFrom(
                                                            backgroundColor:
                                                                const Color(
                                                                  0xFF1B5E20,
                                                                ),
                                                            foregroundColor:
                                                                Colors.white,
                                                            shape: RoundedRectangleBorder(
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    16,
                                                                  ),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 10),
                                                    Expanded(
                                                      child: SizedBox(
                                                        height: 54,
                                                        child: FilledButton.icon(
                                                          onPressed: () =>
                                                              _addSale(
                                                                'TRANSFERENCIA',
                                                              ),
                                                          icon: const Icon(
                                                            Icons
                                                                .account_balance,
                                                          ),
                                                          label: const Text(
                                                            'TRANSFERENCIA',
                                                          ),
                                                          style: FilledButton.styleFrom(
                                                            backgroundColor:
                                                                const Color(
                                                                  0xFF6A1B9A,
                                                                ),
                                                            foregroundColor:
                                                                Colors.white,
                                                            shape: RoundedRectangleBorder(
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    16,
                                                                  ),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Container(
                                      width: 22,
                                      alignment: Alignment.center,
                                      child: Container(
                                        width: 1,
                                        height: double.infinity,
                                        color: cs.primary.withOpacity(0.18),
                                      ),
                                    ),
                                    Expanded(
                                      child: SizedBox.expand(
                                        child: SectionCard(
                                          title: 'Lista de Ventas',
                                          icon: Icons.receipt_long,
                                          child: Column(
                                            children: [
                                              // Filtro arriba
                                              Wrap(
                                                spacing: 10,
                                                runSpacing: 8,
                                                children: [
                                                  ChoiceChip(
                                                    label: const Text('TODO'),
                                                    selected:
                                                        _filter ==
                                                        SalesFilter.all,
                                                    onSelected: (_) => setState(
                                                      () => _filter =
                                                          SalesFilter.all,
                                                    ),
                                                  ),
                                                  ChoiceChip(
                                                    label: const Text(
                                                      'EFECTIVO',
                                                    ),
                                                    selected:
                                                        _filter ==
                                                        SalesFilter.cash,
                                                    selectedColor: const Color(
                                                      0xFF1B5E20,
                                                    ).withOpacity(0.18),
                                                    onSelected: (_) => setState(
                                                      () => _filter =
                                                          SalesFilter.cash,
                                                    ),
                                                  ),
                                                  ChoiceChip(
                                                    label: const Text(
                                                      'TRANSFERENCIA',
                                                    ),
                                                    selected:
                                                        _filter ==
                                                        SalesFilter.transfer,
                                                    selectedColor: const Color(
                                                      0xFF6A1B9A,
                                                    ).withOpacity(0.18),
                                                    onSelected: (_) => setState(
                                                      () => _filter =
                                                          SalesFilter.transfer,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 12),

                                              Expanded(
                                                child: filtered.isEmpty
                                                    ? const Center(
                                                        child: Text(
                                                          'No hay ventas en este filtro.',
                                                        ),
                                                      )
                                                    : ListView.separated(
                                                        keyboardDismissBehavior:
                                                            ScrollViewKeyboardDismissBehavior
                                                                .onDrag,
                                                        itemCount:
                                                            filtered.length,
                                                        separatorBuilder:
                                                            (_, __) =>
                                                                const SizedBox(
                                                                  height: 10,
                                                                ),
                                                        itemBuilder: (_, i) {
                                                          final it =
                                                              filtered[i];
                                                          final color =
                                                              _methodColor(
                                                                it.method,
                                                              );

                                                          return Container(
                                                            decoration: BoxDecoration(
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    18,
                                                                  ),
                                                              color: Colors
                                                                  .white
                                                                  .withOpacity(
                                                                    0.95,
                                                                  ),
                                                              boxShadow: [
                                                                BoxShadow(
                                                                  blurRadius:
                                                                      14,
                                                                  offset:
                                                                      const Offset(
                                                                        0,
                                                                        6,
                                                                      ),
                                                                  color: Colors
                                                                      .black
                                                                      .withOpacity(
                                                                        0.06,
                                                                      ),
                                                                ),
                                                              ],
                                                            ),
                                                            child: Row(
                                                              children: [
                                                                Container(
                                                                  width: 10,
                                                                  height: 88,
                                                                  decoration: BoxDecoration(
                                                                    color:
                                                                        color,
                                                                    borderRadius:
                                                                        const BorderRadius.horizontal(
                                                                          left: Radius.circular(
                                                                            18,
                                                                          ),
                                                                        ),
                                                                  ),
                                                                ),
                                                                Expanded(
                                                                  child: Padding(
                                                                    padding:
                                                                        const EdgeInsets.all(
                                                                          12,
                                                                        ),
                                                                    child: Column(
                                                                      crossAxisAlignment:
                                                                          CrossAxisAlignment
                                                                              .start,
                                                                      children: [
                                                                        Row(
                                                                          children: [
                                                                            Expanded(
                                                                              child: Text(
                                                                                it.productName,
                                                                                style: const TextStyle(
                                                                                  fontWeight: FontWeight.w900,
                                                                                ),
                                                                              ),
                                                                            ),
                                                                            IconButton(
                                                                              onPressed: () => _removeDraftItem(
                                                                                it.id,
                                                                              ),
                                                                              icon: const Icon(
                                                                                Icons.delete_outline,
                                                                              ),
                                                                            ),
                                                                          ],
                                                                        ),
                                                                        const SizedBox(
                                                                          height:
                                                                              6,
                                                                        ),
                                                                        Wrap(
                                                                          spacing:
                                                                              10,
                                                                          runSpacing:
                                                                              6,
                                                                          children: [
                                                                            Chip(
                                                                              label: Text(
                                                                                it.method,
                                                                              ),
                                                                              backgroundColor: color.withOpacity(
                                                                                0.12,
                                                                              ),
                                                                              labelStyle: TextStyle(
                                                                                fontWeight: FontWeight.w900,
                                                                                color: color,
                                                                              ),
                                                                            ),
                                                                            Chip(
                                                                              label: Text(
                                                                                'Cant: ${it.qty}',
                                                                              ),
                                                                            ),
                                                                            Chip(
                                                                              label: Text(
                                                                                'Total: S/ ${_money(it.total)}',
                                                                              ),
                                                                            ),
                                                                          ],
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          );
                                                        },
                                                      ),
                                              ),

                                              const SizedBox(height: 12),

                                              // TOTAL fijo abajo (por filtro)
                                              Container(
                                                width: double.infinity,
                                                padding: const EdgeInsets.all(
                                                  14,
                                                ),
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(18),
                                                  gradient: LinearGradient(
                                                    colors: [
                                                      cs.primary.withOpacity(
                                                        0.10,
                                                      ),
                                                      cs.secondary.withOpacity(
                                                        0.10,
                                                      ),
                                                      Colors.white.withOpacity(
                                                        0.92,
                                                      ),
                                                    ],
                                                  ),
                                                  border: Border.all(
                                                    color: cs.primary
                                                        .withOpacity(0.10),
                                                  ),
                                                ),
                                                child: Row(
                                                  children: [
                                                    const Icon(Icons.calculate),
                                                    const SizedBox(width: 10),
                                                    Expanded(
                                                      child: Text(
                                                        'TOTAL (${_filterLabel()})',
                                                        style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.w900,
                                                          letterSpacing: 0.8,
                                                        ),
                                                      ),
                                                    ),
                                                    Text(
                                                      'S/ ${_money(_sumFiltered())}',
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.w900,
                                                        fontSize: 16,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : Column(
                                  children: [
                                    Expanded(
                                      child: SizedBox.expand(
                                        child: SectionCard(
                                          title: 'Registrar Venta',
                                          icon: Icons.point_of_sale,
                                          child: SingleChildScrollView(
                                            keyboardDismissBehavior:
                                                ScrollViewKeyboardDismissBehavior
                                                    .onDrag,
                                            padding: EdgeInsets.only(
                                              bottom: bottomPad,
                                            ),
                                            child: Column(
                                              children: [
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: FilledButton.tonalIcon(
                                                        onPressed:
                                                            _printPdfTotals,
                                                        icon: const Icon(
                                                          Icons.picture_as_pdf,
                                                        ),
                                                        label: const Text(
                                                          'PDF',
                                                        ),
                                                        style: FilledButton.styleFrom(
                                                          shape: RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  16,
                                                                ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 10),
                                                    Expanded(
                                                      child: FilledButton.icon(
                                                        onPressed:
                                                            _publishSales,
                                                        icon: const Icon(
                                                          Icons.publish,
                                                        ),
                                                        label: const Text(
                                                          'PUBLICAR VENTA',
                                                        ),
                                                        style: FilledButton.styleFrom(
                                                          backgroundColor:
                                                              Colors.black87,
                                                          foregroundColor:
                                                              Colors.white,
                                                          shape: RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  16,
                                                                ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 14),
                                                DropdownButtonFormField<
                                                  Product
                                                >(
                                                  value: _selectedProduct,
                                                  items: _products
                                                      .map(
                                                        (p) =>
                                                            DropdownMenuItem<
                                                              Product
                                                            >(
                                                              value: p,
                                                              child: Text(
                                                                p.name,
                                                              ),
                                                            ),
                                                      )
                                                      .toList(),
                                                  onChanged: (p) {
                                                    if (p == null) return;
                                                    _onSelectedProduct(p);
                                                  },
                                                  decoration:
                                                      const InputDecoration(
                                                        labelText: 'Nombre',
                                                        prefixIcon: Icon(
                                                          Icons.list_alt,
                                                        ),
                                                      ),
                                                ),
                                                const SizedBox(height: 12),
                                                TextField(
                                                  controller: _qtyCtrl,
                                                  keyboardType:
                                                      TextInputType.number,
                                                  decoration:
                                                      const InputDecoration(
                                                        labelText: 'Cantidad',
                                                        prefixIcon: Icon(
                                                          Icons.numbers,
                                                        ),
                                                      ),
                                                ),
                                                const SizedBox(height: 12),
                                                TextField(
                                                  controller: _priceCtrl,
                                                  keyboardType:
                                                      const TextInputType.numberWithOptions(
                                                        decimal: true,
                                                      ),
                                                  decoration:
                                                      const InputDecoration(
                                                        labelText: 'Precio',
                                                        prefixIcon: Icon(
                                                          Icons.attach_money,
                                                        ),
                                                        prefixText: 'S/ ',
                                                      ),
                                                ),
                                                const SizedBox(height: 14),
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: SizedBox(
                                                        height: 54,
                                                        child: FilledButton.icon(
                                                          onPressed: () =>
                                                              _addSale(
                                                                'EFECTIVO',
                                                              ),
                                                          icon: const Icon(
                                                            Icons.payments,
                                                          ),
                                                          label: const Text(
                                                            'EFECTIVO',
                                                          ),
                                                          style: FilledButton.styleFrom(
                                                            backgroundColor:
                                                                const Color(
                                                                  0xFF1B5E20,
                                                                ),
                                                            foregroundColor:
                                                                Colors.white,
                                                            shape: RoundedRectangleBorder(
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    16,
                                                                  ),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 10),
                                                    Expanded(
                                                      child: SizedBox(
                                                        height: 54,
                                                        child: FilledButton.icon(
                                                          onPressed: () =>
                                                              _addSale(
                                                                'TRANSFERENCIA',
                                                              ),
                                                          icon: const Icon(
                                                            Icons
                                                                .account_balance,
                                                          ),
                                                          label: const Text(
                                                            'TRANSFERENCIA',
                                                          ),
                                                          style: FilledButton.styleFrom(
                                                            backgroundColor:
                                                                const Color(
                                                                  0xFF6A1B9A,
                                                                ),
                                                            foregroundColor:
                                                                Colors.white,
                                                            shape: RoundedRectangleBorder(
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    16,
                                                                  ),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    Expanded(
                                      child: SizedBox.expand(
                                        child: SectionCard(
                                          title: 'Lista de Ventas',
                                          icon: Icons.receipt_long,
                                          child: Column(
                                            children: [
                                              Wrap(
                                                spacing: 10,
                                                runSpacing: 8,
                                                children: [
                                                  ChoiceChip(
                                                    label: const Text('TODO'),
                                                    selected:
                                                        _filter ==
                                                        SalesFilter.all,
                                                    onSelected: (_) => setState(
                                                      () => _filter =
                                                          SalesFilter.all,
                                                    ),
                                                  ),
                                                  ChoiceChip(
                                                    label: const Text(
                                                      'EFECTIVO',
                                                    ),
                                                    selected:
                                                        _filter ==
                                                        SalesFilter.cash,
                                                    selectedColor: const Color(
                                                      0xFF1B5E20,
                                                    ).withOpacity(0.18),
                                                    onSelected: (_) => setState(
                                                      () => _filter =
                                                          SalesFilter.cash,
                                                    ),
                                                  ),
                                                  ChoiceChip(
                                                    label: const Text(
                                                      'TRANSFERENCIA',
                                                    ),
                                                    selected:
                                                        _filter ==
                                                        SalesFilter.transfer,
                                                    selectedColor: const Color(
                                                      0xFF6A1B9A,
                                                    ).withOpacity(0.18),
                                                    onSelected: (_) => setState(
                                                      () => _filter =
                                                          SalesFilter.transfer,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 12),
                                              Expanded(
                                                child: filtered.isEmpty
                                                    ? const Center(
                                                        child: Text(
                                                          'No hay ventas en este filtro.',
                                                        ),
                                                      )
                                                    : ListView.separated(
                                                        keyboardDismissBehavior:
                                                            ScrollViewKeyboardDismissBehavior
                                                                .onDrag,
                                                        itemCount:
                                                            filtered.length,
                                                        separatorBuilder:
                                                            (_, __) =>
                                                                const SizedBox(
                                                                  height: 10,
                                                                ),
                                                        itemBuilder: (_, i) {
                                                          final it =
                                                              filtered[i];
                                                          final color =
                                                              _methodColor(
                                                                it.method,
                                                              );

                                                          return Container(
                                                            decoration: BoxDecoration(
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    18,
                                                                  ),
                                                              color: Colors
                                                                  .white
                                                                  .withOpacity(
                                                                    0.95,
                                                                  ),
                                                              boxShadow: [
                                                                BoxShadow(
                                                                  blurRadius:
                                                                      14,
                                                                  offset:
                                                                      const Offset(
                                                                        0,
                                                                        6,
                                                                      ),
                                                                  color: Colors
                                                                      .black
                                                                      .withOpacity(
                                                                        0.06,
                                                                      ),
                                                                ),
                                                              ],
                                                            ),
                                                            child: Row(
                                                              children: [
                                                                Container(
                                                                  width: 10,
                                                                  height: 88,
                                                                  decoration: BoxDecoration(
                                                                    color:
                                                                        color,
                                                                    borderRadius:
                                                                        const BorderRadius.horizontal(
                                                                          left: Radius.circular(
                                                                            18,
                                                                          ),
                                                                        ),
                                                                  ),
                                                                ),
                                                                Expanded(
                                                                  child: Padding(
                                                                    padding:
                                                                        const EdgeInsets.all(
                                                                          12,
                                                                        ),
                                                                    child: Column(
                                                                      crossAxisAlignment:
                                                                          CrossAxisAlignment
                                                                              .start,
                                                                      children: [
                                                                        Row(
                                                                          children: [
                                                                            Expanded(
                                                                              child: Text(
                                                                                it.productName,
                                                                                style: const TextStyle(
                                                                                  fontWeight: FontWeight.w900,
                                                                                ),
                                                                              ),
                                                                            ),
                                                                            IconButton(
                                                                              onPressed: () => _removeDraftItem(
                                                                                it.id,
                                                                              ),
                                                                              icon: const Icon(
                                                                                Icons.delete_outline,
                                                                              ),
                                                                            ),
                                                                          ],
                                                                        ),
                                                                        const SizedBox(
                                                                          height:
                                                                              6,
                                                                        ),
                                                                        Wrap(
                                                                          spacing:
                                                                              10,
                                                                          runSpacing:
                                                                              6,
                                                                          children: [
                                                                            Chip(
                                                                              label: Text(
                                                                                it.method,
                                                                              ),
                                                                              backgroundColor: color.withOpacity(
                                                                                0.12,
                                                                              ),
                                                                              labelStyle: TextStyle(
                                                                                fontWeight: FontWeight.w900,
                                                                                color: color,
                                                                              ),
                                                                            ),
                                                                            Chip(
                                                                              label: Text(
                                                                                'Cant: ${it.qty}',
                                                                              ),
                                                                            ),
                                                                            Chip(
                                                                              label: Text(
                                                                                'Total: S/ ${_money(it.total)}',
                                                                              ),
                                                                            ),
                                                                          ],
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          );
                                                        },
                                                      ),
                                              ),
                                              const SizedBox(height: 12),
                                              Container(
                                                width: double.infinity,
                                                padding: const EdgeInsets.all(
                                                  14,
                                                ),
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(18),
                                                  gradient: LinearGradient(
                                                    colors: [
                                                      cs.primary.withOpacity(
                                                        0.10,
                                                      ),
                                                      cs.secondary.withOpacity(
                                                        0.10,
                                                      ),
                                                      Colors.white.withOpacity(
                                                        0.92,
                                                      ),
                                                    ],
                                                  ),
                                                  border: Border.all(
                                                    color: cs.primary
                                                        .withOpacity(0.10),
                                                  ),
                                                ),
                                                child: Row(
                                                  children: [
                                                    const Icon(Icons.calculate),
                                                    const SizedBox(width: 10),
                                                    Expanded(
                                                      child: Text(
                                                        'TOTAL (${_filterLabel()})',
                                                        style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.w900,
                                                          letterSpacing: 0.8,
                                                        ),
                                                      ),
                                                    ),
                                                    Text(
                                                      'S/ ${_money(_sumFiltered())}',
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.w900,
                                                        fontSize: 16,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ],
                    );
                  },
                ),
              ),
      ),
    );
  }
}
