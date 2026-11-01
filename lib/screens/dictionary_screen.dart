import 'package:flutter/material.dart';

import '../core/database/database_service.dart';
import '../core/theme/app_colors.dart';
import '../data/han_character.dart';
import '../data/han_seed_data.dart';
import '../services/tts_service.dart';
import '../state/app_state.dart';
import '../widgets/type_badge.dart';
import 'character_detail_screen.dart';

class DictionaryScreen extends StatefulWidget {
  final AppState appState;
  final DatabaseService databaseService;
  const DictionaryScreen({super.key, required this.appState, required this.databaseService});

  @override
  State<DictionaryScreen> createState() => _DictionaryScreenState();
}

class _DictionaryScreenState extends State<DictionaryScreen> {
  final TextEditingController _controller = TextEditingController();
  String _query = '';
  String _typeFilter = 'Tất cả';
  List<HanCharacter> _results = [];
  bool _isSearching = true;
  int _matchCount = 0;
  int _requestGeneration = 0;
  static const int _pageSize = 100;

  @override
  void initState() {
    super.initState();
    _loadResults(reset: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _setQuery(String value) {
    _controller.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
    setState(() => _query = value);
    _loadResults(reset: true);
  }

  Future<void> _loadResults({required bool reset}) async {
    final request = ++_requestGeneration;
    final query = _query;
    final type = _typeFilter;
    final offset = reset ? 0 : _results.length;
    if (reset && mounted) setState(() => _isSearching = true);
    try {
      final count = await widget.databaseService.countDictionary(
        type: type == 'Tất cả' ? null : type,
        query: query,
      );
      final page = await widget.databaseService.searchDictionary(
        query,
        type: type,
        limit: _pageSize,
        offset: offset,
      );
      if (!mounted || request != _requestGeneration) return;
      setState(() {
        _matchCount = count;
        if (reset) {
          _results = page;
        } else {
          _results = [..._results, ...page];
        }
        _isSearching = false;
      });
    } catch (error) {
      if (!mounted || request != _requestGeneration) return;
      setState(() => _isSearching = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không tải được từ điển: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Từ điển Hán-Việt', style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: kGreenLight, borderRadius: BorderRadius.circular(20)),
                child: Text('$_matchCount mục', style: const TextStyle(color: kGreen, fontSize: 12, fontWeight: FontWeight.w900)),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            if (widget.databaseService.lastImportError != null)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFFFCC80)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Color(0xFF9A5A20)),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        'Chưa nạp được dictionary.json. Từ điển có thể chỉ hiện dữ liệu lõi. Hãy kiểm tra assets/data/dictionary.json rồi chạy refresh_web_build.bat. Chi tiết: ${widget.databaseService.lastImportError}',
                        style: const TextStyle(fontSize: 12, height: 1.35, color: Color(0xFF70442F)),
                      ),
                    ),
                  ],
                ),
              ),
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(18, 6, 18, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Tra chữ, nhớ nghĩa, hiểu bộ thủ.', style: TextStyle(color: Colors.black54, fontSize: 14)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _controller,
                    onChanged: (value) {
                      setState(() => _query = value);
                      _loadResults(reset: true);
                    },
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: 'Nhập Hán tự, âm đọc hoặc nghĩa...',
                      prefixIcon: const Icon(Icons.search_rounded, color: kGreen),
                      suffixIcon: _query.isEmpty ? null : IconButton(
                        tooltip: 'Xóa tìm kiếm',
                        onPressed: () => _setQuery(''),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(spacing: 8, runSpacing: 7, children: [
                    for (final type in ['Tất cả', 'Hán', 'Nôm'])
                      ChoiceChip(
                        label: Text(type == 'Hán' ? 'Hán tự' : type == 'Nôm' ? (isNomDataEnabled ? 'Chữ Nôm' : 'Nôm · tạm ẩn') : 'Tất cả'),
                        selected: _typeFilter == type,
                        selectedColor: type == 'Nôm' ? kNomLight : kGreenLight,
                        onSelected: (_) {
                          setState(() => _typeFilter = type);
                          _loadResults(reset: true);
                        },
                      ),
                  ]),
                  const SizedBox(height: 9),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(children: [
                      for (final popular in ['nhất', 'trung', 'học', 'tâm', 'người', 'nghia', 'trời', 'đi']) ...[
                        ActionChip(
                          label: Text(popular),
                          onPressed: () => _setQuery(popular),
                          backgroundColor: Colors.white,
                          side: const BorderSide(color: Color(0xFFE4E9E3)),
                        ),
                        const SizedBox(width: 7),
                      ],
                    ]),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 15, 18, 9),
              child: Row(children: [
                Expanded(child: Text(
                  _query.trim().isEmpty ? (isNomDataEnabled ? 'KHÁM PHÁ HÁN TỰ & CHỮ NÔM' : 'KHÁM PHÁ HÁN TỰ · NÔM ĐANG CHUẨN HÓA') : 'KẾT QUẢ TRA CỨU',
                  style: const TextStyle(fontSize: 12, letterSpacing: 1.2, fontWeight: FontWeight.w900, color: kGreen),
                )),
                Text('${_results.length}/$_matchCount', style: const TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.w700)),
              ]),
            ),
            Expanded(
              child: _isSearching && _results.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : _results.isEmpty
                      ? _DictionaryEmptyState(query: _query, typeFilter: _typeFilter)
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                          itemCount: _results.length + (_results.length < _matchCount ? 1 : 0),
                          separatorBuilder: (_, __) => const SizedBox(height: 9),
                          itemBuilder: (context, index) {
                            if (index >= _results.length) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                child: OutlinedButton.icon(
                                  onPressed: _isSearching ? null : () => _loadResults(reset: false),
                                  icon: _isSearching ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.expand_more_rounded),
                                  label: Text('Tải thêm mục từ (${_results.length}/$_matchCount)'),
                                ),
                              );
                            }
                            final character = _results[index];
                            return Card(
                              elevation: 1,
                              margin: EdgeInsets.zero,
                              clipBehavior: Clip.antiAlias,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                              child: InkWell(
                                onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                                  builder: (_) => CharacterDetailScreen(character: character, appState: widget.appState, databaseService: widget.databaseService),
                                )),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 13),
                                  child: Row(children: [
                                    Container(
                                      width: 60,
                                      height: 64,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(color: character.isNom ? kNomLight : kGreenLight, borderRadius: BorderRadius.circular(15)),
                                      child: Text(character.character, style: const TextStyle(fontFamilyFallback: ['NomNaTong', 'HanNomB']).copyWith(fontSize: 34, height: 1.1, color: character.isNom ? kOrange : kGreen, fontWeight: FontWeight.w700)),
                                    ),
                                    const SizedBox(width: 13),
                                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      Row(children: [
                                        Expanded(child: Text(character.isNom ? 'Cách đọc: ${character.hanVietReading}' : character.hanVietReading.toUpperCase(), style: const TextStyle(fontSize: 15, letterSpacing: 0.2, fontWeight: FontWeight.w900, color: Color(0xFF20372C)))),
                                        const SizedBox(width: 4),
                                        InkWell(
                                          onTap: () => TtsService.instance.speakChinese(character.character),
                                          borderRadius: BorderRadius.circular(12),
                                          child: const Padding(padding: EdgeInsets.all(4), child: Icon(Icons.volume_up_rounded, size: 18, color: kGreen)),
                                        ),
                                        const SizedBox(width: 4),
                                        TypeBadge(type: character.type, compact: true),
                                      ]),
                                      const SizedBox(height: 4),
                                      Text(character.meaning, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, height: 1.3, color: Colors.black87)),
                                      if (character.hasProvisionalImportedMeaning) const Padding(padding: EdgeInsets.only(top: 3), child: Text('Cách đọc từ RIME; chưa có nghĩa biên tập', style: TextStyle(fontSize: 10, color: kOrange, fontWeight: FontWeight.w700))),
                                      if (character.examples.isNotEmpty) ...[
                                        const SizedBox(height: 5),
                                        Text('Ví dụ: ${character.examples.first}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: Colors.black45)),
                                      ],
                                      if (!character.inCurriculum) const Padding(padding: EdgeInsets.only(top: 4), child: Text('Từ điển mở rộng', style: TextStyle(fontSize: 10, color: kBlue, fontWeight: FontWeight.w800))),
                                    ])),
                                    const SizedBox(width: 8),
                                    Column(mainAxisSize: MainAxisSize.min, children: [
                                      const Text('BỘ THỦ', style: TextStyle(fontSize: 9, letterSpacing: 0.6, fontWeight: FontWeight.w900, color: Colors.black45)),
                                      const SizedBox(height: 3),
                                      Container(
                                        constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
                                        alignment: Alignment.center,
                                        padding: const EdgeInsets.symmetric(horizontal: 6),
                                        decoration: BoxDecoration(color: const Color(0xFFFFF0E6), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFF2D6C4))),
                                        child: Text(character.radical.isEmpty ? '—' : character.radical, style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w800, color: kOrange, fontFamilyFallback: ['NomNaTong', 'HanNomB'])),
                                      ),
                                    ]),
                                    const SizedBox(width: 2),
                                    const Icon(Icons.chevron_right_rounded, color: Colors.black38, size: 20),
                                  ]),
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DictionaryEmptyState extends StatelessWidget {
  final String query;
  final String typeFilter;
  const _DictionaryEmptyState({required this.query, required this.typeFilter});

  @override
  Widget build(BuildContext context) {
    final hasQuery = query.trim().isNotEmpty;
    final nomPaused = typeFilter == 'Nôm' && !isNomDataEnabled;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(hasQuery ? Icons.search_off_rounded : Icons.menu_book_rounded, size: 62, color: Colors.black26),
            const SizedBox(height: 14),
            Text(nomPaused ? 'Dữ liệu chữ Nôm đang tạm ẩn' : hasQuery ? 'Chưa tìm thấy “$query”' : 'Từ điển đang trống', textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 7),
            Text(
              nomPaused ? 'Các mục Nôm cũ đã được gỡ để chuẩn hóa lại Unicode và cách đọc. Chức năng tra cứu vẫn được giữ để dùng với bộ dữ liệu chuẩn sau này.' : hasQuery ? 'Thử tìm bằng Hán tự, âm Hán-Việt, nghĩa hoặc bộ thủ. Bạn cũng có thể gõ tiếng Việt không dấu.' : 'Kho dữ liệu hiện hiển thị các mục Hán-Việt đang được hỗ trợ. Dữ liệu Nôm tạm ẩn trong thời gian chuẩn hóa.',
              textAlign: TextAlign.center,
              style: const TextStyle(height: 1.45, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}
