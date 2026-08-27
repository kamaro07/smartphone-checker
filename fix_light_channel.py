import os

# 1. Update MainActivity.kt
main_activity_code = \"\"\"package com.example.checklist_app_flutter

import android.content.Context
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel

class MainActivity : FlutterActivity() {
    private val LIGHT_CHANNEL = "com.example.checklist_app_flutter/light"
    private var sensorManager: SensorManager? = null
    private var lightSensor: Sensor? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        sensorManager = getSystemService(Context.SENSOR_SERVICE) as SensorManager
        lightSensor = sensorManager?.getDefaultSensor(Sensor.TYPE_LIGHT)

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, LIGHT_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                private var sensorEventListener: SensorEventListener? = null

                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    if (lightSensor == null) {
                        events?.error("UNAVAILABLE", "Light sensor not available.", null)
                        return
                    }
                    sensorEventListener = object : SensorEventListener {
                        override fun onSensorChanged(event: SensorEvent) {
                            events?.success(event.values[0].toInt())
                        }
                        override fun onAccuracyChanged(sensor: Sensor, accuracy: Int) {}
                    }
                    sensorManager?.registerListener(
                        sensorEventListener,
                        lightSensor,
                        SensorManager.SENSOR_DELAY_NORMAL
                    )
                }

                override fun onCancel(arguments: Any?) {
                    sensorManager?.unregisterListener(sensorEventListener)
                }
            }
        )
    }
}
\"\"\"
with open('checklist_app_flutter/android/app/src/main/kotlin/com/example/checklist_app_flutter/MainActivity.kt', 'w') as f:
    f.write(main_activity_code)

# 2. Update light_service.dart
light_service_code = \"\"\"import 'dart:async';
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
\"\"\"
with open('checklist_app_flutter/lib/services/light_service.dart', 'w') as f:
    f.write(light_service_code)

# 3. Remove 'light:' from pubspec.yaml
with open('checklist_app_flutter/pubspec.yaml', 'r', encoding='utf-8') as f:
    pubspec = f.read()
import re
pubspec = re.sub(r'\\n\\s+light:.*\\n', '\\n', pubspec)
with open('checklist_app_flutter/pubspec.yaml', 'w', encoding='utf-8') as f:
    f.write(pubspec)

# 4. Remove the python sed patch from build-apk.yml
with open('.github/workflows/build-apk.yml', 'r', encoding='utf-8') as f:
    yml = f.read()
# Just restore it to clean state without the Python patch
yml_clean = \"\"\"name: Build Flutter APK

on:
  push:
    branches:
      - main
      - master
  workflow_dispatch:

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - name: Set up Java
        uses: actions/setup-java@v4
        with:
          distribution: 'zulu'
          java-version: '17'

      - name: Set up Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.x'
          channel: 'stable'

      - name: Get Dependencies
        run: flutter pub get
        working-directory: checklist_app_flutter

      - name: Build APK
        run: flutter build apk --release --android-skip-build-dependency-validation
        working-directory: checklist_app_flutter

      - name: Upload APK Artifact
        uses: actions/upload-artifact@v4
        with:
          name: smartphone-checker-apk
          path: checklist_app_flutter/build/app/outputs/flutter-apk/app-release.apk
\"\"\"
with open('.github/workflows/build-apk.yml', 'w', encoding='utf-8') as f:
    f.write(yml_clean)

print("All fixes applied successfully!")
