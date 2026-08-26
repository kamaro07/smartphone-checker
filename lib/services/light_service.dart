import 'package:light_sensor/light_sensor.dart';
import 'dart:async';

class LightService {
  Future<bool> test() async {
    final completer = Completer<bool>();
    final sensor = LightSensor();
    List<double> readings = [];
    final subscription = sensor.lightStream?.listen((lux) {
      readings.add(lux);
    });
    // Collect for ~2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      subscription?.cancel();
      if (readings.isEmpty) {
        completer.complete(false);
      } else {
        // Successful if any reading obtained
        completer.complete(true);
      }
    });
    return completer.future;
  }
}
