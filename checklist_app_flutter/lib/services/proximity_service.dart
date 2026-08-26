// lib/services/proximity_service.dart
import 'package:proximity_sensor/proximity_sensor.dart';

class ProximityService {
  static Future<String> check() async {
    try {
      final completer = Completer<String>();
      StreamSubscription<int>? sub;
      sub = ProximitySensor.events.listen((int event) {
        sub?.cancel();
        completer.complete(event == 1 ? 'Near' : 'Far');
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
