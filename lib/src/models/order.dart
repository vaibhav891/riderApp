import '../helpers/custom_trace.dart';
import '../models/address.dart';
import '../models/order_status.dart';
import '../models/payment.dart';
import '../models/product_order.dart';
import '../models/user.dart';

class Order {
  String id;
  // ignore: non_constant_identifier_names
  String increment_id;
  // ignore: non_constant_identifier_names
  String delivery_date;
  List<ProductOrder> productOrders;
  OrderStatus orderStatus;
  String tax;
  String grandtotal;
  String deliveryFee;
  String hint;
  String customername;
  DateTime dateTime;
  User user;
  Payment payment;
  Address deliveryAddress;
  int actionRequired;
  String driverId;

  Order();

  Order.fromJSON(Map<String, dynamic> jsonMap) {
    try {
      id = jsonMap['id'].toString();
      increment_id = jsonMap['increment_id'].toString();
      delivery_date = jsonMap['delivery_date'].toString();
      customername = jsonMap['customer_firstname'].toString();
      tax = jsonMap['tax'] != null ? jsonMap['tax'] : '0.0';
      deliveryFee = jsonMap['delivery_fee'] != null ? jsonMap['delivery_fee'] : '0.0';
      hint = jsonMap['hint'].toString();
      grandtotal = jsonMap['base_grand_total'] != null ? jsonMap['base_grand_total'] : '0.0';
      orderStatus = jsonMap['order_status'] != null ? OrderStatus.fromJSON(jsonMap['order_status']) : new OrderStatus();
      dateTime = jsonMap['updated_at'] != null ? DateTime.parse(jsonMap['updated_at']) : DateTime.now();
      user = jsonMap['user'] != null ? User.fromJSON(jsonMap['user']) : new User();
      payment = jsonMap['payment'] != null ? Payment.fromJSON(jsonMap['payment']) : new Payment.init();
      deliveryAddress =
          jsonMap['delivery_address'] != null ? Address.fromJSON(jsonMap['delivery_address']) : new Address();
      productOrders = jsonMap['product_orders'] != null
          ? List.from(jsonMap['product_orders']).map((element) => ProductOrder.fromJSON(element)).toList()
          : [];
      actionRequired = jsonMap['action_required'] != null ? jsonMap['action_required'] : 0;
      driverId = jsonMap['driver_id'] != null ? jsonMap['driver_id'].toString() : "0";
    } catch (e) {
      id = '';
      increment_id = '';
      delivery_date = '';
      customername = "";
      tax = '0.0';
      grandtotal = '0.0';
      deliveryFee = '0.0';
      hint = '';
      orderStatus = new OrderStatus();
      dateTime = DateTime(0);
      user = new User();
      payment = new Payment.init();
      deliveryAddress = new Address();
      productOrders = [];
      actionRequired = 0;
      driverId = "";
      print(CustomTrace(StackTrace.current, message: e));
    }
  }

  Map toMap() {
    var map = new Map<String, dynamic>();
    map["id"] = id;
    map["increment_id"] = increment_id;
    map["delivery_date"] = delivery_date;
    map["customername"] = customername;
    map["user_id"] = user?.id;
    map["order_status_id"] = orderStatus?.id;
    map["tax"] = tax;
    map["grandtotal"] = grandtotal;
    map["delivery_fee"] = deliveryFee;
    map["products"] = productOrders.map((element) => element.toMap()).toList();
    map["payment"] = payment?.toMap();
    map["action_required"] = actionRequired;
    map["driver_id"] = driverId;

    if (deliveryAddress?.id != null && deliveryAddress?.id != 'null') map["delivery_address_id"] = deliveryAddress.id;
    return map;
  }

  // ignore: non_constant_identifier_names
  Map PreparingMap() {
    var map = new Map<String, dynamic>();
    map["id"] = id;
    map["order_status_id"] = 2;
    return map;
  }

  // ignore: non_constant_identifier_names
  Map ActionMap() {
    var map = new Map<String, dynamic>();
    map["id"] = id;
    map["order_status_id"] = 6;
    return map;
  }

  // ignore: non_constant_identifier_names
  Map ReadyMap() {
    var map = new Map<String, dynamic>();
    map["id"] = id;
    map["order_status_id"] = 3;
    return map;
  }

  // ignore: non_constant_identifier_names
  Map OnthewayMap() {
    var map = new Map<String, dynamic>();
    map["id"] = id;
    map["order_status_id"] = 4;
    return map;
  }

  Map deliveredMap() {
    var map = new Map<String, dynamic>();
    map["id"] = id;
    map["order_status_id"] = 5;
    return map;
  }

  bool doesProductOrderExist(String productOrderId) {
    return this.productOrders?.any((element) => element?.product?.id == productOrderId) ?? false;
  }
}
