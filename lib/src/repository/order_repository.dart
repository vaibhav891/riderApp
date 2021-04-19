import 'dart:convert';
import 'dart:io';

import 'package:global_configuration/global_configuration.dart';
import 'package:http/http.dart' as http;

import '../helpers/custom_trace.dart';
import '../helpers/helper.dart';
import '../models/address.dart';
import '../models/order.dart';
import '../models/order_status.dart';
import '../models/user.dart';
import '../repository/user_repository.dart' as userRepo;

Future<Stream<Order>> getOrders() async {
  print("normaldelivery getOrders");
  Uri uri = Helper.getUri('api/orders');
  Map<String, dynamic> _queryParams = {};
  //final String orderStatusId = "3"; // for delivered status
  User _user = userRepo.currentUser.value;

  _queryParams['api_token'] = _user.apiToken;
  _queryParams['with'] =
      'driver;productOrders;productOrders.product;orderStatus;deliveryAddress;payment';
  _queryParams['search'] = 'driver.id:${_user.id};delivery_address_id:null';
  // _queryParams['searchFields'] = 'driver.id:=;order_status_id:<>;delivery_address_id:<>';
  // _queryParams['searchJoin'] = 'and';
  // _queryParams['orderBy'] = 'id';
  _queryParams['currentdate'] = 'today';
  uri = uri.replace(queryParameters: _queryParams);
  print(uri);
  try {
    final client = new http.Client();
    final streamedRest = await client.send(http.Request('get', uri));
    return streamedRest.stream
        .transform(utf8.decoder)
        .transform(json.decoder)
        .map((data) => Helper.getData(data))
        .expand((data) => (data as List))
        .map((data) {
      print(data);
      return Order.fromJSON(data);
    });
  } catch (e) {
    print(CustomTrace(StackTrace.current, message: uri.toString()).toString());
    return new Stream.value(new Order.fromJSON({}));
  }
}

Future<Stream<Order>> getOrders1() async {
  print("normaldelivery getOrders1");
  Uri uri = Helper.getUri('api/orders');
  Map<String, dynamic> _queryParams = {};
  //final String orderStatusId = "3"; // for delivered status
  User _user = userRepo.currentUser.value;

  _queryParams['api_token'] = _user.apiToken;
  _queryParams['with'] =
      'driver;productOrders;productOrders.product;orderStatus;deliveryAddress;payment';
  _queryParams['search'] = 'driver.id:${_user.id};delivery_address_id:null';
  // _queryParams['searchFields'] = 'driver.id:=;order_status_id:<>;delivery_address_id:<>';
  // _queryParams['searchJoin'] = 'and';
  // _queryParams['orderBy'] = 'id';
  // _queryParams['sortedBy'] = 'asc';
  // _queryParams['currentdate'] = 'today';
  uri = uri.replace(queryParameters: _queryParams);
  try {
    final client = new http.Client();
    final streamedRest = await client.send(http.Request('get', uri));
    return streamedRest.stream
        .transform(utf8.decoder)
        .transform(json.decoder)
        .map((data) => Helper.getData(data))
        .expand((data) => (data as List))
        .map((data) {
      return Order.fromJSON(data);
    });
  } catch (e) {
    print(CustomTrace(StackTrace.current, message: uri.toString()).toString());
    return new Stream.value(new Order.fromJSON({}));
  }
}

Future<Stream<Order>> getReturnOrders() async {
  print("getReturnOrders");
  //Uri uri = Helper.getUri('api/orders');
  String url = 'http://online.ajmanmarkets.ae/api/return.php';
  Uri uri = Uri(
    scheme: Uri.parse(url).scheme,
    host: Uri.parse(url).host,
    port: Uri.parse(url).port,
    path: Uri.parse(url).path,
  );
  Map<String, dynamic> _queryParams = {};
  //final String orderStatusId = "3"; // for delivered status
  User _user = userRepo.currentUser.value;

  _queryParams['api_token'] = _user.apiToken;
  _queryParams['driver_id'] = _user.id;
  uri = uri.replace(queryParameters: _queryParams);
  try {
    final client = new http.Client();
    final streamedRest = await client.send(http.Request('get', uri));
    return streamedRest.stream
        .transform(utf8.decoder)
        .transform(json.decoder)
        .map((data) => Helper.getDataForReturnOrders(data))
        .expand((data) => (data as List))
        .map((data) {
      print(data);
      return Order.fromJSON(data);
    });
  } catch (e) {
    print(CustomTrace(StackTrace.current, message: uri.toString()).toString());
    return new Stream.value(new Order.fromJSON({}));
  }
}

Future<Stream<Order>> getNearOrders(
    Address myAddress, Address areaAddress) async {
  Uri uri = Helper.getUri('api/orders');
  Map<String, dynamic> _queryParams = {};
  User _user = userRepo.currentUser.value;

  _queryParams['api_token'] = _user.apiToken;
  _queryParams['limit'] = '6';
  _queryParams['with'] =
      'driver;productOrders;productOrders.product;orderStatus;deliveryAddress;payment';
  _queryParams['search'] = 'driver.id:${_user.id};delivery_address_id:null';
  // _queryParams['searchFields'] = 'driver.id:=;delivery_address_id:<>';
  // _queryParams['searchJoin'] = 'and';
  // _queryParams['orderBy'] = 'id';
  // _queryParams['sortedBy'] = 'desc';
  uri = uri.replace(queryParameters: _queryParams);

  //final String url = '${GlobalConfiguration().getString('api_base_url')}orders?${_apiToken}with=driver;productOrders;productOrders.product;productOrders.options;orderStatus;deliveryAddress&search=driver.id:${_user.id};order_status_id:$orderStatusId&searchFields=driver.id:=;order_status_id:=&searchJoin=and&orderBy=id&sortedBy=desc';
  try {
    final client = new http.Client();
    final streamedRest = await client.send(http.Request('get', uri));
    return streamedRest.stream
        .transform(utf8.decoder)
        .transform(json.decoder)
        .map((data) => Helper.getData(data))
        .expand((data) => (data as List))
        .map((data) {
      return Order.fromJSON(data);
    });
  } catch (e) {
    print(CustomTrace(StackTrace.current, message: uri.toString()).toString());
    return new Stream.value(new Order.fromJSON({}));
  }
}

Future<Stream<Order>> getOrdersHistory() async {
  Uri uri = Helper.getUri('api/orders');
  Map<String, dynamic> _queryParams = {};
  //final String orderStatusId = "5"; // for delivered status
  User _user = userRepo.currentUser.value;

  _queryParams['api_token'] = _user.apiToken;
  _queryParams['with'] =
      'driver;productOrders;productOrders.product;orderStatus;deliveryAddress;payment';
  _queryParams['search'] = 'driver.id:${_user.id};delivery_address_id:null';
  //_queryParams['search'] = 'driver.id:${_user.id};order_status_id:$orderStatusId;delivery_address_id:null';
  // _queryParams['searchFields'] = 'driver.id:=;order_status_id:=;delivery_address_id:<>';
  // _queryParams['searchJoin'] = 'and';
  // _queryParams['orderBy'] = 'id';
  // _queryParams['sortedBy'] = 'desc';
  _queryParams['currentdate'] = 'pickedtoday';
  uri = uri.replace(queryParameters: _queryParams);
  //final String url = '${GlobalConfiguration().getString('api_base_url')}orders?${_apiToken}with=driver;productOrders;productOrders.product;productOrders.options;orderStatus;deliveryAddress&search=driver.id:${_user.id};order_status_id:$orderStatusId&searchFields=driver.id:=;order_status_id:=&searchJoin=and&orderBy=id&sortedBy=desc';
  try {
    final client = new http.Client();
    final streamedRest = await client.send(http.Request('get', uri));
    return streamedRest.stream
        .transform(utf8.decoder)
        .transform(json.decoder)
        .map((data) => Helper.getData(data))
        .expand((data) => (data as List))
        .map((data) {
      return Order.fromJSON(data);
    });
  } catch (e) {
    print(CustomTrace(StackTrace.current, message: uri.toString()).toString());
    return new Stream.value(new Order.fromJSON({}));
  }
}

Future<Stream<Order>> getOrder(orderId) async {
  User _user = userRepo.currentUser.value;
  if (_user.apiToken == null) {
    return new Stream.value(new Order());
  }
  final String _apiToken = 'api_token=${_user.apiToken}&';
  // final String url =
  //     '${GlobalConfiguration().getString('api_base_url')}orders/$orderId?${_apiToken}with=user;productOrders;productOrders.product;productOrders.options;orderStatus;deliveryAddress;payment';
  final String url =
      '${GlobalConfiguration().getString('api_base_url')}orders/$orderId?${_apiToken}with=driver;productOrders;productOrders.product;orderStatus;deliveryAddress;payment';
  print(url);
  final client = new http.Client();
  final streamedRest = await client.send(http.Request('get', Uri.parse(url)));

  return streamedRest.stream
      .transform(utf8.decoder)
      .transform(json.decoder)
      .map((data) => Helper.getObjectData(data))
      .map((data) {
    return Order.fromJSON(data);
  });
}

Future<Stream<Order>> getRecentOrders() async {
  Uri uri = Helper.getUri('api/orders');
  Map<String, dynamic> _queryParams = {};
  User _user = userRepo.currentUser.value;

  _queryParams['api_token'] = _user.apiToken;
  _queryParams['limit'] = '4';
  _queryParams['with'] =
      'driver;productOrders;productOrders.product;orderStatus;deliveryAddress;payment';
  // _queryParams['with'] = 'driver;orderStatus';
  // _queryParams['search'] = 'driver.id:${_user.id};delivery_address_id:null';
  // _queryParams['searchFields'] = 'driver.id:=;delivery_address_id:<>';
  // _queryParams['searchJoin'] = 'and';
  // _queryParams['orderBy'] = 'entity_id';
  _queryParams['currentdate'] = 'pickedtoday';

  uri = uri.replace(queryParameters: _queryParams);

  //final String url = '${GlobalConfiguration().getString('api_base_url')}orders?${_apiToken}with=driver;productOrders;productOrders.product;productOrders.options;orderStatus;deliveryAddress&search=driver.id:${_user.id};order_status_id:$orderStatusId&searchFields=driver.id:=;order_status_id:=&searchJoin=and&orderBy=id&sortedBy=desc';
  try {
    final client = new http.Client();
    final streamedRest = await client.send(http.Request('get', uri));
    return streamedRest.stream
        .transform(utf8.decoder)
        .transform(json.decoder)
        .map((data) => Helper.getData(data))
        .expand((data) => (data as List))
        .map((data) {
      return Order.fromJSON(data);
    });
  } catch (e) {
    print(CustomTrace(StackTrace.current, message: uri.toString()).toString());
    return new Stream.value(new Order.fromJSON({}));
  }
}

Future<Stream<OrderStatus>> getOrderStatus() async {
  User _user = userRepo.currentUser.value;
  if (_user.apiToken == null) {
    return new Stream.value(new OrderStatus());
  }
  final String _apiToken = 'api_token=${_user.apiToken}';
  final String url =
      '${GlobalConfiguration().getString('api_base_url')}order_statuses?$_apiToken';

  final client = new http.Client();
  final streamedRest = await client.send(http.Request('get', Uri.parse(url)));

  return streamedRest.stream
      .transform(utf8.decoder)
      .transform(json.decoder)
      .map((data) => Helper.getData(data))
      .expand((data) => (data as List))
      .map((data) {
    return OrderStatus.fromJSON(data);
  });
}

Future<Order> deliveredOrder(Order order) async {
  User _user = userRepo.currentUser.value;
  if (_user.apiToken == null) {
    return new Order();
  }
  final String _apiToken = 'api_token=${_user.apiToken}';
  final String url =
      '${GlobalConfiguration().getString('api_base_url')}orders/${order.id}?$_apiToken';
  final client = new http.Client();
  final response = await client.put(
    url,
    headers: {HttpHeaders.contentTypeHeader: 'application/json'},
    body: json.encode(order.deliveredMap()),
  );
  return Order.fromJSON(json.decode(response.body)['data']);
}

// ignore: non_constant_identifier_names
Future<Order> PreparingOrder(Order order) async {
  User _user = userRepo.currentUser.value;
  if (_user.apiToken == null) {
    return new Order();
  }
  final String _apiToken = 'api_token=${_user.apiToken}';
  final String url =
      '${GlobalConfiguration().getString('api_base_url')}orders/${order.id}?$_apiToken';
  final client = new http.Client();
  final response = await client.put(
    url,
    headers: {HttpHeaders.contentTypeHeader: 'application/json'},
    body: json.encode(order.PreparingMap()),
  );
  return Order.fromJSON(json.decode(response.body)['data']);
}

// ignore: non_constant_identifier_names
Future<Order> ActionOrder(Order order) async {
  User _user = userRepo.currentUser.value;
  if (_user.apiToken == null) {
    return new Order();
  }
  final String _apiToken = 'api_token=${_user.apiToken}';
  final String url =
      '${GlobalConfiguration().getString('api_base_url')}orders/${order.id}?$_apiToken';
  final client = new http.Client();
  final response = await client.put(
    url,
    headers: {HttpHeaders.contentTypeHeader: 'application/json'},
    body: json.encode(order.ActionMap()),
  );
  return Order.fromJSON(json.decode(response.body)['data']);
}

Future collectedOrder(Order order) async {
  User _user = userRepo.currentUser.value;
  if (_user.apiToken == null) {
    return;
  }
  final String _apiToken = 'api_token=${_user.apiToken}';
  final String url =
      'http://online.ajmanmarkets.ae/api/update-returnstatus.php';
  final client = new http.Client();
  final response = await client.post(
    url,
    headers: {HttpHeaders.contentTypeHeader: 'application/json'},
    body: json.encode({
      "order_id": order.id,
      "order_status": 7,
    }),
  );
  return;
}

Future notCollectedOrder(Order order) async {
  User _user = userRepo.currentUser.value;
  if (_user.apiToken == null) {
    return;
  }
  final String _apiToken = 'api_token=${_user.apiToken}';
  final String url =
      'http://online.ajmanmarkets.ae/api/update-returnstatus.php';
  final client = new http.Client();
  final response = await client.post(
    url,
    headers: {HttpHeaders.contentTypeHeader: 'application/json'},
    body: json.encode({
      "order_id": order.id,
      "order_status": 8,
    }),
  );
  return;
}

// ignore: non_constant_identifier_names
Future<Order> ReadyOrder(Order order) async {
  User _user = userRepo.currentUser.value;
  if (_user.apiToken == null) {
    return new Order();
  }
  final String _apiToken = 'api_token=${_user.apiToken}';
  final String url =
      '${GlobalConfiguration().getString('api_base_url')}orders/${order.id}?$_apiToken';
  final client = new http.Client();
  final response = await client.put(
    url,
    headers: {HttpHeaders.contentTypeHeader: 'application/json'},
    body: json.encode(order.ReadyMap()),
  );
  return Order.fromJSON(json.decode(response.body)['data']);
}

// ignore: non_constant_identifier_names
Future<Order> OnthewayOrder(Order order) async {
  User _user = userRepo.currentUser.value;
  if (_user.apiToken == null) {
    return new Order();
  }
  final String _apiToken = 'api_token=${_user.apiToken}';
  final String url =
      '${GlobalConfiguration().getString('api_base_url')}orders/${order.id}?$_apiToken';
  final client = new http.Client();
  final response = await client.put(
    url,
    headers: {HttpHeaders.contentTypeHeader: 'application/json'},
    body: json.encode(order.OnthewayMap()),
  );
  return Order.fromJSON(json.decode(response.body)['data']);
}

Future getProductFromBarcode(String orderId, String barcode) async {
  Uri uri = Uri.parse('https://online.ajmanmarkets.ae/api/barcode.php');
  Map<String, dynamic> _queryParams = {};

  _queryParams['order_id'] = orderId;
  _queryParams['barcode'] = barcode;
  uri = uri.replace(queryParameters: _queryParams);

  try {
    final client = new http.Client();
    final response = await client.get(
      uri,
      // headers: {HttpHeaders.contentTypeHeader: 'application/json'},
      // ),
    );
    return json.decode(response.body)['data'];

    // final streamedRest = await client.send(http.Request('get', uri));
    // return streamedRest.stream
    //     .transform(utf8.decoder)
    //     .transform(json.decoder)
    //     .map((data) => Helper.getData(data))
    //     .expand((data) => (data as List))
    //     .map((data) {
    //   return data;
    // });
  } catch (e) {
    print(CustomTrace(StackTrace.current, message: uri.toString()).toString());
    return null;
  }
}

// Future<int> markAsOutOfStockAPI(Map<String, dynamic> reqMap) async {
//   Uri uri = Uri.parse('http://online.ajmanmarkets.ae/api/stock.php');

//   try {
//     final client = new http.Client();
//     final response = await client.post(
//       uri,
//       headers: {HttpHeaders.contentTypeHeader: 'application/json'},
//       body: json.encode(reqMap),
//     );
//     if (response.body.contains('Success'))
//       return 0;
//     else if (response.body.contains('Already exists'))
//       return 1;
//     else
//       return 2;
//   } catch (e) {
//     print(CustomTrace(StackTrace.current, message: uri.toString()).toString());
//     return -1;
//   }
// }
Future markAsOutOfStockAPI(Map<String, dynamic> reqMap) async {
  Uri uri = Uri.parse('http://online.ajmanmarkets.ae/api/stock.php');

  try {
    final client = new http.Client();
    final response = await client.post(
      uri,
      headers: {HttpHeaders.contentTypeHeader: 'application/json'},
      body: json.encode(reqMap),
    );
    String responseBody = response.body;
    // var responseBody = json.decode(response.body);
    // print(responseBody);
    // if (response.body.contains('Success'))
    //   return 0;
    // else if (response.body.contains('Already exists'))
    //   return 1;
    // else
    //   return 2;
    return json.decode(responseBody);
  } catch (e) {
    print(CustomTrace(StackTrace.current, message: uri.toString()).toString());
    return e.toString();
  }
}

Future<int> addToBagAPI(Map<String, dynamic> reqMap) async {
  Uri uri = Uri.parse('http://online.ajmanmarkets.ae/api/stock.php');

  try {
    final client = new http.Client();
    final response = await client.post(
      uri,
      headers: {HttpHeaders.contentTypeHeader: 'application/json'},
      body: json.encode(reqMap),
    );
//    if (response.body.contains('Success') || response.body.contains('success'))
    if (response.statusCode == 200)
      return 0;
    // else if (response.body.contains('Already exists'))
    //   return 1;
    else
      return 2;
  } catch (e) {
    print(CustomTrace(StackTrace.current, message: uri.toString()).toString());
    return -1;
  }
}

Future<dynamic> rejectProductOrdersPartialAPI(
    Map<String, dynamic> reqMap) async {
  Uri uri =
      Uri.parse('https://online.ajmanmarkets.ae/api/partialordercancel.php');
  print(json.encode(reqMap));
  try {
    final client = new http.Client();
    final response = await client.post(
      uri,
      headers: {HttpHeaders.contentTypeHeader: 'application/json'},
      body: json.encode(reqMap),
    );
    if (response.statusCode == 200)
      return json.decode(response.body);
    // else if (response.body.contains('Already exists'))
    //   return 1;
    else
      return 2;
  } catch (e) {
    print(CustomTrace(StackTrace.current, message: uri.toString()).toString());
    return -1;
  }
}

Future<int> rejectProductOrdersFullAPI(Map<String, dynamic> reqMap) async {
  Uri uri = Uri.parse('https://online.ajmanmarkets.ae/api/rejectorder.php');

  try {
    final client = new http.Client();
    final response = await client.post(
      uri,
      headers: {HttpHeaders.contentTypeHeader: 'application/json'},
      body: json.encode(reqMap),
    );
    if (response.statusCode == 200)
      return 0;
    // else if (response.body.contains('Already exists'))
    //   return 1;
    else
      return 2;
  } catch (e) {
    print(CustomTrace(StackTrace.current, message: uri.toString()).toString());
    return -1;
  }
}

Future<int> addActionRequired(String orderId, String actionText) async {
  Uri uri = Uri.parse('http://online.ajmanmarkets.ae/api/notify.php');

  try {
    final client = new http.Client();
    final response = await client.post(
      uri,
      headers: {HttpHeaders.contentTypeHeader: 'application/json'},
      body: json.encode({
        "order_id": orderId,
        "notify_box": actionText,
      }),
    );
    if (response.body.isEmpty)
      return 0;
    else if (response.body.contains('Already exists'))
      return 1;
    else
      return 2;
  } catch (e) {
    print(CustomTrace(StackTrace.current, message: uri.toString()).toString());
    return -1;
  }
}

Future getPdfInvoice(String orderId) async {
  Uri uri = Uri.parse('http://online.ajmanmarkets.ae/api/invoicepdf.php');

  try {
    final client = new http.Client();
    final response = await client.post(
      uri,
      headers: {HttpHeaders.contentTypeHeader: 'application/json'},
      body: json.encode({
        "order_id": orderId,
      }),
    );
    if (response.statusCode == 200) {
      final res = await http.get(response.body);
      return res.body.codeUnits;
    } else
      return 'Could not fetch invoice';
  } catch (e) {
    print(CustomTrace(StackTrace.current, message: uri.toString()).toString());
    return 'Could not fetch invoice';
  }
}

Future updatePaymentMethod(String orderId, String paymentMethod) async {
  Uri uri = Uri.parse('http://online.ajmanmarkets.ae/api/paymentmethod.php');

  try {
    final client = new http.Client();
    final response = await client.post(
      uri,
      headers: {HttpHeaders.contentTypeHeader: 'application/json'},
      body: json.encode({
        "order_id": orderId,
        "payment_method": paymentMethod,
      }),
    );
    if (response.statusCode == 200) {
      var body = jsonDecode(response.body);
      if ((body as Map).containsKey('success')) {
        if (body['success'] == "1")
          return 'Updated successfully';
        else
          return 'Could not update data';
      } else
        return 'Could not update data';
    } else
      return 'Could not update data';
  } catch (e) {
    print(CustomTrace(StackTrace.current, message: uri.toString()).toString());
    return 'Could not update data';
  }
}

Future updateItemWeight(
    String orderId, String productId, String itemWeight) async {
  Uri uri = Uri.parse('https://online.ajmanmarkets.ae/api/weighteditem.php');

  try {
    final client = new http.Client();
    final response = await client.post(
      uri,
      headers: {HttpHeaders.contentTypeHeader: 'application/json'},
      body: json.encode({
        "order_id": orderId,
        "product_id": productId,
        "weight": itemWeight,
      }),
    );
    print(
      json.encode({
        "order_id": orderId,
        "product_id": productId,
        "weight": itemWeight,
      }),
    );
    print(response.statusCode);
    print(response.body);
    if (response.statusCode == 200) {
      if (jsonDecode(response.body)['success'] == 1) {
        return 'Updated successfully';
      } else {
        return 'Could not update at this time';
      }
    } else
      return 'Could not fetch data';
  } catch (e) {
    print(CustomTrace(StackTrace.current, message: uri.toString()).toString());
    // return 'Could not fetch data';
    return e.toString();
  }
}
