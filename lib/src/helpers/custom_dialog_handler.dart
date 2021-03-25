import 'package:flutter/material.dart';

class CustomDialogHandler {
  BuildContext _dismissingContext;

  void show(BuildContext context) {
    showDialog(
        context: context,
        builder: (dialogContext) {
          _dismissingContext = dialogContext;
          return Center(child: CircularProgressIndicator());
        });
  }

  void hide() {
    Navigator.pop(_dismissingContext);
  }
}
