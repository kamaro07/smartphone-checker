import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:screen_brightness/screen_brightness.dart';

class BrightnessTestScreen extends StatefulWidget {
  const BrightnessTestScreen({super.key});

  @override
  State<BrightnessTestScreen> createState() => _BrightnessTestScreenState();
}

class _BrightnessTestScreenState extends State<BrightnessTestScreen> {
  double? _initialBrightness;

  @override
  void initState() {
    super.initState();
    _saveInitialBrightness();
  }

  Future<void> _saveInitialBrightness() async {
    try {
      _initialBrightness = await ScreenBrightness().current;
    } catch (e) {
      debugPrint('Failed to get current brightness');
    }
  }

  @override
  void dispose() {
    _restoreBrightness();
    super.dispose();
  }

  Future<void> _restoreBrightness() async {
    try {
      if (_initialBrightness != null) {
        await ScreenBrightness().setScreenBrightness(_initialBrightness!);
      }
    } catch (e) {
      debugPrint('Failed to restore brightness');
    }
  }

  Future<void> _setBrightness(double brightness) async {
    try {
      await ScreenBrightness().setScreenBrightness(brightness);
    } catch (e) {
      debugPrint('Failed to set brightness');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('brightness_question'.tr()),
        backgroundColor: const Color(0xFFD32F2F),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFFD32F2F),
                minimumSize: const Size(double.infinity, 60),
                side: const BorderSide(color: Color(0xFFD32F2F)),
              ),
              onPressed: () => _setBrightness(1.0),
              child: Text('brightness_max'.tr()),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFFD32F2F),
                minimumSize: const Size(double.infinity, 60),
                side: const BorderSide(color: Color(0xFFD32F2F)),
              ),
              onPressed: () => _setBrightness(0.1),
              child: Text('brightness_min'.tr()),
            ),
            const SizedBox(height: 48),
            Text(
              'brightness_question'.tr(),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFD32F2F),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text('btn_no'.tr()),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD32F2F),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: () => Navigator.of(context).pop(true),
                    child: Text('btn_yes'.tr()),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
