import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _imeiController = TextEditingController();
  final TextEditingController _ipController = TextEditingController();
  bool _isScanning = false;
  Timer? _pingTimer;
  Map<String, String> _deviceData = {'brand': 'Unknown', 'model': 'Unknown', 'os': 'Android'};

  @override
  void initState() {
    super.initState();
    _loadSavedIp();
    _fetchDeviceInfo();
  }

  Future<void> _loadSavedIp() async {
    final prefs = await SharedPreferences.getInstance();
    final savedIp = prefs.getString('serverIp');
    if (savedIp != null) {
      _ipController.text = savedIp;
    }
  }

  Future<void> _saveIp(String ip) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('serverIp', ip);
  }

  Future<void> _fetchDeviceInfo() async {
    final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    final AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
    setState(() {
      _deviceData = {
        'brand': androidInfo.brand.toUpperCase(),
        'model': androidInfo.model,
        'os': 'Android ${androidInfo.version.release}',
      };
    });
  }

  void _startPing() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      final ip = _ipController.text.trim();
      final imei = _imeiController.text.trim();
      if (ip.isEmpty || imei.isEmpty) return;

      try {
        await http.post(
          Uri.parse('http://$ip:3000/api/ping'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'deviceId': imei,
            'brand': _deviceData['brand'],
            'model': _deviceData['model'],
            'os': _deviceData['os'],
            'osVersion': _deviceData['os']
          }),
        ).timeout(const Duration(seconds: 2));
      } catch (e) {
        // Silent fail
      }
    });
  }

  @override
  void dispose() {
    _pingTimer?.cancel();
    _imeiController.dispose();
    _ipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isScanning) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('scan_barcode').tr(),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => setState(() => _isScanning = false),
          ),
        ),
        body: MobileScanner(
          onDetect: (capture) {
            final List<Barcode> barcodes = capture.barcodes;
            if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
              setState(() {
                _imeiController.text = barcodes.first.rawValue!;
                _isScanning = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Código capturado: ${_imeiController.text}')),
              );
            }
          },
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('app_title').tr(),
        actions: [
          DropdownButton<String>(
            value: context.locale.languageCode,
            underline: const SizedBox(),
            icon: const Icon(Icons.language, color: Colors.white),
            dropdownColor: Colors.white,
            items: const [
              DropdownMenuItem(value: 'pt', child: Text('PT-BR')),
              DropdownMenuItem(value: 'en', child: Text('EN-US')),
              DropdownMenuItem(value: 'es', child: Text('ES')),
            ],
            onChanged: (val) {
              if (val != null) context.setLocale(Locale(val));
            },
          ),
          const SizedBox(width: 15),
        ],
      ),
      backgroundColor: const Color(0xFFF8F9FA),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'app_title'.tr(),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Color(0xFFD32F2F)),
            ),
            Text(
              'app_subtitle'.tr(),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.grey, letterSpacing: 2),
            ),
            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: const Border(left: BorderSide(color: Color(0xFFD32F2F), width: 5)),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('device_detected'.tr(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Text('${'brand'.tr()}: ${_deviceData['brand']}', style: const TextStyle(fontSize: 16)),
                  Text('${'model'.tr()}: ${_deviceData['model']}', style: const TextStyle(fontSize: 16)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text('imei_label'.tr(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _imeiController,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                hintText: 'imei_placeholder'.tr(),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 20),
            Text('ip_label'.tr(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _ipController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                hintText: 'ip_placeholder'.tr(),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onChanged: (val) {
                _saveIp(val);
                _startPing();
              },
            ),
            const SizedBox(height: 30),
            OutlinedButton.icon(
              icon: const Icon(Icons.qr_code_scanner, color: Color(0xFFD32F2F)),
              label: Text('scan_barcode'.tr(), style: const TextStyle(color: Color(0xFFD32F2F), fontSize: 16)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.all(15),
                side: const BorderSide(color: Color(0xFFD32F2F)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => setState(() => _isScanning = true),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD32F2F),
                padding: const EdgeInsets.all(18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                if (_imeiController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('imei_placeholder'.tr())));
                  return;
                }
                _saveIp(_ipController.text.trim());
                _deviceData['imei'] = _imeiController.text.trim();
                Navigator.pushNamed(context, '/test', arguments: {'deviceInfo': _deviceData, 'serverIp': _ipController.text.trim()});
              },
              child: Text('start_tests'.tr(), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1)),
            ),
          ],
        ),
      ),
    );
  }
}
