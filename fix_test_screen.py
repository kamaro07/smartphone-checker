# -*- coding: utf-8 -*-
import re

with open('checklist_app_flutter/lib/services/audio_service.dart', 'r', encoding='utf-8') as f:
    code = f.read()
code = code.replace('record10Seconds', 'record15Seconds')
code = code.replace('seconds: 10', 'seconds: 15')
with open('checklist_app_flutter/lib/services/audio_service.dart', 'w', encoding='utf-8') as f:
    f.write(code)

with open('checklist_app_flutter/lib/screens/test_screen.dart', 'r', encoding='utf-8') as f:
    test_screen = f.read()

imports = '''
import '../services/fingerprint_service.dart';
import '../services/nfc_service.dart';
import '../services/light_service.dart';
import '../services/audio_service.dart';
'''
test_screen = test_screen.replace("import 'buttons_test_screen.dart';", "import 'buttons_test_screen.dart';" + imports)

test_methods = '''
  void _testFingerprint() async {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Siga as instruções no sensor biométrico...')));
    final res = await FingerprintService.check();
    if (res == 'Success') {
      _updateResult('biometria', true);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Biometria OK!'), backgroundColor: Colors.green));
    } else {
      _updateResult('biometria', false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: ' + res), backgroundColor: Colors.red));
    }
  }

  void _testNfc() async {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Aproxime uma TAG NFC...')));
    final res = await NfcService.check();
    if (res.startsWith('Error') || res.startsWith('No tag')) {
      _updateResult('nfc', false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res), backgroundColor: Colors.red));
    } else {
      _updateResult('nfc', true);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('NFC OK!'), backgroundColor: Colors.green));
    }
  }

  void _testLight() async {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lendo sensor de luz...')));
    final res = await LightService.check();
    if (res.startsWith('Lux:')) {
      _updateResult('luz', true);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res), backgroundColor: Colors.green));
    } else {
      _updateResult('luz', false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: ' + res), backgroundColor: Colors.red));
    }
  }

  void _testAudio15s() async {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gravando por 15 segundos... Fale algo.'), duration: Duration(seconds: 15)));
    final res = await AudioService.record15Seconds();
    if (res.startsWith('Error') || res.startsWith('File not')) {
      _updateResult('microfone', false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res), backgroundColor: Colors.red));
    } else {
      _updateResult('microfone', true);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Áudio 15s Gravado OK!'), backgroundColor: Colors.green));
    }
  }

  void _testUsb() async {'''
test_screen = test_screen.replace('  void _testUsb() async {', test_methods)

test_items = '''
          _buildTestItem('microfone', 'Microfone (15s)', Icons.mic, onRun: _testAudio15s),
          _buildTestItem('biometria', 'Impressão Digital', Icons.fingerprint, onRun: _testFingerprint),
          _buildTestItem('nfc', 'NFC', Icons.nfc, onRun: _testNfc),
          _buildTestItem('luz', 'Sensor de Luz', Icons.light_mode, onRun: _testLight),
          _buildTestItem('usb', 'test_usb'.tr(), Icons.usb, onRun: _testUsb),'''
test_screen = test_screen.replace("          _buildTestItem('usb', 'test_usb'.tr(), Icons.usb, onRun: _testUsb),", test_items)

with open('checklist_app_flutter/lib/screens/test_screen.dart', 'w', encoding='utf-8') as f:
    f.write(test_screen)
