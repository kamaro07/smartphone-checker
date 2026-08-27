with open('checklist_app_flutter/pubspec.yaml', 'r', encoding='utf-8') as f:
    text = f.read()
text = text.replace('light_sensor: ^3.0.2', 'light: ^3.0.0')
with open('checklist_app_flutter/pubspec.yaml', 'w', encoding='utf-8') as f:
    f.write(text)

code = '''import 'dart:async';
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
'''
with open('checklist_app_flutter/lib/services/light_service.dart', 'w', encoding='utf-8') as f:
    f.write(code)
