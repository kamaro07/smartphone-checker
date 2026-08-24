import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class ProximityTestScreen extends StatelessWidget {
  const ProximityTestScreen({super.key});

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
              const Icon(
                Icons.sensors,
                size: 100,
                color: Color(0xFFD32F2F),
              ),
              const SizedBox(height: 32),
              Text(
                'proximity_cover'.tr(),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 20),
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
