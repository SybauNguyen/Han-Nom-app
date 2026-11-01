import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  static final TtsService instance = TtsService._internal();
  TtsService._internal();

  FlutterTts? _flutterTts;
  bool _isInitialized = false;
  bool _isSpeaking = false;

  bool get isSpeaking => _isSpeaking;

  Future<void> init() async {
    if (_isInitialized) return;
    try {
      _flutterTts = FlutterTts();

      _flutterTts!.setStartHandler(() {
        _isSpeaking = true;
      });

      _flutterTts!.setCompletionHandler(() {
        _isSpeaking = false;
      });

      _flutterTts!.setErrorHandler((msg) {
        _isSpeaking = false;
        debugPrint('TTS Error: $msg');
      });

      _isInitialized = true;
    } catch (e) {
      debugPrint('TTS initialization warning: $e');
    }
  }

  /// Phát âm tiếng Trung Quan thoại (Mandarin / Pinyin)
  Future<void> speakChinese(String text) async {
    try {
      await init();
      if (_flutterTts == null) return;

      await _flutterTts!.stop();
      await _flutterTts!.setLanguage("zh-CN");
      await _flutterTts!.setSpeechRate(0.42); // Tốc độ vừa phải cho người học
      await _flutterTts!.setPitch(1.0);
      await _flutterTts!.speak(text);
    } catch (e) {
      debugPrint('Error speaking Chinese: $e');
    }
  }

  /// Phát âm tiếng Nhật (On'yomi / Kun'yomi)
  Future<void> speakJapanese(String text) async {
    try {
      await init();
      if (_flutterTts == null) return;

      await _flutterTts!.stop();
      await _flutterTts!.setLanguage("ja-JP");
      await _flutterTts!.setSpeechRate(0.45);
      await _flutterTts!.setPitch(1.0);
      await _flutterTts!.speak(text);
    } catch (e) {
      debugPrint('Error speaking Japanese: $e');
    }
  }

  /// Phát âm tiếng Việt (cho âm Hán-Việt hoặc nghĩa)
  Future<void> speakVietnamese(String text) async {
    try {
      await init();
      if (_flutterTts == null) return;

      await _flutterTts!.stop();
      await _flutterTts!.setLanguage("vi-VN");
      await _flutterTts!.setSpeechRate(0.5);
      await _flutterTts!.setPitch(1.0);
      await _flutterTts!.speak(text);
    } catch (e) {
      debugPrint('Error speaking Vietnamese: $e');
    }
  }

  Future<void> stop() async {
    try {
      if (_flutterTts != null) {
        await _flutterTts!.stop();
        _isSpeaking = false;
      }
    } catch (_) {}
  }
}
