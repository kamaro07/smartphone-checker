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
  final TextEditingController _triadorController = TextEditingController();
  final TextEditingController _imei1Controller = TextEditingController();
  final TextEditingController _imei2Controller = TextEditingController();
  final TextEditingController _capacityController = TextEditingController();
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

  Future<void> _fetchAdbInfo() async {
    final ip = _ipController.text.trim();
    if (ip.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Digite o IP do servidor primeiro!')));
      return;
    }
    _saveIp(ip);
    try {
      final response = await http.get(Uri.parse('http://$ip:3000/api/adb_info')).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          if (data['imei1'] != null) _imei1Controller.text = data['imei1'];
          if (data['imei2'] != null) _imei2Controller.text = data['imei2'];
          if (data['capacity'] != null) _capacityController.text = data['capacity'];
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Dados carregados via USB com sucesso!'), backgroundColor: Colors.green));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao comunicar com o servidor ADB: $e'), backgroundColor: Colors.red));
    }
  }

  void _startPing() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      final ip = _ipController.text.trim();
      final imei = _imei1Controller.text.trim();
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
    _triadorController.dispose();
    _imei1Controller.dispose();
    _imei2Controller.dispose();
    _capacityController.dispose();
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
                if (_imei1Controller.text.isEmpty) {
                  _imei1Controller.text = barcodes.first.rawValue!;
                } else {
                  _imei2Controller.text = barcodes.first.rawValue!;
                }
                _isScanning = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Código capturado!')),
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
            const SizedBox(height: 10),
            
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
            const SizedBox(height: 20),

            ElevatedButton.icon(
              icon: const Icon(Icons.usb, color: Colors.white),
              label: const Text('Puxar dados via USB (ADB)', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueGrey,
                padding: const EdgeInsets.all(12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: _fetchAdbInfo,
            ),
            const SizedBox(height: 20),
            
            Text('Nome do Triador', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _triadorController,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                hintText: 'Ex: João Silva',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 20),

            Text('IMEI 1', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _imei1Controller,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                hintText: 'imei_placeholder'.tr(),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 10),

            Text('IMEI 2 (Opcional)', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _imei2Controller,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                hintText: 'IMEI Secundário',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 10),

            Text('Capacidade (GB)', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _capacityController,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                hintText: 'Ex: 128G',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 20),

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
            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD32F2F),
                padding: const EdgeInsets.all(18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                if (_imei1Controller.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('imei_placeholder'.tr())));
                  return;
                }
                _saveIp(_ipController.text.trim());
                _deviceData['imei'] = _imei1Controller.text.trim();
                _deviceData['imei1'] = _imei1Controller.text.trim();
                _deviceData['imei2'] = _imei2Controller.text.trim();
                _deviceData['capacity'] = _capacityController.text.trim();
                _deviceData['triador'] = _triadorController.text.trim();

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
