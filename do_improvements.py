# -*- coding: utf-8 -*-
import os
import re

# 1. Update test_screen.dart
with open('checklist_app_flutter/lib/screens/test_screen.dart', 'r', encoding='utf-8') as f:
    ts = f.read()

# Replace imports
ts = ts.replace("import '../services/fingerprint_service.dart';", "import '../services/fingerprint_service.dart';\nimport 'light_test_screen.dart';")
ts = ts.replace("import '../services/nfc_service.dart';", "")
ts = ts.replace("import '../services/light_service.dart';", "")
ts = ts.replace("import '../services/audio_service.dart';", "")

# Fix _playBeep to last 10s
playbeep_old = '''    try {
      await _audioPlayer.stop();
      await _audioPlayer.setAudioContext(AudioContext(
        android: AudioContextAndroid(
          isSpeakerphoneOn: !useEarpiece,
          usageType: useEarpiece ? AndroidUsageType.voiceCommunication : AndroidUsageType.media,
          contentType: useEarpiece ? AndroidContentType.speech : AndroidContentType.music,
        ),
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.playAndRecord,
          options: !useEarpiece ? const {AVAudioSessionOptions.defaultToSpeaker} : const {},
        ),
      ));
      await _audioPlayer.setVolume(1.0);
      await _audioPlayer.play(AssetSource('audio/beep.wav'));'''

playbeep_new = '''    try {
      await _audioPlayer.stop();
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.setAudioContext(AudioContext(
        android: AudioContextAndroid(
          isSpeakerphoneOn: !useEarpiece,
          usageType: useEarpiece ? AndroidUsageType.voiceCommunication : AndroidUsageType.media,
          contentType: useEarpiece ? AndroidContentType.speech : AndroidContentType.music,
        ),
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.playAndRecord,
          options: !useEarpiece ? const {AVAudioSessionOptions.defaultToSpeaker} : const {},
        ),
      ));
      await _audioPlayer.setVolume(1.0);
      await _audioPlayer.play(AssetSource('audio/beep.wav'));
      await Future.delayed(const Duration(seconds: 10));
      await _audioPlayer.stop();
      await _audioPlayer.setReleaseMode(ReleaseMode.release);'''
ts = ts.replace(playbeep_old, playbeep_new)

# Remove NFC and Microfone test logic, update Light and Fingerprint
ts = re.sub(r'  void _testNfc\(\) async \{.*?\n  \}\n\n', '', ts, flags=re.DOTALL)
ts = re.sub(r'  void _testAudio15s\(\) async \{.*?\n  \}\n\n', '', ts, flags=re.DOTALL)

light_old = '''  void _testLight() async {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lendo sensor de luz...')));
    final res = await LightService.check();
    if (res.startsWith('Lux:')) {
      _updateResult('luz', true);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res), backgroundColor: Colors.green));
    } else {
      _updateResult('luz', false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: ' + res), backgroundColor: Colors.red));
    }
  }'''

light_new = '''  void _openLightTest() async {
    final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const LightTestScreen()));
    if (result != null) {
      _updateResult('luz', result);
    }
  }'''
ts = ts.replace(light_old, light_new)

fingerprint_old = '''  void _testFingerprint() async {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Siga as instruções no sensor biométrico...')));
    final res = await FingerprintService.check();
    if (res == 'Success') {
      _updateResult('biometria', true);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Biometria OK!'), backgroundColor: Colors.green));
    } else {
      _updateResult('biometria', false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: ' + res), backgroundColor: Colors.red));
    }
  }'''

fingerprint_new = '''  void _testFingerprint() async {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Siga as instruções no sensor biométrico...')));
    final res = await FingerprintService.check();
    // Qualquer resposta que não seja 'Biometrics not available' significa que o sensor respondeu e funciona fisicamente.
    if (res != 'Biometrics not available' && !res.startsWith('Error:')) {
      _updateResult('biometria', true);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sensor Biométrico Funcional!'), backgroundColor: Colors.green));
    } else {
      _updateResult('biometria', false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ou ausente: ' + res), backgroundColor: Colors.red));
    }
  }'''
ts = ts.replace(fingerprint_old, fingerprint_new)

# Update build buttons
items_old = '''          _buildTestItem('microfone', 'Microfone (15s)', Icons.mic, onRun: _testAudio15s),
          _buildTestItem('biometria', 'Impressão Digital', Icons.fingerprint, onRun: _testFingerprint),
          _buildTestItem('nfc', 'NFC', Icons.nfc, onRun: _testNfc),
          _buildTestItem('luz', 'Sensor de Luz', Icons.light_mode, onRun: _testLight),'''
items_new = '''          _buildTestItem('biometria', 'Impressão Digital', Icons.fingerprint, onRun: _testFingerprint),
          _buildTestItem('luz', 'Sensor de Luz', Icons.light_mode, onRun: _openLightTest),'''
ts = ts.replace(items_old, items_new)

# Update speaker button titles for clarity
ts = ts.replace("'test_speaker'.tr()", "'Alto-falante (10s)'")
ts = ts.replace("'test_earpiece'.tr()", "'Auricular (10s)'")

with open('checklist_app_flutter/lib/screens/test_screen.dart', 'w', encoding='utf-8') as f:
    f.write(ts)

# 2. Update proximity_test_screen.dart to be interactive
prox_code = '''import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:proximity_sensor/proximity_sensor.dart';
import 'dart:async';

class ProximityTestScreen extends StatefulWidget {
  const ProximityTestScreen({super.key});

  @override
  State<ProximityTestScreen> createState() => _ProximityTestScreenState();
}

class _ProximityTestScreenState extends State<ProximityTestScreen> {
  StreamSubscription<int>? _subscription;
  bool _isNear = false;
  bool _hasChanged = false;

  @override
  void initState() {
    super.initState();
    _subscription = ProximitySensor.events.listen((int event) {
      setState(() {
        _isNear = (event == 1);
        _hasChanged = true;
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
        title: Text('proximity_instruction'.tr()),
        backgroundColor: const Color(0xFFD32F2F),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.sensors,
                size: 100,
                color: _isNear ? Colors.green : const Color(0xFFD32F2F),
              ),
              const SizedBox(height: 32),
              Text(
                'Aproxime a mão do topo do aparelho.\\nStatus atual:',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(height: 16),
              Text(
                _isNear ? 'PERTO' : 'LONGE',
                style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: _isNear ? Colors.green : Colors.grey),
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
                child: Text('proximity_working'.tr()),
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
                child: Text('proximity_not_working'.tr()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
'''
with open('checklist_app_flutter/lib/screens/proximity_test_screen.dart', 'w', encoding='utf-8') as f:
    f.write(prox_code)


# 3. Create light_test_screen.dart
light_code = '''import 'package:flutter/material.dart';
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
  int _lux = 0;

  @override
  void initState() {
    super.initState();
    _subscription = _lightChannel.receiveBroadcastStream().listen((dynamic event) {
      setState(() {
        _lux = event as int;
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
                'Cubra e descubra o topo do aparelho.\\nO valor deve mudar:',
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
'''
with open('checklist_app_flutter/lib/screens/light_test_screen.dart', 'w', encoding='utf-8') as f:
    f.write(light_code)


# 4. Update FingerprintService to treat 'LockedOut' / auth failure as success
with open('checklist_app_flutter/lib/services/fingerprint_service.dart', 'r', encoding='utf-8') as f:
    fp = f.read()

fp = fp.replace("return didAuthenticate ? 'Success' : 'Failed';", "return didAuthenticate ? 'Success' : 'Success_WrongFinger';")
# also catch lockedout? Usually local_auth throws PlatformException, so we can catch it.
fp = fp.replace('''    } catch (e) {
      return 'Error: ';
    }''', '''    } catch (e) {
      // Se lançou exceção LockedOut ou NotEnrolled, o sensor físico existe e tentou ler.
      final err = e.toString().toLowerCase();
      if (err.contains('lockedout') || err.contains('notenrolled') || err.contains('passcode')) {
        return 'Success_SensorExists';
      }
      return 'Error: ';
    }''')

with open('checklist_app_flutter/lib/services/fingerprint_service.dart', 'w', encoding='utf-8') as f:
    f.write(fp)


# 5. Clean up deleted services
try:
    os.remove('checklist_app_flutter/lib/services/audio_service.dart')
    os.remove('checklist_app_flutter/lib/services/nfc_service.dart')
except:
    pass

