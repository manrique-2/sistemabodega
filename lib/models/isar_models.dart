import 'package:isar/isar.dart';

part 'isar_models.g.dart';

// ===================== PRODUCTO =====================
@collection
class Product {
  Id id = Isar.autoIncrement;

  @Index()
  late String name;

  late int stockQty;
  late double purchasePrice;
  late double salePrice;

  Product();

  Product.create({
    required this.name,
    required this.stockQty,
    required this.purchasePrice,
    required this.salePrice,
  });
}

// ===================== VENTA BORRADOR =====================
@collection
class SaleDraftItem {
  Id id = Isar.autoIncrement;

  late int productId;
  late String productName;
  late int qty;
  late double unitPrice;

  @Index()
  late String method;

  late DateTime createdAt;

  double get total => qty * unitPrice;

  SaleDraftItem();

  SaleDraftItem.create({
    required this.productId,
    required this.productName,
    required this.qty,
    required this.unitPrice,
    required this.method,
  }) {
    createdAt = DateTime.now();
  }
}

// ===================== HISTORIAL DE VENTAS =====================
@collection
class SaleHistory {
  Id id = Isar.autoIncrement;

  late int productId;
  late String productName;
  late int qty;
  late double unitPrice;
  late String method;

  @Index()
  late DateTime publishedAt;

  @Index()
  late String publishedDate;

  double get total => qty * unitPrice;

  SaleHistory();

  SaleHistory.create({
    required this.productId,
    required this.productName,
    required this.qty,
    required this.unitPrice,
    required this.method,
    required this.publishedAt,
    required this.publishedDate,
  });
}
