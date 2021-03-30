import 'package:flutter/material.dart';
import 'package:markets_deliveryboy/src/models/order_status.dart';
import 'package:mvc_pattern/mvc_pattern.dart';

import '../../generated/l10n.dart';
import '../models/order.dart';
import '../repository/order_repository.dart';

class OrderController extends ControllerMVC {
  List<Order> orders = <Order>[];
  List<Order> expressOrders = <Order>[];
  List<Order> normalOrders = <Order>[];
  static List<Order> returnOrders = <Order>[];
  GlobalKey<ScaffoldState> scaffoldKey;

  OrderController() {
    this.scaffoldKey = new GlobalKey<ScaffoldState>();
  }

  void listenForOrders({String message}) async {
    orders.clear();
    final Stream<Order> stream = await getOrders();
    stream.listen((Order _order) {
      // int value = _order.productOrders
      //     .fold<int>(0, (previousValue, element) => previousValue + double.parse(element.quantity).toInt());
      // int value2 =
      //     _order.productOrders.fold<int>(0, (previousValue, element) => previousValue + (element.inBagQty ?? 0));
      int value3 = _order.productOrders.fold<int>(
          0,
          (previousValue, element) =>
              previousValue + (element.outOfStockQnty ?? 0));
      if (/*value <= value2 + value3 && */ value3 > 0) {
        _order.orderStatus = OrderStatus.fromJSON({
          'id': '6',
          'status': 'Action_required',
        });
      }
      //setState(() {
      expressOrders.add(_order);
      //});
    }, onError: (a) {
      print(a);
      scaffoldKey?.currentState?.showSnackBar(SnackBar(
        content: Text(S.of(context).verify_your_internet_connection),
      ));
    }, onDone: () {
      setState(() {
        orders = expressOrders;
      });
      if (message != null) {
        scaffoldKey?.currentState?.showSnackBar(SnackBar(
          content: Text(message),
        ));
      }
    });
  }

  void listenForOrders1({String message}) async {
    orders.clear();
    final Stream<Order> stream = await getOrders1();
    stream.listen((Order _order) {
      // int value = _order.productOrders
      //     .fold<int>(0, (previousValue, element) => previousValue + double.parse(element.quantity).toInt());
      // int value2 =
      //     _order.productOrders.fold<int>(0, (previousValue, element) => previousValue + (element.inBagQty ?? 0));
      int value3 = _order.productOrders.fold<int>(
          0,
          (previousValue, element) =>
              previousValue + (element.outOfStockQnty ?? 0));
      if (/*value <= value2 + value3 && */ value3 > 0) {
        _order.orderStatus = OrderStatus.fromJSON({
          'id': '6',
          'status': 'Action_required',
        });
      }
      //setState(() {
      normalOrders.add(_order);
      //});
    }, onError: (a) {
      print(a);
      scaffoldKey?.currentState?.showSnackBar(SnackBar(
        content: Text(S.of(context).verify_your_internet_connection),
      ));
    }, onDone: () {
      setState(() {
        orders = normalOrders;
      });
      if (message != null) {
        scaffoldKey?.currentState?.showSnackBar(SnackBar(
          content: Text(message),
        ));
      }
    });
  }

  void listenForReturnOrders({String message}) async {
    orders.clear();
    final Stream<Order> stream = await getReturnOrders();
    stream.listen((Order _order) {
      // if (value <= value2 + value3 && value3 > 0) {
      _order.orderStatus = OrderStatus.fromJSON({
        'id': '20',
        'status': 'Received',
      });
      // }
      //setState(() {
      returnOrders.add(_order);
      //});
    }, onError: (a) {
      print(a);
      scaffoldKey?.currentState?.showSnackBar(SnackBar(
        content: Text(S.of(context).verify_your_internet_connection),
      ));
    }, onDone: () {
      setState(() {
        orders = returnOrders;
      });
      if (message != null) {
        scaffoldKey?.currentState?.showSnackBar(SnackBar(
          content: Text(message),
        ));
      }
    });
  }

  void listenForOrdersHistory({String message}) async {
    final Stream<Order> stream = await getOrdersHistory();
    stream.listen((Order _order) {
      setState(() {
        orders.add(_order);
      });
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

  Future<void> refreshOrdersHistory() async {
    orders.clear();
    listenForOrdersHistory(message: S.of(context).order_refreshed_successfuly);
  }

  Future<void> refreshOrders() async {
    orders.clear();
    listenForOrders(message: S.of(context).order_refreshed_successfuly);
  }

  Future<void> refreshOrdersOnPop() async {
    orders.clear();
    listenForOrders();
  }
}
