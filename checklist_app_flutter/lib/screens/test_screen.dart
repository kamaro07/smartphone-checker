import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:vibration/vibration.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:battery_plus/battery_plus.dart';
import 'dart:async';

import 'package:camera/camera.dart';

import 'rgb_screen_test.dart';
import 'proximity_test_screen.dart';
import 'brightness_test_screen.dart';
import 'camera_test_screen.dart';
import 'buttons_test_screen.dart';
import '../services/fingerprint_service.dart';
import 'light_test_screen.dart';





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
  List<CameraDescription> _cameras = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    _deviceInfo = args['deviceInfo'];
    _serverIp = args['serverIp'];
    _loadCameras();
  }

  Future<void> _loadCameras() async {
    final cameras = await availableCameras();
    setState(() {
      _cameras = cameras;
    });
  }

  void _updateResult(String key, bool value) {
    setState(() {
      _results[key] = value;
    });
  }

  // ==========================================
  // TESTES AUTOMÁTICOS / SEMI-AUTOMÁTICOS
  // ==========================================

  void _testVibration() async {
    bool? hasVibrator = await Vibration.hasVibrator();
    if (hasVibrator == true) {
      Vibration.vibrate(duration: 500);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vibrando...')));
      }
    }
  }

  Future<void> _playBeep(bool useEarpiece) async {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('sound_playing'.tr()), backgroundColor: Colors.blue, duration: const Duration(seconds: 1)),
      );
    }
    try {
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
      await Future.delayed(const Duration(seconds: 5));
      await _audioPlayer.stop();
      await _audioPlayer.setReleaseMode(ReleaseMode.release);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('sound_question'.tr()), backgroundColor: Colors.orange),
        );
      }
    }
  }

  void _testLoudspeaker() => _playBeep(false);
  void _testEarpiece() => _playBeep(true);

  void _testWifi() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult.contains(ConnectivityResult.wifi) || connectivityResult.contains(ConnectivityResult.mobile)) {
      _updateResult('wifi', true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rede conectada! (Aprovado)'), backgroundColor: Colors.green));
      }
    } else {
      _updateResult('wifi', false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sem conexão de rede.'), backgroundColor: Colors.red));
      }
    }
  }


  void _testFingerprint() async {
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
  }

  void _openLightTest() async {
    final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const LightTestScreen()));
    if (result != null) {
      _updateResult('luz', result);
    }
  }

  void _testUsb() async {
    var battery = Battery();
    var state = await battery.batteryState;
    if (state == BatteryState.charging || state == BatteryState.full) {
      _updateResult('usb', true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Carregamento detectado! (Aprovado)'), backgroundColor: Colors.green));
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Não está carregando.'), backgroundColor: Colors.red));
      }
    }
  }

  void _testSimCard() async {
    // SIM card detection is restricted on Android 10+
    // We show a manual confirmation dialog
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('test_sim'.tr()),
        content: Text('sim_detected'.tr()),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _updateResult('chip', false);
            },
            child: Text('btn_no'.tr(), style: const TextStyle(color: Colors.red)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _updateResult('chip', true);
            },
            child: Text('btn_yes'.tr(), style: const TextStyle(color: Colors.green)),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TESTES INTERATIVOS (ABREM TELAS)
  // ==========================================

  void _openTouchGrid() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TouchGridTestScreen())).then((approved) {
      if (approved == true) {
        _updateResult('tela', true);
      }
    });
  }

  void _openRgbTest() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RgbScreenTest())).then((result) {
      if (result != null) {
        _updateResult('telaRgb', result as bool);
      }
    });
  }

  void _openProximityTest() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProximityTestScreen())).then((result) {
      if (result != null) {
        _updateResult('sensorProximidade', result as bool);
      }
    });
  }

  void _openBrightnessTest() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BrightnessTestScreen())).then((result) {
      if (result != null) {
        _updateResult('brilho', result as bool);
      }
    });
  }

  void _openCameraTest(CameraDescription camera, String key) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => CameraTestScreen(camera: camera))).then((result) {
      if (result != null) {
        _updateResult(key, result as bool);
      }
    });
  }

  void _openButtonsTest() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ButtonsTestScreen())).then((result) {
      if (result != null) {
        _updateResult('botoesFisicos', result as bool);
      }
    });
  }

  // ==========================================
  // BUILD TEST ITEM WIDGET
  // ==========================================

  Widget _buildTestItem(String key, String title, IconData icon, {VoidCallback? onRun}) {
    bool? status = _results[key];
    Color statusColor = status == null
        ? Colors.grey.shade300
        : status == true
            ? Colors.green
            : Colors.red;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: status == null ? Colors.transparent : statusColor,
          width: status == null ? 0 : 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD32F2F).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: const Color(0xFFD32F2F), size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                ),
                if (status != null)
                  Icon(
                    status == true ? Icons.check_circle : Icons.cancel,
                    color: statusColor,
                    size: 28,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (onRun != null)
              OutlinedButton.icon(
                icon: const Icon(Icons.play_arrow, size: 20),
                label: Text('btn_run'.tr()),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFD32F2F),
                  side: const BorderSide(color: Color(0xFFD32F2F)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: onRun,
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.close, size: 18),
                    label: Text('btn_reject'.tr()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: status == false ? Colors.red : Colors.white,
                      foregroundColor: status == false ? Colors.white : Colors.red,
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => _updateResult(key, false),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.check, size: 18),
                    label: Text('btn_approve'.tr()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: status == true ? Colors.green : Colors.white,
                      foregroundColor: status == true ? Colors.white : Colors.green,
                      side: const BorderSide(color: Colors.green),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => _updateResult(key, true),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  // ==========================================
  // AESTHETICS CHECKLIST WIDGET
  // ==========================================

  Widget _buildAestheticsSection() {
    bool? status = _results['estetica'];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: status == null ? Colors.transparent : (status == true ? Colors.green : Colors.red),
          width: status == null ? 0 : 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD32F2F).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.phone_android, color: Color(0xFFD32F2F), size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'test_aesthetics'.tr(),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                ),
                if (status != null)
                  Icon(
                    status == true ? Icons.check_circle : Icons.cancel,
                    color: status == true ? Colors.green : Colors.red,
                    size: 28,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            _buildCheckTile('aesthetics_scratches'),
            _buildCheckTile('aesthetics_cracks'),
            _buildCheckTile('aesthetics_buttons'),
            _buildCheckTile('aesthetics_ports'),
            _buildCheckTile('aesthetics_back'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.close, size: 18),
                    label: Text('btn_reject'.tr()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: status == false ? Colors.red : Colors.white,
                      foregroundColor: status == false ? Colors.white : Colors.red,
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => _updateResult('estetica', false),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.check, size: 18),
                    label: Text('btn_approve'.tr()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: status == true ? Colors.green : Colors.white,
                      foregroundColor: status == true ? Colors.white : Colors.green,
                      side: const BorderSide(color: Colors.green),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => _updateResult('estetica', true),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildCheckTile(String titleKey) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          const Icon(Icons.check_box_outline_blank, color: Colors.grey, size: 20),
          const SizedBox(width: 8),
          Text(titleKey.tr(), style: const TextStyle(fontSize: 14, color: Colors.black87)),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  // ==========================================
  // BUILD
  // ==========================================

  @override
  Widget build(BuildContext context) {
    int totalAnswered = _results.values.where((v) => v != null).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('tests_title').tr(),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
      ),
      backgroundColor: const Color(0xFFF8F9FA),
      body: ListView(
        padding: const EdgeInsets.all(15),
        children: [
          // Device info header
          Container(
            padding: const EdgeInsets.all(15),
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: const Border(bottom: BorderSide(color: Color(0xFFD32F2F), width: 4)),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
            ),
            child: Row(
              children: [
                const Icon(Icons.smartphone, color: Color(0xFFD32F2F), size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_deviceInfo['brand']} ${_deviceInfo['model']}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'IMEI: ${_deviceInfo['imei'] ?? '-'}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD32F2F).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$totalAnswered/${11 + _cameras.length + 1}', // 11 static tests + n cameras + 1 aesthetics
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFD32F2F)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // ========== TESTES ==========
          _buildTestItem('tela', 'test_screen'.tr(), Icons.touch_app, onRun: _openTouchGrid),
          _buildTestItem('telaRgb', 'test_rgb'.tr(), Icons.color_lens, onRun: _openRgbTest),
          _buildTestItem('vibracao', 'test_vibration'.tr(), Icons.vibration, onRun: _testVibration),
          _buildTestItem('sensorProximidade', 'test_proximity'.tr(), Icons.sensors, onRun: _openProximityTest),
          _buildTestItem('somCampainha', 'Alto-falante (5s)', Icons.volume_up, onRun: _testLoudspeaker),
          _buildTestItem('somAuricular', 'Auricular (5s)', Icons.hearing, onRun: _testEarpiece),
          _buildTestItem('brilho', 'test_brightness'.tr(), Icons.brightness_high, onRun: _openBrightnessTest),
          
          ..._cameras.asMap().entries.map((e) {
            String dir = e.value.lensDirection.toString().split('.').last.toUpperCase();
            return _buildTestItem(
              'camera_${e.key}',
              'Câmera $dir (${e.value.name})',
              Icons.camera,
              onRun: () => _openCameraTest(e.value, 'camera_${e.key}')
            );
          }),

          _buildTestItem('botoesFisicos', 'test_buttons'.tr(), Icons.gamepad, onRun: _openButtonsTest),
          _buildTestItem('wifi', 'test_wifi'.tr(), Icons.wifi, onRun: _testWifi),
          _buildTestItem('chip', 'test_sim'.tr(), Icons.sim_card, onRun: _testSimCard),

          _buildTestItem('biometria', 'Impressão Digital', Icons.fingerprint, onRun: _testFingerprint),
          _buildTestItem('luz', 'Sensor de Luz', Icons.light_mode, onRun: _openLightTest),
          _buildTestItem('usb', 'test_usb'.tr(), Icons.usb, onRun: _testUsb),
          _buildAestheticsSection(),

          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD32F2F),
              padding: const EdgeInsets.all(18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 3,
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
    double progress = _painted.length / _totalBlocks;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Progress bar
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(
                progress > 0.9 ? Colors.green : const Color(0xFFD32F2F),
              ),
              minHeight: 6,
            ),
            Expanded(
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
          ],
        ),
      ),
    );
  }
}
