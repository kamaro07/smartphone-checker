package com.example.checklist_app_flutter

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
