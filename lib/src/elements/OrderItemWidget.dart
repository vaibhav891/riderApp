import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../generated/l10n.dart';
import '../helpers/helper.dart';
import '../models/order.dart';
import '../models/route_argument.dart';

class OrderItemWidget extends StatefulWidget {
  final bool expanded;
  final Order order;
  final Function callback;

  OrderItemWidget({Key key, this.expanded, this.order, this.callback}) : super(key: key);

  @override
  _OrderItemWidgetState createState() => _OrderItemWidgetState();
}

class _OrderItemWidgetState extends State<OrderItemWidget> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).copyWith(dividerColor: Colors.transparent);
    return Stack(
      children: <Widget>[
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            Container(
              margin: EdgeInsets.only(top: 14),
              padding: EdgeInsets.only(top: 20, bottom: 5),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.9),
                boxShadow: [
                  BoxShadow(color: Theme.of(context).focusColor.withOpacity(0.1), blurRadius: 5, offset: Offset(0, 2)),
                ],
              ),
              child: Theme(
                data: theme,
                child: ExpansionTile(
                  initiallyExpanded: widget.expanded,
                  title: Column(
                    children: <Widget>[
                      Text('${S.of(context).order_id}: #${widget.order.increment_id}'),
                      Text(
                        widget.order.productOrders.isNotEmpty
                            ? 'Delivery Date: ${widget.order.productOrders.first.deliveryDate}'
                            : 'Delivery Date: ${widget.order.delivery_date}',
                        style: Theme.of(context).textTheme.caption,
                      ),
                      Text(
                        S.of(context).items + ':' + widget.order.productOrders?.length?.toString() ?? 0,
                        style: Theme.of(context).textTheme.caption,
                      ),
                    ],
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                  ),
                  trailing: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Helper.getPrice(Helper.getTotalOrdersPrice(widget.order), context,
                          style: Theme.of(context).textTheme.subtitle1),
                      Text(
                        '${widget.order.payment.method}',
                        style: Theme.of(context).textTheme.caption,
                      )
                    ],
                  ),
                  children: <Widget>[
                    // Column(
                    //     children: List.generate(
                    //   widget.order.productOrders.length,
                    //   (indexProduct) {
                    //     return ProductOrderItemWidget(
                    //         heroTag: 'mywidget.orders', order: widget.order, productOrder: widget.order.productOrders.elementAt(indexProduct));
                    //   },
                    // )),
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                      child: Column(
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: Text(
                                  S.of(context).delivery_fee,
                                  style: Theme.of(context).textTheme.bodyText1,
                                ),
                              ),
                              Helper.getPrice(widget.order.deliveryFee, context,
                                  style: Theme.of(context).textTheme.bodyText2)
                            ],
                          ),
                          // Row(
                          //   children: <Widget>[
                          //     Expanded(
                          //       child: Text(
                          //         '${S.of(context).tax} (${widget.order.tax}%)',
                          //         style: Theme.of(context).textTheme.bodyText1,
                          //       ),
                          //     ),
                          //     Helper.getPrice(Helper.getTaxOrder(widget.order), context,
                          //         style: Theme.of(context).textTheme.bodyText2)
                          //   ],
                          // ),
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: Text(
                                  S.of(context).total1,
                                  style: Theme.of(context).textTheme.bodyText1,
                                ),
                              ),
                              Helper.getPrice(Helper.getTotalOrdersPrice(widget.order), context,
                                  style: Theme.of(context).textTheme.subtitle2)
                            ],
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),
            Container(
              child: Wrap(
                alignment: WrapAlignment.end,
                children: <Widget>[
                  FlatButton(
                    onPressed: () {
                      //   //changed to add a popup for user to select if view or work on it
                      // Navigator.of(context).pushNamed('/OrderDetails', arguments: RouteArgument(id: widget.order.id));
                      Navigator.of(context)
                          .pushNamed('/OrderDetails',
                              arguments:
                                  RouteArgument(id: widget.order.id, param: [false, widget.order.actionRequired]))
                          .then((value) {
                        widget.callback();
                      });
                      //  _showDialog(context);
                    },
                    //  onPressed: () =>
                    //      Navigator.of(context).popAndPushNamed(
                    //    '/OrderDetails',
                    //    arguments: RouteArgument(id: widget.order.id, param: [false, widget.order.orderStatus.id]),
                    //  ),
                    textColor: Theme.of(context).hintColor,
                    child: Text("View Details"),
                    padding: EdgeInsets.symmetric(horizontal: 20),
                  ),
                ],
              ),
            ),
          ],
        ),
        Container(
          margin: EdgeInsetsDirectional.only(start: 20),
          padding: EdgeInsets.symmetric(horizontal: 10),
          height: 28,
          width: 140,
          decoration:
              BoxDecoration(borderRadius: BorderRadius.all(Radius.circular(100)), color: Theme.of(context).accentColor),
          alignment: AlignmentDirectional.center,
          child: Text(
            //'${widget.order.orderStatus.status}',
            getNextStatus() ?? "",
            maxLines: 1,
            style:
                Theme.of(context).textTheme.caption.merge(TextStyle(height: 1, color: Theme.of(context).primaryColor)),
          ),
        ),
      ],
    );
  }

  String getNextStatus() {
    if (widget.order.orderStatus.id == '1') {
      return "Order placed"; //"Preparing";
    } else if (widget.order.orderStatus.id == '2') {
      return "Start Picking";
      //"Ready to pickup";
    } else if (widget.order.orderStatus.id == '3') {
      //&& currentUser.value.role_id == 'driver') {
      return "End Picking";
      //"On the way";
    } else if (widget.order.orderStatus.id == '4') {
      //&& currentUser.value.role_id == 'driver') {
      return "Out for Delivery";
      //S.of(context).delivered;

    } else if (widget.order.orderStatus.id == '5') {
      //&& currentUser.value.role_id == 'driver') {
      return "Delivered";
      //S.of(context).delivered;

    } else if (widget.order.orderStatus.id == '6') {
      return "Action required";
    }
    return null;
  }

  // _showDialog(context) {
  //   return showDialog(
  //     context: context,
  //     builder: (context) => AlertDialog(
  //       title: Text('Select Action'.toUpperCase()),
  //       content: Text('Do you want to see the details or work on it?'),
  //       actions: [
  //         RaisedButton(
  //           color: Theme.of(context).accentColor,
  //           textColor: Theme.of(context).primaryColor,
  //           onPressed: () => Navigator.of(context).popAndPushNamed(
  //             '/OrderDetails',
  //             arguments: RouteArgument(id: widget.order.id, param: [true, widget.order.orderStatus.id]),
  //           ),
  //           child: Text('View details'),
  //         ),
  //         RaisedButton(
  //           color: Theme.of(context).accentColor,
  //           textColor: Theme.of(context).primaryColor,
  //           onPressed: () => Navigator.of(context).popAndPushNamed(
  //             '/OrderDetails',
  //             arguments: RouteArgument(id: widget.order.id, param: [false, widget.order.orderStatus.id]),
  //           ),
  //           child: Text('Work on it'),
  //         ),
  //         RaisedButton(
  //           onPressed: () => Navigator.of(context).pop(),
  //           child: Text('Cancel'),
  //         ),
  //       ],
  //     ),
  //   );
  // }
}
