import 'package:flutter_sound/flutter_sound.dart';
import 'dart:async';

class AudioService {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();

  Future<bool> test() async {
    try {
      await _recorder.openRecorder();
      await _recorder.startRecorder(toFile: 'audio_test.wav');
      // Record for 10 seconds
      await Future.delayed(const Duration(seconds: 10));
      await _recorder.stopRecorder();
      await _recorder.closeRecorder();
      return true;
    } catch (e) {
      return false;
    }
  }
}
