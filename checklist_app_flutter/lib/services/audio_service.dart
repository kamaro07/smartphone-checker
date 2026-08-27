// lib/services/audio_service.dart
import 'package:flutter_sound/flutter_sound.dart';
import 'dart:async';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class AudioService {
  static final _recorder = FlutterSoundRecorder();

  static Future<String> record15Seconds() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/audio_test_${DateTime.now().millisecondsSinceEpoch}.aac';
      await _recorder.openRecorder();
      await _recorder.startRecorder(
        toFile: filePath,
        codec: Codec.aacADTS,
      );
      await Future.delayed(const Duration(seconds: 15));
      await _recorder.stopRecorder();
      await _recorder.closeRecorder();
      final file = File(filePath);
      return file.existsSync() ? 'Recorded ${file.lengthSync()} bytes' : 'File not created';
    } catch (e) {
      return 'Error: $e';
    }
  }
}
