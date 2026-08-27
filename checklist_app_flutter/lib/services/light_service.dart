import 'dart:async';
import 'package:flutter/services.dart';

class LightService {
  static const EventChannel _lightChannel = EventChannel('com.example.checklist_app_flutter/light');

  static Future<String> check() async {
    try {
      final completer = Completer<String>();
      StreamSubscription<dynamic>? sub;
      sub = _lightChannel.receiveBroadcastStream().listen((dynamic lux) {
        sub?.cancel();
        completer.complete('Lux: ' + lux.toString());
      }, onError: (e) {
        completer.complete('Error: ' + e.toString());
      });
      return await completer.future.timeout(const Duration(seconds: 5), onTimeout: () => 'Timeout');
    } catch (e) {
      return 'Error: ' + e.toString();
    }
  }
}
