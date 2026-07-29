import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:vibration/vibration.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:battery_plus/battery_plus.dart';
import 'dart:async';

class TestScreen extends StatefulWidget {
  const TestScreen({super.key});

  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  final Map<String, bool?> _results = {};
  late Map<String, dynamic> _deviceInfo;
  late String _serverIp;
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    _deviceInfo = args['deviceInfo'];
    _serverIp = args['serverIp'];
  }

  void _updateResult(String key, bool value) {
    setState(() {
      _results[key] = value;
    });
  }

  void _testVibration() async {
    bool? hasVibrator = await Vibration.hasVibrator();
    if (hasVibrator == true) {
      Vibration.vibrate(duration: 500);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vibrando...')));
    }
  }

  void _testSound() async {
    // In a real app we'd record and playback. For now we play a tone or wait for user to confirm.
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reproduzindo áudio (Mock)...')));
  }

  void _testWifi() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult.contains(ConnectivityResult.wifi) || connectivityResult.contains(ConnectivityResult.mobile)) {
      _updateResult('wifi', true);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rede conectada! (Aprovado)'), backgroundColor: Colors.green));
    } else {
      _updateResult('wifi', false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sem conexão de rede.'), backgroundColor: Colors.red));
    }
  }

  void _testUsb() async {
    var battery = Battery();
    var state = await battery.batteryState;
    if (state == BatteryState.charging || state == BatteryState.full) {
      _updateResult('usb', true);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Carregamento detectado! (Aprovado)'), backgroundColor: Colors.green));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Não está carregando.'), backgroundColor: Colors.red));
    }
  }

  void _openTouchGrid() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TouchGridTestScreen())).then((approved) {
      if (approved == true) {
        _updateResult('tela', true);
      }
    });
  }

  Widget _buildTestItem(String key, String titleKey, {VoidCallback? onRun}) {
    bool? status = _results[key];
    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      color: Colors.white,
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(titleKey.tr(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 10),
            if (onRun != null)
              OutlinedButton(
                onPressed: onRun,
                child: Text('btn_run'.tr()),
              ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: status == false ? Colors.red : Colors.white,
                      foregroundColor: status == false ? Colors.white : Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                    onPressed: () => _updateResult(key, false),
                    child: Text('btn_reject'.tr()),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: status == true ? Colors.green : Colors.white,
                      foregroundColor: status == true ? Colors.white : Colors.green,
                      side: const BorderSide(color: Colors.green),
                    ),
                    onPressed: () => _updateResult(key, true),
                    child: Text('btn_approve'.tr()),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('tests_title').tr(),
        backgroundColor: Colors.white,
      ),
      backgroundColor: const Color(0xFFF8F9FA),
      body: ListView(
        padding: const EdgeInsets.all(15),
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            margin: const EdgeInsets.only(bottom: 20),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFD32F2F), width: 4)),
            ),
            child: Text('${_deviceInfo['brand']} ${_deviceInfo['model']}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          _buildTestItem('tela', 'test_screen', onRun: _openTouchGrid),
          _buildTestItem('vibracao', 'test_vibration', onRun: _testVibration),
          _buildTestItem('som', 'test_sound', onRun: _testSound),
          _buildTestItem('wifi', 'test_wifi', onRun: _testWifi),
          _buildTestItem('usb', 'test_usb', onRun: _testUsb),

          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD32F2F),
              padding: const EdgeInsets.all(18),
            ),
            onPressed: () {
              Navigator.pushNamed(context, '/result', arguments: {
                'deviceInfo': _deviceInfo,
                'tests': _results,
                'serverIp': _serverIp
              });
            },
            child: Text('finish_btn'.tr(), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

// ----------------------------------------------------
// TELA INTERATIVA DO TESTE DE TOUCH (NATIVO FLUTTER)
// ----------------------------------------------------
class TouchGridTestScreen extends StatefulWidget {
  const TouchGridTestScreen({super.key});
  @override
  State<TouchGridTestScreen> createState() => _TouchGridTestScreenState();
}

class _TouchGridTestScreenState extends State<TouchGridTestScreen> {
  final Set<int> _painted = {};
  final int _rows = 15;
  final int _cols = 8;
  late int _totalBlocks;

  @override
  void initState() {
    super.initState();
    _totalBlocks = _rows * _cols;
  }

  void _onPanUpdate(DragUpdateDetails details, Size size) {
    double blockW = size.width / _cols;
    double blockH = size.height / _rows;

    int col = (details.localPosition.dx / blockW).floor();
    int row = (details.localPosition.dy / blockH).floor();

    if (col >= 0 && col < _cols && row >= 0 && row < _rows) {
      int idx = row * _cols + col;
      if (!_painted.contains(idx)) {
        setState(() {
          _painted.add(idx);
        });
        if (_painted.length >= _totalBlocks * 0.95) { // 95% pintado = Aprovado
           Navigator.of(context).pop(true);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return GestureDetector(
              onPanUpdate: (details) => _onPanUpdate(details, constraints.biggest),
              onPanDown: (details) => _onPanUpdate(DragUpdateDetails(globalPosition: details.globalPosition, localPosition: details.localPosition), constraints.biggest),
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: _cols,
                  childAspectRatio: (constraints.biggest.width / _cols) / (constraints.biggest.height / _rows),
                ),
                itemCount: _totalBlocks,
                itemBuilder: (context, index) {
                  return Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.withOpacity(0.3)),
                      color: _painted.contains(index) ? Colors.green : Colors.transparent,
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
