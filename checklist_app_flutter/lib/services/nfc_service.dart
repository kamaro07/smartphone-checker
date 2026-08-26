// lib/services/nfc_service.dart
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';

class NfcService {
  static Future<String> check() async {
    try {
      final result = await FlutterNfcKit.poll(timeout: const Duration(seconds: 5));
      // If a tag is detected, return its ID; otherwise timeout.
      return result.id ?? 'No tag detected';
    } catch (e) {
      return 'Error: $e';
    } finally {
      await FlutterNfcKit.finish();
    }
  }
}
