import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:keyboard_visibility/keyboard_visibility.dart';
import 'package:markets_deliveryboy/src/models/order_status.dart';
import 'package:markets_deliveryboy/src/repository/order_repository.dart';
import 'package:markets_deliveryboy/src/repository/user_repository.dart';

import '../helpers/helper.dart';
import '../models/order.dart';
import '../models/product_order.dart';

class ProductOrderItemWidget extends StatefulWidget {
  final String heroTag;
  final ProductOrder productOrder;
  final OrderStatus orderStatus;
  final Order order;
  final Widget radio;
  final bool isScanned;

  const ProductOrderItemWidget({
    Key key,
    this.productOrder,
    this.order,
    this.heroTag,
    this.radio,
    this.orderStatus,
    this.isScanned = false,
  }) : super(key: key);

  @override
  _ProductOrderItemWidgetState createState() => _ProductOrderItemWidgetState();
}

class _ProductOrderItemWidgetState extends State<ProductOrderItemWidget> {
  FocusNode myFocusNode = FocusNode();
  KeyboardVisibilityNotification _keyboardVisibility =
      new KeyboardVisibilityNotification();
  int _keyboardVisibilitySubscriberId;
  TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();

    _keyboardVisibilitySubscriberId = _keyboardVisibility.addNewListener(
      onChange: (bool visible) {
        if (!visible) {
          myFocusNode.unfocus();
        }
      },
    );
    _controller.text = widget.productOrder.weightedItem;
  }

  @override
  void dispose() {
    _keyboardVisibility.removeListener(_keyboardVisibilitySubscriberId);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      splashColor: Theme.of(context).accentColor,
      focusColor: Theme.of(context).accentColor,
      highlightColor: Theme.of(context).primaryColor,
      // onTap: () {
      //   Navigator.of(context).pushReplacementNamed('/OrderDetails', arguments: RouteArgument(id: order.id));
      // },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.9),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.35,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Image.network(
                    widget.productOrder.image != null &&
                            widget.productOrder.image
                                .split('/')
                                .first
                                .toUpperCase()
                                .contains("HTTP")
                        ? widget.productOrder.image
                        : "http://online.ajmanmarkets.ae/pub/media/catalog/product${widget.productOrder?.image}",
                    height: 75,
                    width: 75,
                  ),
                  Text(
                    "Category: ${widget.productOrder?.categoryName}",
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                    style: TextStyle(fontSize: 15),
                  ),
                  Text(
                    widget.productOrder?.name,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                    style: TextStyle(fontSize: 12),
                  ),
                  // added to show item barcode
                  Text(
                    'code: ${widget.productOrder?.itemBarcode}',
                    overflow: TextOverflow.ellipsis,
                    //maxLines: 2,
                    style: TextStyle(fontSize: 11),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  RichText(
                    text: TextSpan(
                      text: "x  ",
                      style: Theme.of(context).textTheme.subtitle1,
                      children: [
                        TextSpan(
                          text: double.tryParse(widget.productOrder.quantity)
                                  ?.toStringAsFixed(0) ??
                              0,
                          style: Theme.of(context)
                              .textTheme
                              .headline1
                              .copyWith(fontSize: 20),
                        ),
                      ],
                    ),
                  ),
                  Helper.getPrice(
                      Helper.getOrderPrice(widget.productOrder), context,
                      style: Theme.of(context).textTheme.caption),
                  Text("Bag: ${widget.productOrder.inBagQty ?? 0}"),
                  if (currentUser.value.role_id == 'picker')
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Expanded(
                          child: TextField(
                            focusNode: myFocusNode,
                            controller: _controller,
                            textAlign: TextAlign.center,
                            decoration: InputDecoration(
                              isDense: true,
                              contentPadding: EdgeInsets.fromLTRB(4, 4, 4, 4),
                              border: OutlineInputBorder(),
                            ),
                            onSubmitted: (value) async {
                              widget.productOrder.weightedItem =
                                  _controller.text;
                              var weightedTotal = double.parse(
                                      _controller.text) *
                                  double.parse(widget.productOrder.quantity);
                              var message = await updateItemWeight(
                                  widget.order.id,
                                  widget.productOrder.product.id,
                                  weightedTotal.toInt().toString());
                              print(message);
                              Fluttertoast.showToast(msg: message);
                            },
                          ),
                        ),
                        GestureDetector(
                          onTap: () async {
                            widget.productOrder.weightedItem = _controller.text;
                            var weightedTotal = double.parse(_controller.text) *
                                double.parse(widget.productOrder.quantity);
                            var message = await updateItemWeight(
                                widget.order.id,
                                widget.productOrder.product.id,
                                weightedTotal.toInt().toString());
                            print(message);
                            Fluttertoast.showToast(msg: message);
                          },
                          child: Icon(Icons.arrow_circle_up_rounded),
                        ),
                      ],
                    )
                ],
              ),
            ),
            Container(
              width: MediaQuery.of(context).size.width * 0.1,
              child: widget.isScanned
                  ? Icon(
                      Icons.qr_code_scanner_sharp,
                    )
                  : SizedBox.shrink(),
            ),
            widget.radio
          ],
        ),
      ),
    );
  }
}
