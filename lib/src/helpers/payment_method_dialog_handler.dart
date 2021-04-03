import 'package:flutter/material.dart';
import 'package:markets_deliveryboy/src/models/payment.dart';
import 'package:markets_deliveryboy/src/repository/order_repository.dart';

class PaymentMethod {
  final String id;
  final String name;

  PaymentMethod(this.id, this.name);
}

class PaymentMethodDialogHandler {
  BuildContext _dismissingContext;
  var _selected;
  List<PaymentMethod> paymentMethods = [
    PaymentMethod('cashondelivery', 'Cash On Delivery'),
    PaymentMethod('checkmo', 'Card On Delivery'),
    PaymentMethod('ngeniusonline', 'Debit / Credit Card'),
  ];
  Future show(BuildContext context, String currentPaymentMethod) {
    _selected = paymentMethods.firstWhere(
        (element) => element.id == currentPaymentMethod,
        orElse: () => null);
    return showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (dialogContext) {
          _dismissingContext = dialogContext;
          return Wrap(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8.0, vertical: 4.0),
                    child: Text(
                      "Select a payment method",
                      style: Theme.of(context)
                          .textTheme
                          .headline4
                          .copyWith(color: Theme.of(context).accentColor),
                    ),
                  ),
                  ...paymentMethods
                      .map((ele) => RadioListTile<PaymentMethod>(
                            value: ele,
                            groupValue: _selected,
                            onChanged: (value) {
                              _selected = value;
                              hide();
                            },
                            title: Text(ele.name),
                          ))
                      .toList(),
                ],
              ),
            ],
          );
        });
  }

  void hide() {
    Navigator.pop(_dismissingContext, _selected);
  }
}
