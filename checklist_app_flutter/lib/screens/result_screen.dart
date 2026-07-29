import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ResultScreen extends StatefulWidget {
  const ResultScreen({super.key});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  bool _isLoading = false;

  // Map of test keys to translation keys and icons
  static const Map<String, Map<String, dynamic>> _testMeta = {
    'tela': {'label': 'test_screen', 'icon': Icons.touch_app},
    'telaRgb': {'label': 'test_rgb', 'icon': Icons.color_lens},
    'vibracao': {'label': 'test_vibration', 'icon': Icons.vibration},
    'sensorProximidade': {'label': 'test_proximity', 'icon': Icons.sensors},
    'som': {'label': 'test_sound', 'icon': Icons.volume_up},
    'brilho': {'label': 'test_brightness', 'icon': Icons.brightness_high},
    'cameraFrontal': {'label': 'test_front_camera', 'icon': Icons.camera_front},
    'cameraTraseira': {'label': 'test_rear_camera', 'icon': Icons.camera_rear},
    'wifi': {'label': 'test_wifi', 'icon': Icons.wifi},
    'chip': {'label': 'test_sim', 'icon': Icons.sim_card},
    'usb': {'label': 'test_usb', 'icon': Icons.usb},
    'estetica': {'label': 'test_aesthetics', 'icon': Icons.phone_android},
  };

  void _sendReport(BuildContext context, Map<String, dynamic> deviceInfo, Map<String, bool?> tests, String ip) async {
    if (ip.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('IP do servidor não fornecido!')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('http://$ip:3000/api/report'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'device': deviceInfo,
          'tests': tests,
          'date': DateTime.now().toIso8601String(),
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Relatório PDF gerado no Desktop!'), backgroundColor: Colors.green));
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      } else {
        throw Exception('Server error');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erro ao comunicar com o servidor.'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final deviceInfo = args['deviceInfo'];
    final tests = args['tests'] as Map<String, bool?>;
    final serverIp = args['serverIp'] as String;

    int approved = tests.values.where((v) => v == true).length;
    int rejected = tests.values.where((v) => v == false).length;
    int totalTests = _testMeta.length;
    int untested = totalTests - (approved + rejected);

    return Scaffold(
      appBar: AppBar(
        title: const Text('results_title').tr(),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
      ),
      backgroundColor: const Color(0xFFF8F9FA),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Device card
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD32F2F).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.smartphone, color: Color(0xFFD32F2F), size: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${deviceInfo['brand']} ${deviceInfo['model']}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('IMEI: ${deviceInfo['imei'] ?? '-'}', style: const TextStyle(fontSize: 13, color: Colors.grey)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Summary boxes
          Row(
            children: [
              _buildResultBox(approved, 'approved'.tr(), Colors.green, Colors.green.shade50),
              _buildResultBox(rejected, 'rejected'.tr(), Colors.red, Colors.red.shade50),
              _buildResultBox(untested, 'untested'.tr(), Colors.grey, Colors.grey.shade100),
            ],
          ),
          const SizedBox(height: 24),

          // Test details
          Text('test_details'.tr(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFD32F2F))),
          const SizedBox(height: 12),

          // Individual test results
          ..._testMeta.entries.map((entry) {
            final key = entry.key;
            final label = (entry.value['label'] as String).tr();
            final icon = entry.value['icon'] as IconData;
            final result = tests[key];

            Color statusColor;
            IconData statusIcon;
            String statusText;

            if (result == true) {
              statusColor = Colors.green;
              statusIcon = Icons.check_circle;
              statusText = 'approved'.tr();
            } else if (result == false) {
              statusColor = Colors.red;
              statusIcon = Icons.cancel;
              statusText = 'rejected'.tr();
            } else {
              statusColor = Colors.grey;
              statusIcon = Icons.help_outline;
              statusText = 'untested'.tr();
            }

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: ListTile(
                leading: Icon(icon, color: const Color(0xFFD32F2F)),
                title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(statusText, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(width: 6),
                    Icon(statusIcon, color: statusColor, size: 22),
                  ],
                ),
              ),
            );
          }),

          const SizedBox(height: 30),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD32F2F),
              padding: const EdgeInsets.all(18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 3,
            ),
            onPressed: _isLoading ? null : () => _sendReport(context, deviceInfo, tests, serverIp),
            child: _isLoading 
                ? const CircularProgressIndicator(color: Colors.white)
                : Text('send_report'.tr(), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildResultBox(int count, String label, Color color, Color bgColor) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: bgColor,
          border: Border.all(color: color, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(count.toString(), style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
