import 'package:flutter/material.dart';

import '../core/database/database_service.dart';
import '../core/theme/app_colors.dart';
import '../data/han_character.dart';
import '../data/han_seed_data.dart';
import '../state/app_state.dart';
import '../widgets/type_badge.dart';
import 'character_detail_screen.dart';
import 'lesson_screen.dart';

bool nomCharacterIsUnlocked(HanCharacter character, AppState appState) {
  if (!character.isNom || appState.unlockedNomLessons <= 0) return false;
  final unlockedSymbols = nomLessonUnits
      .take(appState.unlockedNomLessons)
      .expand((unit) => unit.characters)
      .toSet();
  return unlockedSymbols.contains(character.character);
}

class ReviewScreen extends StatelessWidget {
  final AppState appState;
  final DatabaseService? databaseService;
  const ReviewScreen({super.key, required this.appState, this.databaseService});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appState,
      builder: (context, _) {
        final reviewCharacters = seedCharacters
            .where((character) => character.isHan || nomCharacterIsUnlocked(character, appState))
            .toList()
          ..sort((a, b) => appState.masteryOf(a.character).compareTo(appState.masteryOf(b.character)));
        final due = reviewCharacters.take(8).toList();
        return Scaffold(
          appBar: AppBar(title: const Text('Ôn tập mỗi ngày', style: TextStyle(fontWeight: FontWeight.w800))),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: kGreenLight, borderRadius: BorderRadius.circular(22)),
                child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Icon(Icons.psychology_alt_rounded, color: kGreen, size: 32),
                  SizedBox(height: 10),
                  Text('Nhớ lâu hơn bằng cách ôn lại', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900, color: Color(0xFF20372C))),
                  SizedBox(height: 6),
                  Text('Các chữ có mức thuần thục thấp được ưu tiên lên đầu danh sách.', style: TextStyle(height: 1.4, color: Colors.black54)),
                ]),
              ),
              const SizedBox(height: 18),
              Row(children: [const Expanded(child: Text('GỢI Ý ÔN TẬP', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2, color: kGreen, fontSize: 12))), Text('${due.length} chữ', style: const TextStyle(color: Colors.black54))]),
              const SizedBox(height: 10),
              for (final character in due)
                Card(
                  child: ListTile(
                    onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => CharacterDetailScreen(character: character, appState: appState, databaseService: databaseService))),
                    leading: Container(width: 48, height: 48, alignment: Alignment.center, decoration: BoxDecoration(color: character.isNom ? kNomLight : kGreenLight, borderRadius: BorderRadius.circular(14)), child: Text(character.character, style: const TextStyle(fontFamilyFallback: ['NomNaTong', 'HanNomB']).copyWith(fontSize: 27, color: character.isNom ? kOrange : kGreen, fontWeight: FontWeight.w600))),
                    title: Row(children: [Expanded(child: Text(character.isNom ? 'Cách đọc: ${character.hanVietReading}' : character.hanVietReading.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900))), TypeBadge(type: character.type, compact: true)]),
                    subtitle: Text(character.hasProvisionalImportedMeaning ? 'Nghĩa chưa được biên tập  •  Thuần thục ${appState.masteryOf(character.character)}/5' : '${character.meaning}  •  Thuần thục ${appState.masteryOf(character.character)}/5'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                  ),
                ),
              const SizedBox(height: 14),
              ElevatedButton.icon(
                onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => LessonScreen(appState: appState, reviewMode: true))),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Bắt đầu ôn tập'),
              ),
            ],
          ),
        );
      },
    );
  }
}
