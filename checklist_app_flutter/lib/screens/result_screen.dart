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
    int totalTests = 5; // Tela, Vibracao, Som, Wifi, USB
    int untested = totalTests - (approved + rejected);

    return Scaffold(
      appBar: AppBar(title: const Text('results_title').tr()),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('device_detected'.tr(), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFD32F2F))),
          Card(
            margin: const EdgeInsets.only(top: 10, bottom: 20),
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('IMEI: ${deviceInfo['imei']}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text('${deviceInfo['brand']} ${deviceInfo['model']}', style: const TextStyle(fontSize: 16)),
                ],
              ),
            ),
          ),
          
          Text('results_title'.tr(), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFD32F2F))),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildResultBox(approved, 'approved'.tr(), Colors.green, Colors.green.shade50),
              _buildResultBox(rejected, 'rejected'.tr(), Colors.red, Colors.red.shade50),
              _buildResultBox(untested, 'untested'.tr(), Colors.grey, Colors.grey.shade100),
            ],
          ),

          const SizedBox(height: 40),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD32F2F),
              padding: const EdgeInsets.all(18),
            ),
            onPressed: _isLoading ? null : () => _sendReport(context, deviceInfo, tests, serverIp),
            child: _isLoading 
                ? const CircularProgressIndicator(color: Colors.white)
                : Text('send_report'.tr(), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ),
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
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(count.toString(), style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
