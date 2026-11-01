import 'package:flutter/material.dart';

import '../data/models/cjk_character.dart';
import '../services/tts_service.dart';

/// Cụm nút phát âm dùng chung cho các màn hình có một chữ Hán.
///
/// Hán-Việt luôn được hiển thị. Chỉ hiển thị nút ngôn ngữ phụ đang được chọn.
/// Với Hán-Nhật, mỗi nút đọc trực tiếp một giá trị On'yomi Kana; tối đa hai nút.
class CharacterPronunciationControls extends StatelessWidget {
  final String hanVietReading;
  final SupplementaryLanguage supplementaryLanguage;
  final CjkCharacter? cjkCharacter;
  final bool showHanViet;
  final bool compact;

  const CharacterPronunciationControls({
    super.key,
    required this.hanVietReading,
    required this.supplementaryLanguage,
    this.cjkCharacter,
    this.showHanViet = true,
    this.compact = true,
  });

  Widget _speakerButton({
    required String tooltip,
    required VoidCallback onPressed,
    required Color color,
  }) {
    final dimension = compact ? 34.0 : 40.0;
    return IconButton(
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: BoxConstraints.tightFor(width: dimension, height: dimension),
      icon: Icon(Icons.volume_up_rounded, color: color, size: compact ? 19 : 21),
      onPressed: onPressed,
    );
  }

  @override
  Widget build(BuildContext context) {
    final controls = <Widget>[];

    if (showHanViet && hanVietReading.trim().isNotEmpty) {
      controls.add(_speakerButton(
        tooltip: 'Nghe âm Hán-Việt: $hanVietReading',
        color: const Color(0xFFCC6B3D),
        onPressed: () => TtsService.instance.speakVietnamese(hanVietReading),
      ));
    }

    final record = cjkCharacter;
    if (record == null) {
      return Wrap(
        spacing: 2,
        runSpacing: 2,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: controls,
      );
    }

    switch (supplementaryLanguage) {
      case SupplementaryLanguage.mandarin:
        final pinyin = record.readingsPinyin
            .map((reading) => reading.trim())
            .firstWhere((reading) => reading.isNotEmpty, orElse: () => '');
        if (pinyin.isNotEmpty) {
          if (!compact) {
            controls.add(Text(
              pinyin,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF28664F),
                fontWeight: FontWeight.w800,
              ),
            ));
          }
          controls.add(_speakerButton(
            tooltip: 'Nghe Quan thoại · $pinyin',
            color: const Color(0xFF28664F),
            onPressed: () => TtsService.instance.speakChinese(
              record.getDisplayChar(SupplementaryLanguage.mandarin),
            ),
          ));
        }
        break;

      case SupplementaryLanguage.japanese:
        final onyomi = record.readingsOnyomi
            .map((reading) => reading.trim())
            .where((reading) => reading.isNotEmpty)
            .toSet()
            .take(2);
        for (final reading in onyomi) {
          if (!compact) {
            controls.add(Text(
              reading,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF28664F),
                fontWeight: FontWeight.w800,
              ),
            ));
          }
          controls.add(_speakerButton(
            tooltip: 'Nghe Hán-Nhật · On’yomi $reading',
            color: const Color(0xFF28664F),
            onPressed: () => TtsService.instance.speakJapanese(reading),
          ));
        }
        break;

      case SupplementaryLanguage.none:
      case SupplementaryLanguage.hanja:
      case SupplementaryLanguage.cantonese:
        // Hán-Hàn và Quảng Đông chưa được bật trong sản phẩm.
        break;
    }

    return Wrap(
      spacing: 2,
      runSpacing: 2,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: controls,
    );
  }
}
