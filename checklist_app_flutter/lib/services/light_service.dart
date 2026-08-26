// lib/services/light_service.dart
import 'package:light_sensor/light_sensor.dart';

class LightService {
  static Future<String> check() async {
    try {
      final completer = Completer<String>();
      StreamSubscription<double>? sub;
      sub = LightSensor.events.listen((double lux) {
        sub?.cancel();
        completer.complete('Lux: ${lux.toStringAsFixed(2)}');
      }, onError: (e) {
        completer.complete('Error: $e');
      });
      // Timeout after 5 seconds
      return await completer.future.timeout(const Duration(seconds: 5), onTimeout: () => 'Timeout');
    } catch (e) {
      return 'Error: $e';
    }
  }
}
