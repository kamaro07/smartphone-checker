// lib/screens/hardware_tests_page.dart
import 'package:flutter/material.dart';
import '../widgets/test_result_tile.dart';
import '../services/fingerprint_service.dart';
import '../services/proximity_service.dart';
import '../services/light_service.dart';
import '../services/audio_service.dart';
import '../services/nfc_service.dart';

class HardwareTestsPage extends StatefulWidget {
  const HardwareTestsPage({Key? key}) : super(key: key);

  @override
  State<HardwareTestsPage> createState() => _HardwareTestsPageState();
}

class _HardwareTestsPageState extends State<HardwareTestsPage> {
  final Map<String, String?> _results = {};

  Future<void> _runTest(String name, Future<String> Function() test) async {
    setState(() => _results[name] = 'Running...');
    try {
      final res = await test();
      setState(() => _results[name] = res);
    } catch (e) {
      setState(() => _results[name] = 'Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hardware Tests')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ElevatedButton(
            onPressed: () => _runTest('Fingerprint', FingerprintService.check),
            child: const Text('Test Fingerprint'),
          ),
          TestResultTile(label: 'Fingerprint', result: _results['Fingerprint']),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () => _runTest('Proximity', ProximityService.check),
            child: const Text('Test Proximity'),
          ),
          TestResultTile(label: 'Proximity', result: _results['Proximity']),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () => _runTest('Ambient Light', LightService.check),
            child: const Text('Test Ambient Light'),
          ),
          TestResultTile(label: 'Ambient Light', result: _results['Ambient Light']),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () => _runTest('Audio (10 s)', AudioService.record10Seconds),
            child: const Text('Record Audio (10 s)'),
          ),
          TestResultTile(label: 'Audio', result: _results['Audio (10 s)']),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () => _runTest('NFC', NfcService.check),
            child: const Text('Test NFC'),
          ),
          TestResultTile(label: 'NFC', result: _results['NFC']),
        ],
      ),
    );
  }
}
