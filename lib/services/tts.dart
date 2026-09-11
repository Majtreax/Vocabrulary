import 'package:flutter_tts/flutter_tts.dart';

// TEXT TO SPEECH SERVICE
class TtsService {
  static final FlutterTts _tts = FlutterTts();
  static bool _initialized = false;

  // INITIALIZE ENGINE WITH RUSSIAN SETTINGS
  static Future<void> init() async {
    if (_initialized) return;

    await _tts.setLanguage("ru-RU");
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);

    _initialized = true;
  }

  // SPEAK TEXT IN RUSSIAN
  static Future<void> speak(String text) async {
    await init();
    await _tts.stop();
    await _tts.speak(text);
  }

  // STOP ACTIVE SPEECH
  static Future<void> stop() async {
    await _tts.stop();
  }
}
