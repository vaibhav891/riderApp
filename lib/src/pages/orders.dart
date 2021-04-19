import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:markets_deliveryboy/src/repository/user_repository.dart';
import 'package:mvc_pattern/mvc_pattern.dart';

import '../../generated/l10n.dart';
import '../controllers/order_controller.dart';
import '../elements/EmptyOrdersWidget.dart';
import '../elements/OrderItemWidget.dart';
import '../elements/ShoppingCartButtonWidget.dart';

class OrdersWidget extends StatefulWidget {
  final GlobalKey<ScaffoldState> parentScaffoldKey;
  // final String selected = "first";
  OrdersWidget({Key key, this.parentScaffoldKey}) : super(key: key);

  @override
  _OrdersWidgetState createState() => _OrdersWidgetState();
}

class _OrdersWidgetState extends StateMVC<OrdersWidget> {
  OrderController _con;
  bool pressAttention = false;
  bool pressAttention1 = true;
  _OrdersWidgetState() : super(OrderController()) {
    _con = controller;
  }

  @override
  void initState() {
    _con.listenForOrders();
    // _con.listenForOrders1();
    super.initState();
  }

  void dosomething(String buttonName) {
    if (buttonName == "Express") {
      setState(() {
        pressAttention = false;
        pressAttention1 = true;
        _con.listenForOrders();
      });
    } else if (buttonName == "Return") {
      setState(() {
        pressAttention = false;
        pressAttention1 = true;
        _con.listenForReturnOrders();
      });
    } else {
      setState(() {
        pressAttention = true;
        pressAttention1 = false;
        _con.listenForOrders();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _con.scaffoldKey,
      appBar: AppBar(
        leading: new IconButton(
          icon: new Icon(Icons.sort, color: Theme.of(context).hintColor),
          onPressed: () => widget.parentScaffoldKey.currentState.openDrawer(),
        ),
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          S.of(context).orders,
          style: Theme.of(context)
              .textTheme
              .headline6
              .merge(TextStyle(letterSpacing: 1.3)),
        ),
        actions: <Widget>[
          new ShoppingCartButtonWidget(
              iconColor: Theme.of(context).hintColor,
              labelColor: Theme.of(context).accentColor),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _con.refreshOrders,
        child: ListView(
          padding: EdgeInsets.symmetric(vertical: 10),
          children: <Widget>[
            Container(
              // color: Colors.blue,
              // margin: EdgeInsets.all(10),
              // padding: EdgeInsets.all(10),
              child: Row(
                children: [
                  Expanded(
                    child: FlatButton(
                      // child: Text("Normal Delivery",
                      child: Text("Normal",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          )),
                      color: pressAttention ? Color(0xff0068b2) : Colors.orange,
                      onPressed: () => dosomething("Normal"),
                    ),
                  ),
                  SizedBox(
                    width: 1,
                  ),
                  Expanded(
                    child: RaisedButton(
                      child: Text("Express",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          )),

                      //// onPressed: null,
                      color:
                          pressAttention1 ? Color(0xff0068b2) : Colors.orange,
                      onPressed: () => dosomething("Express"),

                      // color: Theme.of(context).accentColor,
                      //               disabledColor: Colors.blue,//add this to your code
                    ),
                  ),
                  if (currentUser.value.role_id == 'driver')
                    SizedBox(
                      width: 1,
                    ),
                  if (currentUser.value.role_id == 'driver')
                    Expanded(
                      child: FlatButton(
                        child: Text("Return",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            )),
                        color:
                            pressAttention1 ? Color(0xff0068b2) : Colors.orange,
                        onPressed: () => dosomething("Return"),
                      ),
                    ),
                ],
              ),
            ),
            _con.orders.isEmpty
                ? EmptyOrdersWidget()
                : ListView.separated(
                    scrollDirection: Axis.vertical,
                    shrinkWrap: true,
                    primary: false,
                    itemCount: _con.orders.length,
                    itemBuilder: (context, index) {
                      var _order = _con.orders.elementAt(index);
                      return OrderItemWidget(
                          expanded: index == 0 ? true : false,
                          order: _order,
                          callback: () {
                            setState(() {
                              _con.refreshOrdersOnPop();
                            });
                          });
                    },
                    separatorBuilder: (context, index) {
                      return SizedBox(height: 20);
                    },
                  ),
          ],
        ),
      ),
    );
  }
}
