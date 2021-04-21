import 'dart:io';

import 'package:flutter/material.dart';
import 'package:markets_deliveryboy/src/controllers/order_controller.dart';
import 'package:markets_deliveryboy/src/helpers/helper.dart';
import 'package:markets_deliveryboy/src/models/order_status.dart';
import 'package:markets_deliveryboy/src/models/product_order.dart';
import 'package:mvc_pattern/mvc_pattern.dart';
import 'package:path_provider/path_provider.dart';

import '../../generated/l10n.dart';
import '../models/order.dart';
import '../repository/order_repository.dart';

class OrderDetailsController extends ControllerMVC {
  Order order;
  double deliveryFee = 0.0;
  GlobalKey<ScaffoldState> scaffoldKey;
  // String productFromBarcode;

  OrderDetailsController() {
    this.scaffoldKey = new GlobalKey<ScaffoldState>();
  }

  void listenForOrder({String id, String message}) async {
    //var _con = OrderController()..listenForReturnOrders();
    var returnOrders = OrderController.returnOrders;
    if (true) {
      for (var _order in returnOrders) {
        if (_order.id == id) {
          setState(() => order = _order);
          return;
        }
      }
    }

    final Stream<Order> stream = await getOrder(id);
    stream.listen((Order _order) {
      // int value = _order.productOrders.fold<int>(
      //     0,
      //     (previousValue, element) =>
      //         previousValue + double.parse(element.quantity).toInt());
      // int value2 = _order.productOrders.fold<int>(0,
      //     (previousValue, element) => previousValue + (element.inBagQty ?? 0));
      int value3 = _order.productOrders.fold<int>(
          0,
          (previousValue, element) =>
              previousValue + (element.outOfStockQnty ?? 0));
      if (/*value <= value2 + value3 && */ value3 > 0 &&
          _order.orderStatus.id == '2') {
        _order.orderStatus = OrderStatus.fromJSON({
          'id': '21',
          'status': 'Submit_Action_required',
        });
      }
      setState(() => order = _order);
    }, onError: (a) {
      print(a);
      scaffoldKey?.currentState?.showSnackBar(SnackBar(
        content: Text(S.of(context).verify_your_internet_connection),
      ));
    }, onDone: () {
      if (message != null) {
        scaffoldKey?.currentState?.showSnackBar(SnackBar(
          content: Text(message),
        ));
      }
    });
  }

  Future<void> refreshOrder() async {
    listenForOrder(
        id: order.id, message: S.of(context).order_refreshed_successfuly);
  }

  void doPreparingOrder(Order _order) async {
    PreparingOrder(_order).then((value) {
      setState(() {
        this.order.orderStatus.id = '2';
      });
      scaffoldKey?.currentState?.showSnackBar(SnackBar(
        content: Text('The order preparing successfully to client'),
      ));
    });
  }

  void doActionOrder(Order _order) async {
    ActionOrder(_order).then((value) {
      setState(() {
        this.order.orderStatus.id = '6';
      });
      scaffoldKey?.currentState?.showSnackBar(SnackBar(
        content: Text('The action notification sent!'),
      ));
    });
  }

  void doReadyOrder(Order _order) async {
    // updated to check if all items are either added to bag or marked out of stock before ready
    bool flag = false;
    for (var product in _order.productOrders) {
      if (double.parse(product.quantity) !=
          (product.inBagQty ?? 0) + (product.outOfStockQnty ?? 0)) {
        flag = true;
        break;
      }
    }
    if (flag) {
      scaffoldKey?.currentState?.showSnackBar(SnackBar(
        content: Text(
            'Please make sure all the products are either added to cart or marked as out of stock'),
      ));
      return;
    }
    ReadyOrder(_order).then((value) {
      int totalQty = 0, bagQty = 0;
      order.productOrders.forEach((element) {
        totalQty += double.parse(element.quantity).toInt();
        bagQty += element.inBagQty;
      });
      setState(() {
        if (totalQty != bagQty) {
          order.orderStatus.id = '6';
        } else
          order.orderStatus.id = '3';
      });
      scaffoldKey?.currentState?.showSnackBar(SnackBar(
        content: Text('The order ready to pickup successfully to client'),
      ));
    });
  }

  void doCollectedOrder(Order _order) async {
    collectedOrder(_order).then((value) {
      setState(() {
        this.order.orderStatus.id = '7';
      });
      scaffoldKey?.currentState?.showSnackBar(SnackBar(
        content: Text('The order collected successfully'),
      ));
    });
  }

  void doNotCollectedOrder(Order _order) async {
    notCollectedOrder(_order).then((value) {
      setState(() {
        this.order.orderStatus.id = '8';
      });
      scaffoldKey?.currentState?.showSnackBar(SnackBar(
        content: Text('Order could not be collected'),
      ));
    });
  }

  void doOnthewayOrder(Order _order) async {
    OnthewayOrder(_order).then((value) {
      setState(() {
        this.order.orderStatus.id = '4';
      });
      scaffoldKey?.currentState?.showSnackBar(SnackBar(
        content: Text('The order On the way successfully to client'),
      ));
    });
  }

  void doDeliveredOrder(Order _order) async {
    deliveredOrder(_order).then((value) {
      setState(() {
        this.order.orderStatus.id = '5';
      });
      scaffoldKey?.currentState?.showSnackBar(SnackBar(
        content: Text('The order deliverd successfully to client'),
      ));
    });
  }

  Future getProductDetails(
      {String orderId, String barcode, String message}) async {
    var productFromBarcode = await getProductFromBarcode(orderId, barcode);
    return productFromBarcode;
  }

  Future addProductsToBag(
      List<ProductOrder> productOrdersList, String orderId) async {
    List<Map> itemMapList = productOrdersList
        .map((e) => {
              'product_id': e.product.id,
              'qty': e.selectedQuantity,
            })
        .toList();
    Map<String, dynamic> reqMap = {
      'order_id': orderId,
      'item': itemMapList,
    };
    Map response = await addToBagAPI(reqMap);
    int responseId = response['id'];
    if (responseId == 0) {
      print(
          '${productOrdersList?.map((e) => e.toMap())?.toList()} added to bag');
      setState(() {
        productOrdersList.forEach((e) {
          // e.inBagQty = double.parse(e.selectedQuantity).toInt();
          e.inBagQty = response['qty'];
          e.outOfStockQnty = double.parse(e.quantity).toInt() - e.inBagQty;
          // double.parse(e.selectedQuantity).toInt();
          e.selectedQuantity = '0.0';
        });
      });
      scaffoldKey?.currentState?.showSnackBar(SnackBar(
        content: Text(response['message']),
      ));
      return true;
    } else {
      scaffoldKey?.currentState?.showSnackBar(SnackBar(
        content: Text(response['message']),
      ));
      productOrdersList.forEach((e) {
        e.selectedQuantity = '0.0';
      });
      return false;
    }
  }

  // markedAsOutOfStock(
  //     List<ProductOrder> productOrdersList, String orderId) async {
  //   List<Map> itemMapList = productOrdersList
  //       .map((e) => {
  //             'product_id': e.product.id,
  //             'qty': e.selectedQuantity,
  //           })
  //       .toList();
  //   Map<String, dynamic> reqMap = {
  //     'order_id': orderId,
  //     'item': itemMapList,
  //   };
  //   int responseId = await markAsOutOfStockAPI(reqMap);
  //   if (responseId == 0) {
  //     print(
  //         '${productOrdersList?.map((e) => e.toMap())?.toList()} marked as out of stock');
  //     setState(() {
  //       productOrdersList.forEach((e) {
  //         // _con.order.productOrders.remove(e);
  //         e.outOfStockQnty = double.parse(e.selectedQuantity).toInt();
  //         e.selectedQuantity = '0.0';
  //         //e.quantity = '0';
  //       });
  //       // order.orderStatus = OrderStatus.fromJSON({
  //       //   'id': '6',
  //       //   'status': 'Action_required',
  //       // });
  //     });
  //     scaffoldKey?.currentState?.showSnackBar(SnackBar(
  //       content: Text('Marked as out of stock successfully!'),
  //     ));
  //     return true;
  //   } else {
  //     scaffoldKey?.currentState?.showSnackBar(SnackBar(
  //       content: Text(responseId == 1
  //           ? 'Already Exists'
  //           : 'Could not mark as out of stock!'),
  //     ));
  //     return false;
  //   }
  // }

  rejectProductOrdersPartial(List<ProductOrder> productOrdersList,
      String orderId, String driverId) async {
    // List<Map> itemMapList = productOrdersList
    //     .map((e) => {
    //           'product_id': e.product.id,
    //         })
    //     .toList();
    var response;
    // productOrdersList.forEach((element)  {
    //   Map<String, dynamic> reqMap = {
    //     'order_id': orderId,
    //     'driver_id': driverId,
    //     'qty': element.selectedQuantity,
    //     'product_id': element.id,
    //   };
    //   responseId =  rejectProductOrdersPartialAPI(reqMap).then((value) => responseId=);
    // });
    for (var element in productOrdersList) {
      Map<String, dynamic> reqMap = {
        'order_id': orderId,
        'driver_id': driverId,
        'qty': element.selectedQuantity,
        'product_id': element.product.id,
      };
      response = await rejectProductOrdersPartialAPI(reqMap);
    }
    if (response == 2) {
      scaffoldKey?.currentState?.showSnackBar(SnackBar(
        content: Text('Could not be rejected!'),
      ));
      return false;
    } else {
      print('${productOrdersList?.map((e) => e.toMap())?.toList()} rejected');
      productOrdersList.forEach((e) {
        e.quantity = response['data']['new_qty'].toString();
      });
      order.grandtotal = response['data']['new_price'].toString();
      setState(() {});
      scaffoldKey?.currentState?.showSnackBar(SnackBar(
        content: Text('Rejected successfully!'),
      ));
      return true;
    }
  }

  rejectProductOrdersFull(String orderId, String driverId) async {
    Map<String, dynamic> reqMap = {
      'order_id': orderId,
      'driver_id': driverId,
    };
    int responseId = await rejectProductOrdersFullAPI(reqMap);
    if (responseId == 0) {
      // print('${productOrdersList?.map((e) => e.toMap())?.toList()} rejected');
      // productOrdersList.forEach((e) {
      //   e.quantity = '0';
      // });
      setState(() {
        order.orderStatus.id = '9';
        order.orderStatus.status = 'order rejected';
      });
      scaffoldKey?.currentState?.showSnackBar(SnackBar(
        content: Text('Rejected successfully!'),
      ));
      return true;
    } else {
      scaffoldKey?.currentState?.showSnackBar(SnackBar(
        content:
            Text(responseId == 1 ? 'Already Exists' : 'Could not be rejected!'),
      ));
      return false;
    }
  }

  void addProductOrder(ProductOrder _productOrder, int selectedQuantity) async {
    // if (doesProductOrderExist(_productOrder)) {
    //   scaffoldKey?.currentState?.showSnackBar(SnackBar(
    //     content: Text('Product already exists!'),
    //   ));
    //   return;
    // }

    //updated to fix scanning issue
    // var existingProductOrder =
    //     this.order?.productOrders?.firstWhere((e) => e.id == _productOrder.product.id, orElse: () => null);
    var existingProductOrderIndex = order?.productOrders
        ?.indexWhere((e) => e.id == _productOrder.product.id);
    if (existingProductOrderIndex != -1) {
      setState(() {
        //existingProductOrder.quantity
        order.productOrders[existingProductOrderIndex].selectedQuantity =
            Helper.stringToStringFixed(
                /*(Helper.toDouble(existingProductOrder.quantity) + */ (Helper
                        .toDouble(selectedQuantity.toString()))
                    .toString(),
                2);
        // existingProductOrder.isScanned = true;
        order.productOrders[existingProductOrderIndex].isScanned = true;
      });
      _productOrder.selectedQuantity = selectedQuantity.toString();
      // await addProductsToBag(order.productOrders, order.id);
      await addProductsToBag(
          [order.productOrders[existingProductOrderIndex]], order.id);
      // scaffoldKey?.currentState?.showSnackBar(SnackBar(
      //   content: Text('Product updated!'),
      // ));
      return;
    }

    setState(() {
      this.order.productOrders.add(_productOrder);
    });
    scaffoldKey?.currentState?.showSnackBar(SnackBar(
      content: Text('Product added!'),
    ));
  }

  bool doesProductOrderExist(ProductOrder newProductOrder) {
    if (newProductOrder?.product?.id == null) {
      print('Invalid product order');
      return false;
    }
    return this.order.doesProductOrderExist(newProductOrder?.product?.id);
  }

  bool confirmProductsSelection(List list) {
    if (list == null || list.isEmpty) {
      scaffoldKey?.currentState?.showSnackBar(SnackBar(
        content: Text('No products selected!'),
      ));
      return false;
    }
    return true;
  }

  bool confirmProductsQuantity(List<ProductOrder> list) {
    if (list.any((e) => Helper.toDouble(e.selectedQuantity) < 0)) {
      scaffoldKey?.currentState?.showSnackBar(SnackBar(
        content: Text('Not enough quantity to add to bag!'),
      ));
      return false;
    }
    return true;
  }

  void productNotFoundSnackbar() {
    scaffoldKey?.currentState?.showSnackBar(SnackBar(
      content: Text('Product not found!'),
    ));
  }

  void noCameraPermissionsSnackbar() {
    scaffoldKey?.currentState?.showSnackBar(SnackBar(
      content: Text('Please allow camera permssions to scan barcode!'),
    ));
  }

  void orderStatusSnackbar() {
    scaffoldKey?.currentState?.showSnackBar(SnackBar(
      content: Text('Please accept the order before proceeding!'),
    ));
  }

  void contentEmptySnackbar() {
    scaffoldKey?.currentState?.showSnackBar(SnackBar(
      content: Text('Comment Cannot be empty!'),
    ));
  }

  bool isPickerStatus() =>
      Helper.pickerStatuses.contains(order?.orderStatus?.id);

  bool isDelivererStatus() =>
      Helper.delivererStatuses.contains(order?.orderStatus?.id);

  Future submitActoinRequired(String orderId, String actionText) async {
    int responseId = await addActionRequired(orderId, actionText);
    if (responseId == 0) {
      scaffoldKey?.currentState?.showSnackBar(SnackBar(
        content: Text('Action added to order!'),
      ));
      return true;
    } else {
      scaffoldKey?.currentState?.showSnackBar(SnackBar(
        content:
            Text(responseId == 1 ? 'Already Exists' : 'Could not be added!'),
      ));
      return false;
    }
  }

  Future<File> getInvoicePdf(String orderId) async {
    var invoice = await getPdfInvoice(orderId);
    if (invoice is String) {
      return Future.error('error');
    }
    final output = await getTemporaryDirectory();
    final file = File("${output.path}/example.pdf");
    await file.writeAsBytes(invoice);
    return file;
  }
}
