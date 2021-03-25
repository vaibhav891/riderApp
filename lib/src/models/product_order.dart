import '../models/option.dart';
import '../models/product.dart';

class ProductOrder {
  String id;
  String price;
  String name;
  String quantity;
  List<Option> options;
  Product product;
  DateTime dateTime;
  bool isScanned;
  String itemBarcode;
  int outOfStockQnty;
  int inBagQty;
  String image;
  int categoryId;
  String categoryName;
  String selectedQuantity;
  String deliveryDate;

  ProductOrder(
      {this.id,
      this.price,
      this.name,
      this.quantity,
      this.options,
      this.product,
      this.dateTime,
      this.isScanned = false,
      this.itemBarcode,
      this.outOfStockQnty,
      this.inBagQty,
      this.image,
      this.categoryId,
      this.categoryName,
      this.selectedQuantity,
      this.deliveryDate});

  ProductOrder.fromJSON(Map<String, dynamic> jsonMap) {
    try {
      isScanned = jsonMap['scanned'] != null
          ? jsonMap['scanned'] == 1
              ? true
              : false
          : false;
      id = jsonMap['item_id'].toString();
      price = jsonMap['price'] != null ? jsonMap['price'] : '0.0';
      name = jsonMap['name'] != null ? jsonMap['name'] : '0.0';
      quantity = jsonMap['qty_ordered'] != null ? jsonMap['qty_ordered'] : '0.0';
      product = jsonMap['product'] != null ? Product.fromJSON(jsonMap['product']) : null;
      dateTime = jsonMap['updated_at'] != null ? DateTime.parse(jsonMap['updated_at']) : null;
      options = jsonMap['options'] != null
          ? List.from(jsonMap['options']).map((element) => Option.fromJSON(element)).toList()
          : null;
      itemBarcode = jsonMap['item_barcode'];
      outOfStockQnty = jsonMap['outofstockqty'] ?? 0;
      inBagQty = jsonMap['inbagqty'] ?? 0;
      image = jsonMap['product_image'];
      categoryId = jsonMap['category_id'];
      categoryName = jsonMap['category_name'];
      selectedQuantity = jsonMap['selected_quantity'] != null ? jsonMap['selected_quantity'] : '0.0';
      deliveryDate = jsonMap['delivery_date'] != null ? jsonMap['delivery_date'] : "";
    } catch (e) {
      isScanned = false;
      id = '';
      price = '0.0';
      quantity = '0.0';
      name = "";
      product = new Product();
      dateTime = DateTime(0);
      options = [];
      itemBarcode = '';
      outOfStockQnty = 0;
      inBagQty = 0;
      image = "";
      categoryId = 0;
      categoryName = '';
      deliveryDate = '';
      print(e);
    }
  }

  Map toMap() {
    var map = new Map<String, dynamic>();
    map["id"] = id;
    map["price"] = price;
    map["name"] = name;
    map["quantity"] = quantity;
    map["product_id"] = product.id;
    map["options"] = options?.map((element) => element.id)?.toList();
    map["scanned"] = isScanned;
    map["item_barcode"] = itemBarcode;
    map["outofstockqty"] = outOfStockQnty;
    map["inbagqty"] = inBagQty;
    map["product_image"] = inBagQty;
    map["category_id"] = inBagQty;
    map["selected_quantity"] = selectedQuantity;
    map["delivery_date"] = deliveryDate;
    return map;
  }
}
