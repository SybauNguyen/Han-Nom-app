import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Một engine TTS dùng chung cho toàn ứng dụng.
///
/// Mọi yêu cầu phát âm được xếp tuần tự để không xảy ra tình trạng một màn hình
/// đổi locale trong khi màn hình khác vẫn đang phát âm.
class TtsService {
  static final TtsService instance = TtsService._internal();
  TtsService._internal();

  FlutterTts? _flutterTts;
  bool _isInitialized = false;
  bool _isSpeaking = false;
  Future<void>? _initializing;
  Future<void> _queue = Future<void>.value();

  bool get isSpeaking => _isSpeaking;

  Future<void> init() async {
    if (_isInitialized) return;

    final pendingInitialization = _initializing;
    if (pendingInitialization != null) {
      await pendingInitialization;
      return;
    }

    final completer = Completer<void>();
    _initializing = completer.future;

    try {
      final engine = FlutterTts();
      _flutterTts = engine;

      engine.setStartHandler(() => _isSpeaking = true);
      engine.setCompletionHandler(() => _isSpeaking = false);
      engine.setCancelHandler(() => _isSpeaking = false);
      engine.setErrorHandler((message) {
        _isSpeaking = false;
        debugPrint('TTS error: $message');
      });

      // Đảm bảo Future speak() chỉ hoàn tất khi câu đọc đã phát xong.
      await engine.awaitSpeakCompletion(true);
      _isInitialized = true;
    } catch (error) {
      _flutterTts = null;
      _isInitialized = false;
      debugPrint('TTS initialization failed: $error');
    } finally {
      _initializing = null;
      if (!completer.isCompleted) completer.complete();
    }
  }

  Future<void> _enqueueSpeak({
    required String text,
    required String locale,
    required double speechRate,
    required String label,
  }) {
    final normalizedText = text.trim();
    if (normalizedText.isEmpty) return Future<void>.value();

    final request = _queue.then((_) async {
      await _speakNow(
        text: normalizedText,
        locale: locale,
        speechRate: speechRate,
        label: label,
      );
    });

    // Một yêu cầu lỗi không được làm hỏng hàng đợi của các yêu cầu sau.
    _queue = request.then<void>(
      (_) {},
      onError: (Object error, StackTrace stackTrace) {
        debugPrint('TTS queue error ($label): $error');
      },
    );
    return _queue;
  }

  Future<void> _speakNow({
    required String text,
    required String locale,
    required double speechRate,
    required String label,
  }) async {
    try {
      await init();
      final engine = _flutterTts;
      if (engine == null || !_isInitialized) {
        debugPrint('TTS unavailable; skipped $label ($locale).');
        return;
      }

      // Cấu hình locale và tốc độ trong cùng một tác vụ tuần tự.
      await engine.stop();
      final languageResult = await engine.setLanguage(locale);
      if (languageResult == false) {
        debugPrint('TTS locale unavailable: $locale ($label).');
        return;
      }
      await engine.setSpeechRate(speechRate);
      await engine.setPitch(1.0);

      final speakResult = await engine.speak(text);
      if (speakResult == 0 || speakResult == false) {
        debugPrint('TTS engine rejected utterance: $label ($locale).');
      }
    } catch (error) {
      _isSpeaking = false;
      debugPrint('TTS playback failed ($label, $locale): $error');
    }
  }

  /// Âm Hán-Việt là lớp phát âm chính của ứng dụng.
  Future<void> speakVietnamese(String text) => _enqueueSpeak(
        text: text,
        locale: 'vi-VN',
        speechRate: 0.48,
        label: 'Hán-Việt',
      );

  /// Quan thoại: đọc hình thể chữ giản thể/truyền thống bằng giọng zh-CN.
  Future<void> speakChinese(String text) => _enqueueSpeak(
        text: text,
        locale: 'zh-CN',
        speechRate: 0.42,
        label: 'Quan thoại',
      );

  /// Hán-Nhật: truyền cách đọc Kana (ví dụ チュウ), không truyền Kanji mơ hồ.
  Future<void> speakJapanese(String kanaReading) => _enqueueSpeak(
        text: kanaReading,
        locale: 'ja-JP',
        speechRate: 0.45,
        label: 'Hán-Nhật On’yomi',
      );

  /// Dừng phát âm ngay lập tức (ví dụ khi ứng dụng đóng hoặc rời màn hình).
  Future<void> stop() async {
    final engine = _flutterTts;
    if (engine == null) return;
    try {
      await engine.stop();
      _isSpeaking = false;
    } catch (error) {
      debugPrint('TTS stop failed: $error');
    }
  }
}
