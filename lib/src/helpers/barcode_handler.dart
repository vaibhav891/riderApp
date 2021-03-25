import 'package:flutter/material.dart';
import 'package:qrscan/qrscan.dart' as scanner;

class BarcodeHandler {
  static Future scanBarcode(BuildContext context) async {
    try {
      String cameraScanResult = await scanner.scan();
      return cameraScanResult;
    } catch (e) {
      print(e);
      return null;
    }
  }
}
