import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../models/isar_models.dart';

class IsarService {
  static Isar? _isar;

  // ==================== INICIALIZACIÓN ====================

  static Future<void> init() async {
    if (_isar != null) return; // Ya está inicializado

    final dir = await getApplicationDocumentsDirectory();

    _isar = await Isar.open(
      [ProductSchema, SaleDraftItemSchema, SaleHistorySchema],
      directory: dir.path,
      name: 'bodega_db',
    );

    print('✅ Isar inicializado en: ${dir.path}');
  }

  static Isar get isar {
    if (_isar == null) {
      throw Exception(
        '❌ Isar no inicializado. Llama a IsarService.init() primero',
      );
    }
    return _isar!;
  }

  // ==================== PRODUCTOS ====================

  static Future<List<Product>> loadProducts() async {
    return await isar.products.where().findAll();
  }

  static Future<int> saveProduct(Product product) async {
    return await isar.writeTxn(() async {
      return await isar.products.put(product);
    });
  }

  static Future<void> updateProduct(Product product) async {
    await isar.writeTxn(() async {
      await isar.products.put(product);
    });
  }

  static Future<bool> deleteProduct(int id) async {
    return await isar.writeTxn(() async {
      return await isar.products.delete(id);
    });
  }

  static Future<Product?> getProductById(int id) async {
    return await isar.products.get(id);
  }

  // ==================== BORRADOR DE VENTAS ====================

  static Future<List<SaleDraftItem>> loadSalesDraft() async {
    return await isar.saleDraftItems.where().sortByCreatedAtDesc().findAll();
  }

  static Future<int> saveSaleDraft(SaleDraftItem item) async {
    return await isar.writeTxn(() async {
      return await isar.saleDraftItems.put(item);
    });
  }

  static Future<bool> deleteSaleDraft(int id) async {
    return await isar.writeTxn(() async {
      return await isar.saleDraftItems.delete(id);
    });
  }

  static Future<void> clearSalesDraft() async {
    await isar.writeTxn(() async {
      await isar.saleDraftItems.clear();
    });
  }

  // Eliminar borradores de un producto específico
  static Future<void> deleteDraftsByProductId(int productId) async {
    await isar.writeTxn(() async {
      final items = await isar.saleDraftItems
          .filter()
          .productIdEqualTo(productId)
          .findAll();

      for (final item in items) {
        await isar.saleDraftItems.delete(item.id);
      }
    });
  }

  // ==================== HISTORIAL DE VENTAS ====================

  static Future<void> publishSales(List<SaleDraftItem> items) async {
    final now = DateTime.now();
    final dateStr = '${now.year}-${_two(now.month)}-${_two(now.day)}';

    await isar.writeTxn(() async {
      for (final item in items) {
        final history = SaleHistory.create(
          productId: item.productId,
          productName: item.productName,
          qty: item.qty,
          unitPrice: item.unitPrice,
          method: item.method,
          publishedAt: now,
          publishedDate: dateStr,
        );
        await isar.saleHistorys.put(history);
      }
    });
  }

  static Future<List<SaleHistory>> loadSalesHistory() async {
    return await isar.saleHistorys.where().sortByPublishedAtDesc().findAll();
  }

  // Ventas de hoy
  static Future<List<SaleHistory>> getSalesToday() async {
    final now = DateTime.now();
    final dateStr = '${now.year}-${_two(now.month)}-${_two(now.day)}';

    return await isar.saleHistorys
        .filter()
        .publishedDateEqualTo(dateStr)
        .findAll();
  }

  // Ventas por rango de fechas
  static Future<List<SaleHistory>> getSalesByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    return await isar.saleHistorys
        .filter()
        .publishedAtBetween(start, end)
        .findAll();
  }

  // Ventas por método de pago
  static Future<List<SaleHistory>> getSalesByMethod(String method) async {
    return await isar.saleHistorys.filter().methodEqualTo(method).findAll();
  }

  // ==================== UTILIDADES ====================

  static String _two(int v) => v.toString().padLeft(2, '0');

  // Estadísticas rápidas
  static Future<Map<String, dynamic>> getStats() async {
    final products = await loadProducts();
    final salesToday = await getSalesToday();

    final totalProducts = products.length;
    final totalStock = products.fold(0, (sum, p) => sum + p.stockQty);
    final totalSalesToday = salesToday.length;
    final revenueTodayTotal = salesToday.fold(0.0, (sum, s) => sum + s.total);

    return {
      'totalProducts': totalProducts,
      'totalStock': totalStock,
      'totalSalesToday': totalSalesToday,
      'revenueToday': revenueTodayTotal,
    };
  }
}
