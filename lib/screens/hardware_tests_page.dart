import 'package:flutter/material.dart';
import '../services/fingerprint_service.dart';
import '../services/proximity_service.dart';
import '../services/light_service.dart';
import '../services/audio_service.dart';
import '../services/nfc_service.dart';
import '../widgets/test_result_tile.dart';

class HardwareTestsPage extends StatefulWidget {
  const HardwareTestsPage({Key? key}) : super(key: key);

  @override
  State<HardwareTestsPage> createState() => _HardwareTestsPageState();
}

class _HardwareTestsPageState extends State<HardwareTestsPage> {
  final Map<String, bool?> _results = {};

  Future<void> _runTest(String name, Future<bool> Function() test) async {
    setState(() => _results[name] = null);
    final success = await test();
    setState(() => _results[name] = success);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Testes de Hardware')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ElevatedButton(
            onPressed: () => _runTest('Impressão Digital', () => FingerprintService().test()),
            child: const Text('Testar Impressão Digital'),
          ),
          TestResultTile(testName: 'Impressão Digital', result: _results['Impressão Digital']),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _runTest('Proximidade', () => ProximityService().test()),
            child: const Text('Testar Sensor de Proximidade'),
          ),
          TestResultTile(testName: 'Proximidade', result: _results['Proximidade']),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _runTest('Luz Ambiente', () => LightService().test()),
            child: const Text('Testar Luz Ambiente'),
          ),
          TestResultTile(testName: 'Luz Ambiente', result: _results['Luz Ambiente']),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _runTest('Áudio', () => AudioService().test()),
            child: const Text('Testar Áudio (10s)'),
          ),
          TestResultTile(testName: 'Áudio', result: _results['Áudio']),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _runTest('NFC', () => NfcService().test()),
            child: const Text('Testar NFC'),
          ),
          TestResultTile(testName: 'NFC', result: _results['NFC']),
        ],
      ),
    );
  }
}
