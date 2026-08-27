import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';

class LightTestScreen extends StatefulWidget {
  const LightTestScreen({super.key});

  @override
  State<LightTestScreen> createState() => _LightTestScreenState();
}

class _LightTestScreenState extends State<LightTestScreen> {
  static const EventChannel _lightChannel = EventChannel('com.example.checklist_app_flutter/light');
  StreamSubscription<dynamic>? _subscription;
  String _lux = "0";

  @override
  void initState() {
    super.initState();
    _subscription = _lightChannel.receiveBroadcastStream().listen((dynamic event) {
      setState(() {
        _lux = (event as num).toStringAsFixed(1);
      });
    }, onError: (dynamic error) {
      setState(() {
        _lux = "Erro (Sensor ausente)";
      });
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Teste do Sensor de Luz'),
        backgroundColor: const Color(0xFFD32F2F),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.light_mode,
                size: 100,
                color: Color(0xFFD32F2F),
              ),
              const SizedBox(height: 32),
              const Text(
                'Cubra e descubra o topo do aparelho.\nO valor deve mudar:',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20),
              ),
              const SizedBox(height: 16),
              Text(
                ' Lux',
                style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.blueAccent),
              ),
              const SizedBox(height: 48),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD32F2F),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                ),
                onPressed: () {
                  Navigator.of(context).pop(true);
                },
                child: const Text('Funciona perfeitamente'),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFD32F2F),
                  minimumSize: const Size(double.infinity, 50),
                ),
                onPressed: () {
                  Navigator.of(context).pop(false);
                },
                child: const Text('Não está funcionando'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
