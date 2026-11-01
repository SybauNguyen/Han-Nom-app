import 'package:flutter/material.dart';

import '../core/database/database_service.dart';
import '../core/theme/app_colors.dart';
import '../data/han_character.dart';
import '../data/models/cjk_character.dart';
import '../state/app_state.dart';
import '../widgets/type_badge.dart';
import 'writing_practice_screen.dart';

class CharacterDetailScreen extends StatelessWidget {
  final HanCharacter character;
  final AppState appState;
  final DatabaseService? databaseService;
  const CharacterDetailScreen({super.key, required this.character, required this.appState, this.databaseService});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(character.isNom ? 'Thẻ học chữ Nôm' : 'Thẻ học Hán tự', style: const TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
            tooltip: 'Luyện viết chữ này',
            icon: const Icon(Icons.brush_rounded, color: kGreen),
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute<void>(
                builder: (_) => WritingPracticeScreen(character: character),
              ));
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
            decoration: BoxDecoration(color: character.isNom ? kNomLight : kGreenLight, borderRadius: BorderRadius.circular(26)),
            child: Column(children: [
              Text(character.character, style: const TextStyle(fontFamilyFallback: ['NomNaTong', 'HanNomB']).copyWith(fontSize: 104, height: 1.15, fontWeight: FontWeight.w500, color: character.isNom ? kOrange : kGreen)),
              const SizedBox(height: 8),
              TypeBadge(type: character.type),
              const SizedBox(height: 8),
              Text(character.isNom ? 'CÁCH ĐỌC TIẾNG VIỆT' : 'ÂM HÁN-VIỆT', style: const TextStyle(color: Colors.black45, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.1)),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(character.isNom ? character.hanVietReading : character.hanVietReading.toUpperCase(), style: const TextStyle(color: kOrange, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
                ],
              ),
              if (!character.isNom && appState.supplementaryLanguage != SupplementaryLanguage.none) ...[
                const SizedBox(height: 12),
                FutureBuilder<CjkCharacter?>(
                  future: databaseService?.getCjkCharacter(character.character),
                  builder: (context, snapshot) {
                    final language = appState.supplementaryLanguage;
                    final record = snapshot.data;
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SizedBox(height: 25, width: 25, child: CircularProgressIndicator(strokeWidth: 2));
                    }
                    if (record == null || !record.hasReadingFor(language)) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.72), borderRadius: BorderRadius.circular(12)),
                        child: Text(
                          'Chưa có dữ liệu ${language.label} cho chữ này',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.w600),
                        ),
                      );
                    }
                    final displayChar = record.getDisplayChar(language);
                    final readings = record.getReadings(language).where((reading) => reading.trim().isNotEmpty).take(language == SupplementaryLanguage.japanese ? 2 : 1).join(' · ');
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.82), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFDCE8DD))),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 54,
                            height: 54,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(color: kGreenLight, borderRadius: BorderRadius.circular(12)),
                            child: Text(displayChar, style: const TextStyle(fontSize: 31, height: 1.0, fontWeight: FontWeight.w700, color: kGreen, fontFamilyFallback: ['NomNaTong', 'HanNomB'])),
                          ),
                          const SizedBox(width: 10),
                          Container(width: 1, height: 46, color: const Color(0xFFDCE8DD)),
                          const SizedBox(width: 10),
                          Flexible(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text('${language.label.toUpperCase()} · ${language.readingLabel.toUpperCase()}', style: const TextStyle(fontSize: 9, letterSpacing: 0.8, color: Colors.black45, fontWeight: FontWeight.w900)),
                              const SizedBox(height: 2),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(readings, style: const TextStyle(fontSize: 20, color: kGreen, fontWeight: FontWeight.w900)),
                                ],
                              ),
                              Text(language.characterFormLabel, style: const TextStyle(fontSize: 10, color: Colors.black45)),
                            ]),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
              const SizedBox(height: 7),
              Text(character.meaning, textAlign: TextAlign.center, style: const TextStyle(fontSize: 17, color: Color(0xFF32473B))),
              const SizedBox(height: 14),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: character.isNom ? kOrange : kGreen,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(200, 44),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute<void>(
                    builder: (_) => WritingPracticeScreen(character: character, databaseService: databaseService, appState: appState),
                  ));
                },
                icon: const Icon(Icons.brush_rounded, size: 19),
                label: const Text('Luyện viết chữ này'),
              ),
              if (character.hasProvisionalImportedMeaning) ...[
                const SizedBox(height: 10),
                const Text('Lưu ý: dữ liệu RIME cung cấp cách gõ/cách đọc, không phải định nghĩa Hán-Nôm đã được biên tập.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, height: 1.35, color: kOrange)),
              ],
            ]),
          ),
          const SizedBox(height: 20),
          const Text('THÔNG TIN CHỮ', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1.3, color: kGreen)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF0E6),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFF2D6C4)),
            ),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(17)),
                  child: Text(character.radical.isEmpty ? '—' : character.radical, style: const TextStyle(fontSize: 38, fontWeight: FontWeight.w800, color: kOrange, fontFamilyFallback: ['NomNaTong', 'HanNomB'])),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(character.isNom ? 'THÀNH PHẦN GỢI NGHĨA' : 'BỘ THỦ', style: const TextStyle(fontSize: 11, letterSpacing: 1.0, color: kOrange, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 5),
                      Text(character.isNom ? 'Thành phần Hán tự dùng để gợi nghĩa hoặc tra cứu' : 'Bộ gốc dùng để tra cứu chữ', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF653E2B))),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          _InfoCard(label: 'Cấu tạo', value: character.structure, icon: Icons.dashboard_customize_outlined),
          if (character.mnemonic != null && character.mnemonic!.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFFFFF7DF), borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFF3DEA0))),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Icon(Icons.lightbulb_rounded, color: Color(0xFFB98216), size: 25),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('MẸO NHỚ', style: TextStyle(fontSize: 11, letterSpacing: 1.2, fontWeight: FontWeight.w900, color: Color(0xFF9A6D0D))),
                  const SizedBox(height: 5),
                  Text(character.mnemonic!, style: const TextStyle(fontSize: 14, height: 1.45, color: Color(0xFF5E4A25))),
                ])),
              ]),
            ),
          ],
          const SizedBox(height: 8),
          _InfoCard(label: 'Độ khó', value: 'Cấp ${character.difficulty}', icon: Icons.stairs_outlined),
          const SizedBox(height: 20),
          const Text('TỪ GHÉP GỢI Ý', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1.3, color: kGreen)),
          const SizedBox(height: 8),
          if (character.examples.isEmpty)
            const Text('Chưa có từ ghép cho chữ này.')
          else
            for (final example in character.examples)
              Card(child: ListTile(leading: const Icon(Icons.auto_stories_outlined, color: kGreen), title: Text(example, style: const TextStyle(fontWeight: FontWeight.w700)))),
          const SizedBox(height: 18),
          AnimatedBuilder(
            animation: appState,
            builder: (context, _) => Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
              child: Row(children: [const Icon(Icons.insights_rounded, color: kBlue), const SizedBox(width: 10), Expanded(child: Text('Mức thuần thục: ${appState.masteryOf(character.character)}/5', style: const TextStyle(fontWeight: FontWeight.w800))), const Icon(Icons.auto_awesome, color: kOrange)]),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: kGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute<void>(
                builder: (_) => WritingPracticeScreen(character: character, databaseService: databaseService, appState: appState),
              ));
            },
            icon: const Icon(Icons.brush_rounded, size: 20),
            label: Text('Luyện viết chữ “${character.character}” (Có Bút thuận)', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _InfoCard({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Card(child: ListTile(leading: Icon(icon, color: kGreen), title: Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)), subtitle: Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF20372C)))));
  }
}
