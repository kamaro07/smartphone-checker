import 'dart:async';
import 'package:proximity_sensor/proximity_sensor.dart';

class ProximityService {
  Future<bool> test() async {
    final completer = Completer<bool>();
    StreamSubscription<bool>? subscription;
    subscription = ProximitySensor.events?.listen((bool isNear) {
      // If something is near within 5 seconds, consider success
      completer.complete(true);
      subscription?.cancel();
    });
    // Timeout after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      if (!completer.isCompleted) {
        completer.complete(false);
        subscription?.cancel();
      }
    });
    return completer.future;
  }
}
