import 'package:flutter/material.dart';
import 'package:markets_deliveryboy/src/models/order_status.dart';

import '../helpers/helper.dart';
import '../models/order.dart';
import '../models/product_order.dart';

class ProductOrderItemWidget extends StatelessWidget {
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
                    productOrder.image != null && productOrder.image.split('/').first.toUpperCase().contains("HTTP")
                        ? productOrder.image
                        : "http://online.ajmanmarkets.ae/pub/media/catalog/product${productOrder?.image}",
                    height: 75,
                    width: 75,
                  ),
                  Text(
                    "Category: ${productOrder?.categoryName}",
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                    style: TextStyle(fontSize: 15),
                  ),
                  Text(
                    productOrder?.name,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                    style: TextStyle(fontSize: 12),
                  ),
                  // added to show item barcode
                  Text(
                    'code: ${productOrder?.itemBarcode}',
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
                          text: double.tryParse(productOrder.quantity)?.toStringAsFixed(0) ?? 0,
                          style: Theme.of(context).textTheme.headline1.copyWith(fontSize: 20),
                        ),
                      ],
                    ),
                  ),
                  Helper.getPrice(Helper.getOrderPrice(productOrder), context,
                      style: Theme.of(context).textTheme.caption),

                  //if (orderStatus.id == '2')
                  Text("Bag: ${productOrder.inBagQty ?? 0}"),
                  //  Text("OutOfStock: ${productOrder.outOfStockQnty ?? 0}")
                ],
              ),
            ),
            Container(
              width: MediaQuery.of(context).size.width * 0.1,
              child: isScanned
                  ? Icon(
                      Icons.qr_code_scanner_sharp,
                    )
                  : SizedBox.shrink(),
            ),
            radio
          ],
        ),
      ),
    );
  }
}
