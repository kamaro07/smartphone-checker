import 'dart:async';
import 'package:light/light.dart';

class LightService {
  static Future<String> check() async {
    try {
      final light = Light();
      // On some platforms, requestAuthorization may be needed, but usually not strictly for Android.
      final completer = Completer<String>();
      StreamSubscription<int>? sub;
      sub = light.lightSensorStream.listen((int lux) {
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
