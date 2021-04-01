import 'package:flutter/material.dart';

class PaymentMethodDialogHandler {
  BuildContext _dismissingContext;

  void show(BuildContext context) {
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (dialogContext) {
          _dismissingContext = dialogContext;
          return Wrap(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Select a payment method"),
                  RadioListTile(value: null, groupValue: null, onChanged: null)
                ],
              ),
            ],
          );
        });
  }

  void hide() {
    Navigator.pop(_dismissingContext);
  }
}
