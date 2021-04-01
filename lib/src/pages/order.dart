import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:markets_deliveryboy/src/helpers/custom_dialog_handler.dart';
import 'package:markets_deliveryboy/src/helpers/payment_method_dialog_handler.dart';
import 'package:markets_deliveryboy/src/models/order_status.dart';
import 'package:markets_deliveryboy/src/models/product.dart';
import 'package:markets_deliveryboy/src/models/product_order.dart';
import 'package:mvc_pattern/mvc_pattern.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:signature/signature.dart';
import '../../generated/l10n.dart';
import '../controllers/order_details_controller.dart';
import '../elements/CircularLoadingWidget.dart';
import '../elements/DrawerWidget.dart';
import '../elements/ProductOrderItemWidget.dart';
import '../elements/ShoppingCartButtonWidget.dart';
import '../helpers/helper.dart';
import '../models/route_argument.dart';
import '../repository/user_repository.dart';
import 'dart:convert';
import 'dart:ui';
import 'package:http/http.dart' as http;
import '../helpers/barcode_handler.dart';

class OrderWidget extends StatefulWidget {
  final RouteArgument routeArgument;

  OrderWidget({Key key, this.routeArgument}) : super(key: key);

  @override
  _OrderWidgetState createState() {
    return _OrderWidgetState();
  }
}

class _OrderWidgetState extends StateMVC<OrderWidget>
    with SingleTickerProviderStateMixin {
  bool _switchToProducts = true;

  OrderDetailsController _con;
  List<String> selectedProductOrders = [];
  static const int minSelectedQuantity = 0;
  ProductOrderFilter _filterDropdownValue = ProductOrderFilter.nonScanned;
  bool isView = true;
  bool workSelected = false;
  bool _submitted = false;
  bool editPressed = false;
  bool partialReject = false;
  //bool outOfStock = false;
  TextEditingController _textController = TextEditingController();
  Future<File> pdfFile;

  _OrderWidgetState() : super(OrderDetailsController()) {
    _con = controller;
  }
  final SignatureController _controller = SignatureController(
    penStrokeWidth: 5,
    penColor: Colors.red,
    exportBackgroundColor: Colors.blue,
  );

  List<ProductOrder> getFilteredProductOrders() {
    var filteredProductOrders = _con.order.productOrders.toList()
      ..sort((a, b) => (a.categoryId ?? 0).compareTo(b.categoryId ?? 0));
    switch (_filterDropdownValue) {
      case ProductOrderFilter.nonScanned:
        return filteredProductOrders
            .where((e) => ((e.inBagQty ?? 0) + (e.outOfStockQnty ?? 0) <
                double.parse(e.quantity).toInt()))
            .toList()
              ..sort(
                  (a, b) => (a.categoryId ?? 0).compareTo(b.categoryId ?? 0));

      case ProductOrderFilter.outOfStock:
        return filteredProductOrders
            .where((e) => (e.outOfStockQnty ?? 0) > 0)
            .toList()
              ..sort(
                  (a, b) => (a.categoryId ?? 0).compareTo(b.categoryId ?? 0));
      case ProductOrderFilter.all:
        return filteredProductOrders
          ..sort((a, b) => (a.categoryId ?? 0).compareTo(b.categoryId ?? 0));
      case ProductOrderFilter.scanned:
      default:
        return filteredProductOrders
            .where((e) => ((e.inBagQty ?? 0) + (e.outOfStockQnty ?? 0) >=
                double.parse(e.quantity).toInt()))
            .toList()
              ..sort(
                  (a, b) => (a.categoryId ?? 0).compareTo(b.categoryId ?? 0));
    }
  }

  @override
  void initState() {
    super.initState();
    isView = widget.routeArgument.param[0];
    _con.listenForOrder(id: widget.routeArgument.id);
    pdfFile = _con.getInvoicePdf(widget.routeArgument.id);
    _submitted = widget.routeArgument.param[1] == 1;
    _filterDropdownValue = currentUser.value.role_id == 'driver'
        ? ProductOrderFilter.all
        : _filterDropdownValue;
  }

  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    //outOfStock = ;
    return Scaffold(
      key: _con.scaffoldKey,
      drawer: DrawerWidget(),
      // floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      // floatingActionButton: _con.isPickerStatus()
      //     ? FloatingActionButton(
      //         onPressed: () async {
      //           await _onScanPressed();
      //         },
      //         child: Text('Scan'),
      //       )
      //     : null,
      bottomNavigationBar: isView
          ? Container(
              height: 80,
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.only(
                      topRight: Radius.circular(20),
                      topLeft: Radius.circular(20)),
                  boxShadow: [
                    BoxShadow(
                        color: Theme.of(context).focusColor.withOpacity(0.15),
                        offset: Offset(0, -2),
                        blurRadius: 5.0)
                  ]),
              child: CustomRoundButton(
                text: 'Start picking',
                width: MediaQuery.of(context).size.width * 0.4,
                onPressed: () {
                  setState(() {
                    isView = false;
                    workSelected = true;
                  });
                },
              ),
            )
          : _buildBottomBar(),
      body: _buildBody(),
    );
  }

  List<ProductOrder> getSelectedProductOrders() {
    return selectedProductOrders
        .map((e) =>
            _con.order.productOrders.firstWhere((element) => element.id == e))
        .toList();
  }

  Future _onScanPressed() async {
//check the order status.. allow scan only if order assigned/accepted
    if (_con.order.orderStatus.id != '2') {
      _con.orderStatusSnackbar();
      return;
    }
    if (!await Permission.camera.request().isGranted) {
      print('No camera permissions');
      _con.noCameraPermissionsSnackbar();
      return;
    }
    String barcode = await BarcodeHandler.scanBarcode(context);
    String orderId = _con.order.id;
    //
    // String barcode = '4084500190917';
    // String orderId = '33';

    if (barcode == null || orderId == null) {
      return;
    }
    print('barcode: $barcode, orderId: $orderId');
    var _customDialogHandler = CustomDialogHandler();
    _customDialogHandler.show(context);
    List productFromBarcodeList = await _con.getProductDetails(
        orderId: orderId ?? '', barcode: barcode ?? '');
    _customDialogHandler.hide();
    var productFromBarcode;
    if (productFromBarcodeList != null && productFromBarcodeList.length > 0) {
      productFromBarcode = productFromBarcodeList?.first;
    }
    if (productFromBarcode == null) {
      _con.productNotFoundSnackbar();
      return;
    }
    ProductOrder _scannedProductOrder = new ProductOrder(
      product: Product(id: productFromBarcode['item_id']),
      id: productFromBarcode['order_id'],
      name: productFromBarcode['name'],
      quantity: productFromBarcode['qty'],
      selectedQuantity: productFromBarcode['changeqty'],
      price: productFromBarcode['price'],
      isScanned: true,
    );
    print(_scannedProductOrder.toMap());
    if (_scannedProductOrder != null) {
      int qtyFromDialog = await _showDetailsDialog(_scannedProductOrder) ?? -1;
      print(qtyFromDialog);
    }
  }

  Future _showDetailsDialog(ProductOrder productOrder) {
    int selectedQuantity = double.parse(productOrder.selectedQuantity).toInt();
    //int selectedQuantity = double.parse(productOrder.quantity).toInt();
    return showDialog(
        context: context,
        builder: (dialogContext) {
          return StatefulBuilder(builder: (context, StateSetter stateSetter) {
            return SimpleDialog(
              title: Text('Scanned Details'),
              children: [
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(
                            color: Colors.grey,
                            width: 2,
                          ),
                        ),
                        padding: EdgeInsets.all(12.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Title'),
                                  Text(productOrder?.name ?? 'none')
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Quantity'),
                                Text(productOrder?.quantity ?? '')
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text('Add'),
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(1),
                                    border: Border.all(
                                      color: Colors.grey,
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      GestureDetector(
                                          child: Icon(
                                            Icons.arrow_drop_up,
                                            size: 30,
                                          ),
                                          onTap: () {
                                            print('up');
                                            final maxQuantity = Helper.toDouble(
                                                productOrder?.quantity);
                                            if (selectedQuantity <
                                                maxQuantity.toInt()) {
                                              stateSetter(() {
                                                ++selectedQuantity;
                                              });
                                            }
                                          }),
                                      Text(selectedQuantity.toString()),
                                      GestureDetector(
                                          child: Icon(
                                            Icons.arrow_drop_down,
                                            size: 30,
                                          ),
                                          onTap: () {
                                            print('down');
                                            if (selectedQuantity >
                                                minSelectedQuantity) {
                                              stateSetter(() {
                                                --selectedQuantity;
                                              });
                                            }
                                          }),
                                    ],
                                  ),
                                )
                              ],
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 20.0),
                      ),
                      CustomRoundButton(
                          onPressed: () {
                            _con.addProductOrder(
                                productOrder, selectedQuantity);
                            Navigator.pop(dialogContext, selectedQuantity);
                          },
                          text: 'Submit'),
                    ],
                  ),
                ),
              ],
            );
          });
        });
  }

  Future _showActionReq() {
    //int selectedQuantity = minSelectedQuantity;
    return showDialog(
        context: context,
        builder: (dialogContext) {
          return StatefulBuilder(builder: (context, StateSetter stateSetter) {
            return AlertDialog(
              title: Text('Action Required'.toUpperCase()),
              content: TextField(
                decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Input action required',
                    labelStyle: TextStyle(fontSize: 12, color: Colors.orange)),
                controller: _textController,
                maxLines: 5,
              ),
              actions: <Widget>[
                // usually buttons at the bottom of the dialog
                FlatButton(
                  child: new Text(S.of(context).submit),
                  onPressed: () async {
                    //_con.doDeliveredOrder(_con.order);
                    _con.doActionOrder(_con.order);
                    if (_textController.text.isEmpty) {
                      return _con.contentEmptySnackbar();
                    }
                    _con.submitActoinRequired(
                        _con.order.id, _textController.text);
                    stateSetter(() {
                      _submitted = true;
                    });
                    Navigator.of(context).pop();
                  },
                ),
                FlatButton(
                  child: new Text(S.of(context).cancel),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          });
        });
  }

  void addToBag(String orderId) async {
    if (!_con.confirmProductsSelection(getSelectedProductOrders())) {
      return;
    }
    if (!_con.confirmProductsQuantity(getSelectedProductOrders())) {
      return;
    }
    final CustomDialogHandler _customDialogHandler = CustomDialogHandler();
    _customDialogHandler.show(context);
    await _con.addProductsToBag(
        getSelectedProductOrders()?.map((e) => e)?.toList(), orderId);
    _customDialogHandler.hide();
    // int value = _con.order.productOrders.fold<int>(
    //     0,
    //     (previousValue, element) =>
    //         previousValue + double.parse(element.quantity).toInt());
    // int value2 = _con.order.productOrders.fold<int>(
    //     0, (previousValue, element) => previousValue + (element.inBagQty ?? 0));
    int value3 = _con.order.productOrders.fold<int>(
        0,
        (previousValue, element) =>
            previousValue + (element.outOfStockQnty ?? 0));
    if (/*value <= value2 + value3 && */ value3 > 0 &&
        _con.order.orderStatus.id == '2') {
      setState(() {
        _con.order.orderStatus = OrderStatus.fromJSON({
          'id': '21',
          'status': 'Submit_Action_required',
        });
      });
    }
    return;
  }

  // void markAsOutOfStock(String orderId) async {
  //   if (!_con.confirmProductsSelection(getSelectedProductOrders())) {
  //     return;
  //   }
  //   final CustomDialogHandler _customDialogHandler = CustomDialogHandler();
  //   _customDialogHandler.show(context);
  //   await _con.markedAsOutOfStock(
  //       getSelectedProductOrders()?.map((e) => e)?.toList(), orderId);
  //   _customDialogHandler.hide();
  //   int value = _con.order.productOrders.fold<int>(
  //       0,
  //       (previousValue, element) =>
  //           previousValue + double.parse(element.quantity).toInt());
  //   int value2 = _con.order.productOrders.fold<int>(
  //       0, (previousValue, element) => previousValue + (element.inBagQty ?? 0));
  //   int value3 = _con.order.productOrders.fold<int>(
  //       0,
  //       (previousValue, element) =>
  //           previousValue + (element.outOfStockQnty ?? 0));
  //   if (value <= value2 + value3 && value3 > 0) {
  //     setState(() {
  //       _con.order.orderStatus = OrderStatus.fromJSON({
  //         'id': '6',
  //         'status': 'Action_required',
  //       });
  //     });
  //   }

  //   return;
  // }

  void rejectProductOrdersPartial(String orderId, String driverId) async {
    if (!_con.confirmProductsSelection(getSelectedProductOrders())) {
      return;
    }
    final CustomDialogHandler _customDialogHandler = CustomDialogHandler();
    _customDialogHandler.show(context);
    await _con.rejectProductOrdersPartial(
        getSelectedProductOrders()?.map((e) => e)?.toList(), orderId, driverId);
    _customDialogHandler.hide();
    return;
  }

  rejectProductOrdersFull(String orderId, String driverId) async {
    // if (!_con.confirmProductsSelection(getSelectedProductOrders())) {
    //   return;
    // }
    final CustomDialogHandler _customDialogHandler = CustomDialogHandler();
    _customDialogHandler.show(context);
    await _con.rejectProductOrdersFull(orderId, driverId);
    _customDialogHandler.hide();
    return;
  }

  ProductOrder getDummyProductOrder() => ProductOrder(
        product: Product(id: '1'),
        id: _con.order.id,
        name: 'Samsung TV',
        quantity: '10',
        price: '2000',
      );

  void deliveredPressed() {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(S.of(context).delivery_confirmation),
            content: Signature(
              height: MediaQuery.of(context).size.height * 0.5,
              width: MediaQuery.of(context).size.width * 0.5,
              controller: _controller,
              backgroundColor: Colors.lightBlueAccent,
            ),
            actions: <Widget>[
              // usually buttons at the bottom of the dialog
              FlatButton(
                child: new Text(S.of(context).confirm),
                onPressed: () async {
                  if (_controller.isNotEmpty) {
                    var byteData = await _controller.toPngBytes();
                    var bs64 = base64Encode(byteData);
                    var uri = Uri.parse(
                        "http://ajmanmarkets.apntbs.com/api/signature.php");
                    //var response =
                    await http.post(uri, body: {
                      'image': bs64,
                      'order_id': _con.order.id,
                    });

                    // if (response.statusCode == 200) {
                    //   print("image upload");
                    // } else {
                    //   print("image failed");
                    // }
                  }
                  _con.doDeliveredOrder(_con.order);
                  Navigator.of(context).pop();
                },
              ),
              FlatButton(
                child: new Text(S.of(context).dismiss),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              FlatButton(
                child: new Text('Clear'),
                color: Colors.red,
                onPressed: () {
                  setState(() => _controller.clear());
                },
              ),
            ],
          );
        });
  }

  void preparingPressed() {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Confirm'),
            content:
                Text('Are you sure you want to assign this order to yourself?'),
            actions: <Widget>[
              // usually buttons at the bottom of the dialog
              FlatButton(
                child: new Text(S.of(context).confirm),
                onPressed: () async {
                  //_con.doDeliveredOrder(_con.order);
                  _con.doPreparingOrder(_con.order);
                  Navigator.of(context).pop();
                },
              ),
              FlatButton(
                child: new Text(S.of(context).cancel),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        });
  }

  void rejectedPressed() async {
    if (!partialReject) {
      showModalBottomSheet(
        context: context,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
          top: Radius.circular(40),
          //bottom: Radius.circular(80),
        )),
        builder: (context) => Container(
            height: 150,
            child: Column(
              children: [
                SizedBox(
                  height: 12,
                ),
                ListTile(
                  leading: Icon(Icons.wysiwyg_rounded),
                  title: Text("Full reject"),
                  onTap: () async {
                    print('full reject pressed');
                    await rejectProductOrdersFull(
                        _con.order.id, _con.order.driverId);
                    Navigator.of(context).pop();
                  },
                ),
                ListTile(
                  leading: Icon(Icons.wysiwyg_rounded),
                  title: Text("Partial reject"),
                  onTap: () {
                    Navigator.of(context).pop();
                    setState(() {
                      partialReject = true;
                    });
                    // ReasonForRejection reasonForRejection = await _showRejectedDialog();
                    // print(reasonForRejection);
                  },
                ),
              ],
            )),
      );
    } else {
      setState(() {
        partialReject = false;
      });

      //rejectProductOrdersPartial(_con.order.id, _con.order.driverId);
    }
  }

  // Future _showRejectedDialog() async {
  //   ReasonForRejection _dropDownValue = ReasonForRejection.damagedPoduct;
  //   return showDialog(
  //       context: context,
  //       builder: (dialogContext) {
  //         return StatefulBuilder(builder: (context, StateSetter stateSetter) {
  //           return SimpleDialog(
  //             title: Center(child: Text('Reason for rejection')),
  //             children: [
  //               Column(
  //                 mainAxisSize: MainAxisSize.min,
  //                 children: [
  //                   Container(
  //                       decoration: BoxDecoration(
  //                         borderRadius: BorderRadius.circular(5),
  //                         border: Border.all(
  //                           color: Colors.grey,
  //                           width: 2,
  //                         ),
  //                       ),
  //                       padding: EdgeInsets.symmetric(horizontal: 16.0),
  //                       child: Container(
  //                         child: DropdownButton(
  //                           value: _dropDownValue,
  //                           onChanged: (newVal) {
  //                             stateSetter(() {
  //                               _dropDownValue = newVal;
  //                             });
  //                           },
  //                           items: ReasonForRejection.values
  //                               .map((e) => DropdownMenuItem(
  //                                     child: Padding(
  //                                       padding: const EdgeInsets.only(right: 36.0),
  //                                       child: Text(Helper.reasonForRejectionValues[e]),
  //                                     ),
  //                                     value: e,
  //                                   ))
  //                               .toList(),
  //                         ),
  //                       )),
  //                   Padding(
  //                     padding: EdgeInsets.symmetric(vertical: 10.0),
  //                   ),
  //                   Container(
  //                     margin: EdgeInsets.symmetric(horizontal: 20.0),
  //                     child: Row(
  //                       mainAxisAlignment: MainAxisAlignment.center,
  //                       crossAxisAlignment: CrossAxisAlignment.center,
  //                       children: [
  //                         Text(
  //                           'Quantity',
  //                           style: Theme.of(context).textTheme.subtitle1,
  //                         ),
  //                         Container(
  //                             padding: EdgeInsets.symmetric(horizontal: 8.0),
  //                             width: MediaQuery.of(context).size.width * 0.3,
  //                             height: 30,
  //                             child: TextField(
  //                               decoration:
  //                                   InputDecoration(border: OutlineInputBorder(borderSide: BorderSide(width: 2))),
  //                               inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly],
  //                             ))
  //                       ],
  //                     ),
  //                   ),
  //                   Padding(
  //                     padding: EdgeInsets.symmetric(vertical: 15.0),
  //                   ),
  //                   CustomRoundButton(
  //                       onPressed: () {
  //                         Navigator.pop(dialogContext, _dropDownValue);
  //                       },
  //                       text: 'Submit'),
  //                 ],
  //               ),
  //             ],
  //           );
  //         });
  //       });
  // }

  _buildBottomBar() {
    return _con.order == null
        ? Container(
            height: 193,
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.only(
                    topRight: Radius.circular(20),
                    topLeft: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                      color: Theme.of(context).focusColor.withOpacity(0.15),
                      offset: Offset(0, -2),
                      blurRadius: 5.0)
                ]),
            child: SizedBox(
              width: MediaQuery.of(context).size.width - 40,
            ),
          )
        : Container(
            height: _con.isPickerStatus() ||
                    _con.order.orderStatus.id == '6' ||
                    _con.order.orderStatus.id == '4'
                ? 80 //120
                : _con.isDelivererStatus()
                    ? 120
                    : _con.order.orderStatus.id == '5'
                        ? 60
                        : 80,
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.only(
                    topRight: Radius.circular(20),
                    topLeft: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                      color: Theme.of(context).focusColor.withOpacity(0.15),
                      offset: Offset(0, -2),
                      blurRadius: 5.0)
                ]),
            child: SizedBox(
              width: MediaQuery.of(context).size.width - 40,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.max,
                children: <Widget>[
                  _con.isPickerStatus() //|| !_submitted
                      ? Container(
                          // margin: EdgeInsets.only(left: 8.0, right: 8.0, bottom: 4.0),
                          // child: Row(
                          //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          //   children: [
                          //     CustomRoundButton(
                          //       text: 'Add to bag',
                          //       width: MediaQuery.of(context).size.width * 0.4,
                          //       onPressed: () {
                          //         addToBag(_con.order.id);
                          //       },
                          //     ),
                          //     CustomRoundButton(
                          //       text: 'Out of Stock',
                          //       width: MediaQuery.of(context).size.width * 0.4,
                          //       onPressed: () {
                          //         markAsOutOfStock(_con.order.id);
                          //       },
                          //     ),
                          //   ],
                          // ),
                          )
                      : currentUser.value.role_id == 'driver' &&
                              _con.isDelivererStatus()
                          ? Container(
                              margin: EdgeInsets.only(
                                  left: 8.0, right: 8.0, bottom: 4.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CustomRoundButton(
                                    text: 'Delivered',
                                    width:
                                        MediaQuery.of(context).size.width * 0.4,
                                    onPressed: () {
                                      deliveredPressed();
                                    },
                                  ),
                                  if (!partialReject) SizedBox(width: 10),
                                  if (!partialReject)
                                    CustomRoundButton(
                                      text: 'Rejected',
                                      width: MediaQuery.of(context).size.width *
                                          0.4,
                                      onPressed: () {
                                        rejectedPressed();
                                      },
                                    ),
                                ],
                              ),
                            )
                          : SizedBox.shrink(),
                  SizedBox(height: 5),
                  _con.order.orderStatus.id == '1'
                      ? CustomRoundButton(
                          text: "Start Picking",
                          onPressed: () => workSelected
                              ? _con.doPreparingOrder(_con.order)
                              : preparingPressed(),
                          width: MediaQuery.of(context).size.width * 0.85,
                        )
                      : SizedBox(height: 0),
                  _con.order.orderStatus.id == '2'
                      ? CustomRoundButton(
                          text: "End Picking",
                          onPressed: () {
                            _con.doReadyOrder(_con.order);
                            //Navigator.of(context).pop();
                          },
                          width: MediaQuery.of(context).size.width * 0.85,
                        )
                      : SizedBox(height: 0),
                  _con.order.orderStatus.id == '3' &&
                          currentUser.value.role_id == 'driver'
                      ? CustomRoundButton(
                          text: 'On the way',
                          onPressed: () {
                            _con.doOnthewayOrder(_con.order);
                          },
                          width: MediaQuery.of(context).size.width * 0.85,
                        )
                      : SizedBox(height: 0),
                  // _con.order.orderStatus.id == '4' && currentUser.value.role_id == 'driver'
                  //     ? CustomRoundButton(
                  //         text: S.of(context).delivered,
                  //         onPressed: () {
                  //           deliveredPressed();
                  //         },
                  //         width: MediaQuery.of(context).size.width * 0.85,
                  //       )
                  //     : SizedBox(height: 0),
                  _con.order.orderStatus.id ==
                          '21' //&& currentUser.value.role_id == 'picker'
                      ? CustomRoundButton(
                          text: 'Action Required',
                          width: MediaQuery.of(context).size.width * 0.85,
                          onPressed: _submitted
                              ? null
                              : () async {
                                  //addToBag(_con.order.id);
                                  await _showActionReq();
                                  Navigator.of(context).pop();
                                },
                        )
                      : SizedBox(height: 0),
                  _con.order.orderStatus.id ==
                          '20' //&& currentUser.value.role_id == 'picker'
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            CustomRoundButton(
                              text: 'Not collected',
                              width: MediaQuery.of(context).size.width * 0.44,
                              onPressed: () async {
                                _con.doNotCollectedOrder(_con.order);
                                Navigator.of(context).pop();
                              },
                            ),
                            CustomRoundButton(
                              text: 'Collected',
                              width: MediaQuery.of(context).size.width * 0.44,
                              onPressed: () async {
                                _con.doCollectedOrder(_con.order);
                                Navigator.of(context).pop();
                              },
                            ),
                          ],
                        )
                      : SizedBox(height: 0),
                ],
              ),
            ),
          );
  }

  _buildBody() => _con.order == null
      ? CircularLoadingWidget(height: MediaQuery.of(context).size.height)
      : CustomScrollView(slivers: <Widget>[
          _buildSliverAppBar(),
          //_buildProductsCustomerContainer(),
        ]);

  // _buildProductsCustomerContainer() {
  //   return SliverToBoxAdapter(
  //     child: SliverList(
  //       delegate: SliverChildListDelegate([]),
  //     ),
  //   );
  // }

  _buildSliverAppBar() {
    return SliverAppBar(
      snap: true,
      floating: true,
      automaticallyImplyLeading: false,
      leading: new IconButton(
        icon: new Icon(Icons.sort, color: Theme.of(context).hintColor),
        onPressed: () => _con.scaffoldKey?.currentState?.openDrawer(),
      ),
      centerTitle: true,
      title: Text(
        S.of(context).order_details,
        style: Theme.of(context)
            .textTheme
            .headline6
            .merge(TextStyle(letterSpacing: 1.3)),
      ),
      actions: <Widget>[
        currentUser.value.role_id == 'picker'
            ? SizedBox(
                width: 50,
                child: FlatButton(
                  onPressed: () async {
                    await _onScanPressed();
                  },
                  child: Icon(Icons.qr_code_scanner_outlined),
                ),
              )
            : Container(),
        IconButton(
          visualDensity: VisualDensity(horizontal: -4, vertical: -4),
          onPressed: () {
            showModalBottomSheet(
              isScrollControlled: true,
              shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(12))),
              context: context,
              builder: (context) {
                return FutureBuilder<File>(
                    future: pdfFile,
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Container(
                            height: MediaQuery.of(context).size.height * 0.9,
                            child: Center(
                                child: Text(
                                    'Could not generate invoice at this time')));
                      }
                      if (snapshot.hasData)
                        return Container(
                          height: MediaQuery.of(context).size.height * 0.9,
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(40)),
                          child: PdfPreview(
                            build: (format) => snapshot.data
                                .readAsBytes(), // _generatePdf(format, "this is test page"),
                          ),
                        );
                    });
              },
            );
          },
          icon: Icon(Icons.print_rounded),
        ),
        new ShoppingCartButtonWidget(
            iconColor: Theme.of(context).hintColor,
            labelColor: Theme.of(context).accentColor),
      ],
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      expandedHeight: MediaQuery.of(context).size.height, // * 0.9,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        // collapseMode: CollapseMode.pin,
        background: Container(
          margin: EdgeInsets.only(top: 85),
          padding: EdgeInsets.symmetric(horizontal: 5, vertical: 15),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.9),
            boxShadow: [
              BoxShadow(
                  color: Theme.of(context).focusColor.withOpacity(0.1),
                  blurRadius: 5,
                  offset: Offset(0, 2)),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Flexible(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  S.of(context).order_id +
                                      ": #${_con.order.increment_id}",
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2,
                                  style: Theme.of(context).textTheme.headline4,
                                ),
                                getNextStatus() != null
                                    ? Text(
                                        // \//\ updated to reflect correct status
                                        //_con.order.orderStatus.status,
                                        getNextStatus() ?? '',
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 2,
                                        style:
                                            Theme.of(context).textTheme.caption,
                                      )
                                    : Container(),
                                Text(
                                  _con.order.productOrders.isNotEmpty
                                      ? 'Delivery Date: ${_con.order.productOrders.first.deliveryDate}'
                                      : 'Delivery Date: ${_con.order.delivery_date}',
                                  //  DateFormat('yyyy-MM-dd HH:mm').format(_con.order.dateTime),
                                  style: Theme.of(context).textTheme.caption,
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 8),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: <Widget>[
                              Helper.getPrice(
                                  Helper.getTotalOrdersPrice(_con.order),
                                  context,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headline4
                                      .copyWith(fontSize: 16)),
                              Row(
                                children: [
                                  if (currentUser.value.role_id == 'driver')
                                    GestureDetector(
                                      onTap: () {
                                        final PaymentMethodDialogHandler
                                            _paymentMethodDialogHandler =
                                            PaymentMethodDialogHandler();
                                        _paymentMethodDialogHandler
                                            .show(context);
                                      },
                                      child: Text(
                                        "Edit",
                                        style: TextStyle(
                                          color: Theme.of(context).accentColor,
                                          fontWeight: FontWeight.bold,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                    ),
                                  SizedBox(
                                    width: 4.0,
                                  ),
                                  Text(
                                    _con.order.payment?.method ??
                                        S.of(context).cash_on_delivery,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 2,
                                    style: Theme.of(context).textTheme.caption,
                                  ),
                                ],
                              ),
                              Text(
                                S.of(context).items +
                                        ':' +
                                        _con.order.productOrders?.length
                                            ?.toString() ??
                                    0,
                                style: Theme.of(context).textTheme.caption,
                              ),
                            ],
                          ),
                        ],
                      ),
                    )
                  ],
                ),
                Divider(height: 10),
                ExpansionTile(
                  title: Text(
                    //_con.order?.orderStatus?.status ?? '',
                    getNextStatus() ?? "", overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                    style: Theme.of(context).textTheme.headline4,
                  ),
                  children: [
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            S.of(context).subtotal,
                            style: Theme.of(context).textTheme.bodyText1,
                          ),
                        ),
                        Helper.getPrice(
                            Helper.getSubTotalOrdersPrice(_con.order), context,
                            style: Theme.of(context).textTheme.bodyText2)
                      ],
                    ),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            S.of(context).delivery_fee,
                            style: Theme.of(context).textTheme.bodyText1,
                          ),
                        ),
                        Helper.getPrice(_con.order.deliveryFee, context,
                            style: Theme.of(context).textTheme.bodyText2)
                      ],
                    ),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            '${S.of(context).tax} (${Helper.stringToStringFixed(_con.order.tax, 2)}%)',
                            style: Theme.of(context).textTheme.bodyText1,
                          ),
                        ),
                        Helper.getPrice(Helper.getTaxOrder(_con.order), context,
                            style: Theme.of(context).textTheme.bodyText2)
                      ],
                    ),
                    Divider(height: 10),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            S.of(context).total,
                            style: Theme.of(context).textTheme.headline6,
                          ),
                        ),
                        Helper.getPrice(
                            Helper.getTotalOrdersPrice(_con.order), context,
                            style: Theme.of(context)
                                .textTheme
                                .headline6
                                .copyWith(fontSize: 15))
                      ],
                    ),
                    Divider(height: 5),
                    Container(
                      width: MediaQuery.of(context).size.width * 0.6,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_switchToProducts ? 'Products' : 'Customer',
                              style: Theme.of(context).textTheme.subtitle1),
                          Switch(
                            value: _switchToProducts,
                            onChanged: (val) {
                              setState(() {
                                _switchToProducts = val;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    currentUser.value.role_id == 'picker'
                        ? Offstage(
                            offstage: !_switchToProducts,
                            child: Container(
                              child: DropdownButton(
                                value: _filterDropdownValue,
                                onChanged: (newVal) {
                                  setState(() {
                                    _filterDropdownValue = newVal;
                                  });
                                },
                                items: ProductOrderFilter.values
                                    .map((e) => DropdownMenuItem(
                                          child: Padding(
                                            padding: const EdgeInsets.only(
                                                right: 36.0),
                                            child: Text(Helper
                                                .productOrderFilterValues[e]),
                                          ),
                                          value: e,
                                        ))
                                    .toList(),
                              ),
                            ),
                          )
                        : Container(),
                    Offstage(
                      offstage: !_switchToProducts,
                      child: ListView.separated(
                        padding: EdgeInsets.only(top: 20, bottom: 20),
                        scrollDirection: Axis.vertical,
                        shrinkWrap: true,
                        primary: false,
                        itemCount: getFilteredProductOrders()?.length ?? 0,
                        separatorBuilder: (context, index) {
                          return Divider(
                            color: Colors.grey,
                          );
                        },
                        itemBuilder: (context, index) {
                          final productOrder =
                              getFilteredProductOrders().elementAt(index);
                          var selectedQuantity =
                              minSelectedQuantity; //double.parse(productOrder.quantity).toInt();
                          Widget counter = StatefulBuilder(
                            builder: (BuildContext context, setState) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  //Text('Add'),
                                  Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(1),
                                      border: Border.all(
                                        color: Colors.grey,
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        GestureDetector(
                                            child: Icon(
                                              Icons.arrow_drop_up,
                                              size: 30,
                                            ),
                                            onTap: () {
                                              print('up');
                                              final maxQuantity =
                                                  Helper.toDouble(
                                                      productOrder?.quantity);
                                              if (selectedQuantity <
                                                  maxQuantity.toInt()) {
                                                setState(() {
                                                  ++selectedQuantity;
                                                });
                                              }
                                            }),
                                        Text(selectedQuantity.toString()),
                                        GestureDetector(
                                            child: Icon(
                                              Icons.arrow_drop_down,
                                              size: 30,
                                            ),
                                            onTap: () {
                                              print('down');
                                              if (selectedQuantity >
                                                  minSelectedQuantity) {
                                                setState(() {
                                                  --selectedQuantity;
                                                });
                                              }
                                            }),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      if (!partialReject)
                                        IconButton(
                                          padding: EdgeInsets.all(0),
                                          visualDensity: VisualDensity(
                                              horizontal: -4.0, vertical: -4.0),
                                          icon: Icon(Icons.shopping_bag),
                                          onPressed: () {
                                            //setState(() {
                                            productOrder.selectedQuantity =
                                                selectedQuantity.toString();
                                            //});
                                            // call the add to bag function
                                            selectedProductOrders.clear();
                                            selectedProductOrders
                                                .add(productOrder.id);
                                            addToBag(_con.order.id);
                                          },
                                        ),
                                      if (partialReject)
                                        IconButton(
                                          padding: EdgeInsets.all(0),
                                          visualDensity: VisualDensity(
                                              horizontal: -4.0, vertical: -4.0),
                                          icon: Icon(Icons.highlight_off),
                                          onPressed: () {
                                            //setState(() {
                                            productOrder.selectedQuantity =
                                                selectedQuantity.toString();
                                            //});
                                            // call the out of stock function
                                            selectedProductOrders.clear();
                                            selectedProductOrders
                                                .add(productOrder.id);
                                            rejectProductOrdersPartial(
                                                _con.order.id,
                                                _con.order.driverId);
                                          },
                                        ),
                                    ],
                                  )
                                  // Checkbox(
                                  //   value: selectedProductOrders.contains(_con.order.productOrders.elementAt(index).id),
                                  //   onChanged: _con.order.orderStatus.id == '1'
                                  //       ? null
                                  //       : (newval) {
                                  //           setState(() {
                                  //             _con.order.productOrders.elementAt(index).selectedQuantity =
                                  //                 selectedQuantity.toString();
                                  //             newval
                                  //                 ? selectedProductOrders.add(_con.order.productOrders.elementAt(index).id)
                                  //                 : selectedProductOrders.remove(_con.order.productOrders.elementAt(index).id);
                                  //           });
                                  //         },
                                  // ),
                                ],
                              );
                            },
                          );

                          return ProductOrderItemWidget(
                            heroTag: 'my_orders',
                            order: _con.order,
                            isScanned: partialReject
                                ? false
                                : productOrder
                                    .isScanned, //getFilteredProductOrders().elementAt(index).isScanned,
                            productOrder:
                                productOrder, //getFilteredProductOrders().elementAt(index),
                            radio: Theme(
                              data:
                                  ThemeData(unselectedWidgetColor: Colors.blue),
                              child: double.parse(productOrder.quantity)
                                              .toInt() !=
                                          (productOrder.inBagQty ?? 0) +
                                              (productOrder.outOfStockQnty ??
                                                  0) &&
                                      (_con.order.orderStatus.id == '2' ||
                                          _con.order.orderStatus.id == '21')
                                  ? counter
                                  : !(editPressed || partialReject)
                                      ? IconButton(
                                          icon: Icon(Icons.edit),
                                          onPressed: () {
                                            print('editPressed');
                                            if (_con.order.orderStatus.id ==
                                                '2')
                                              setState(() {
                                                editPressed = true;
                                              });
                                          },
                                        )
                                      : counter,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                Offstage(
                  offstage: _switchToProducts,
                  child: Column(
                    children: <Widget>[
                      SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 7),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    'Fullname',
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context).textTheme.caption,
                                  ),
                                  Text(
                                    _con.order.customername,
                                    style:
                                        Theme.of(context).textTheme.bodyText1,
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 20),
                            SizedBox(
                              width: 42,
                              height: 42,
                              child: FlatButton(
                                padding: EdgeInsets.all(0),
                                disabledColor: Theme.of(context)
                                    .focusColor
                                    .withOpacity(0.4),
                                onPressed: null,
                                // onPressed: () {
                                //  Navigator.of(context).pushNamed('/Profile',
                                //      arguments: new RouteArgument(param: _con.order.deliveryAddress));
                                // },
                                child: Icon(
                                  Icons.person,
                                  color: Theme.of(context).primaryColor,
                                  size: 24,
                                ),
                                color: Theme.of(context)
                                    .accentColor
                                    .withOpacity(0.9),
                                shape: StadiumBorder(),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 7),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    S.of(context).deliveryAddress,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context).textTheme.caption,
                                  ),
                                  Text(
                                    _con.order.deliveryAddress != null
                                        ? '${_con.order.deliveryAddress.street}, ${_con.order.deliveryAddress.city}, ${_con.order.deliveryAddress.address}'
                                        : S
                                            .of(context)
                                            .address_not_provided_please_call_the_client,
                                    style:
                                        Theme.of(context).textTheme.bodyText1,
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 20),
                            SizedBox(
                              width: 42,
                              height: 42,
                              child: FlatButton(
                                padding: EdgeInsets.all(0),
                                disabledColor: Theme.of(context)
                                    .focusColor
                                    .withOpacity(0.4),
                                onPressed: () async {
                                  String googleUrl =
                                      // "https://www.google.com/maps/dir/?api=1&destination=18.565426,73.786262";
                                      "https://www.google.com/maps/dir/?api=1&destination=${_con.order.deliveryAddress.latitude},${_con.order.deliveryAddress.longitude}";
                                  String appleUrl =
                                      'https://maps.apple.com/?daddr=${_con.order.deliveryAddress.latitude},${_con.order.deliveryAddress.longitude}';
                                  // 'https://maps.apple.com/?daddr=18.565426,73.786262';
                                  if (await canLaunch(googleUrl)) {
                                    print('launching com googleUrl');
                                    await launch(googleUrl);
                                  } else if (await canLaunch(appleUrl)) {
                                    print('launching apple url');
                                    await launch(appleUrl);
                                  } else {
                                    throw 'Could not launch url';
                                  }
                                },
                                // {
                                //   Navigator.of(context)
                                //       .pushNamed('/Pages', arguments: new RouteArgument(id: '3', param: _con.order));
                                // },
                                child: Icon(
                                  Icons.directions,
                                  color: Theme.of(context).primaryColor,
                                  size: 24,
                                ),
                                color: Theme.of(context)
                                    .accentColor
                                    .withOpacity(0.9),
                                shape: StadiumBorder(),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 7),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    S.of(context).phoneNumber,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context).textTheme.caption,
                                  ),
                                  Text(
                                    _con.order?.deliveryAddress?.phone ?? "",
                                    overflow: TextOverflow.ellipsis,
                                    style:
                                        Theme.of(context).textTheme.bodyText1,
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 10),
                            SizedBox(
                              width: 42,
                              height: 42,
                              child: FlatButton(
                                padding: EdgeInsets.all(0),
                                onPressed: () {
                                  launch(
                                      "tel:${_con.order.deliveryAddress.phone}");
                                },
                                child: Icon(
                                  Icons.call,
                                  color: Theme.of(context).primaryColor,
                                  size: 24,
                                ),
                                color: Theme.of(context)
                                    .accentColor
                                    .withOpacity(0.9),
                                shape: StadiumBorder(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: _con.isDelivererStatus() ? 135 : 95,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String getNextStatus() {
    if (_con.order.orderStatus.id == '1') {
      return "Order placed"; //"Preparing";
    } else if (_con.order.orderStatus.id == '2') {
      return "Start Picking";
      //"Ready to pickup";
    } else if (_con.order.orderStatus.id == '3') {
      //&& currentUser.value.role_id == 'driver') {
      return "End Picking";
      //"On the way";
    } else if (_con.order.orderStatus.id == '4') {
      //&& currentUser.value.role_id == 'driver') {
      return "Out for Delivery";
      //S.of(context).delivered;
    } else if (_con.order.orderStatus.id == '5') {
      //&& currentUser.value.role_id == 'driver') {
      return "Delivered";
      //S.of(context).delivered;

    } else if (_con.order.orderStatus.id == '6' ||
        _con.order.orderStatus.id == '21') {
      return "Action required";
    }
    return null;
  }
}

class CustomRoundButton extends StatelessWidget {
  const CustomRoundButton({
    Key key,
    this.onPressed,
    this.text,
    this.width = 170,
  }) : super(key: key);
  final Function onPressed;
  final String text;
  final double width;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: width,
        padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
        decoration: BoxDecoration(
            color: Theme.of(context).accentColor,
            borderRadius: BorderRadius.circular(50),
            border: Border.all(
                color: Theme.of(context).accentColor.withOpacity(0.2),
                width: 1)),
        child: Align(
          alignment: Alignment.center,
          child: Text(
            text,
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).primaryColor),
          ),
        ),
      ),
    );
  }
}
