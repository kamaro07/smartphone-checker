import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import 'dart:async';

class NfcService {
  Future<bool> test() async {
    try {
      final result = await FlutterNfcKit.poll(timeout: const Duration(seconds: 5));
      // If a tag is read, consider success
      return result != null && result.id.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}
