import 'package:flutter/material.dart';

import '../core/database/database_service.dart';
import '../data/han_character.dart';
import '../data/models/cjk_character.dart';
import '../services/tts_service.dart';
import '../widgets/hanzi_canvas.dart';

const Color _kGreen = Color(0xFF28664F);
const Color _kGreenLight = Color(0xFFE4F1E8);
const Color _kOrange = Color(0xFFCC6B3D);
const Color _kRed = Color(0xFFD94343);

class WritingPracticeScreen extends StatefulWidget {
  final HanCharacter character;
  final DatabaseService? databaseService;

  const WritingPracticeScreen({
    super.key,
    required this.character,
    this.databaseService,
  });

  @override
  State<WritingPracticeScreen> createState() => _WritingPracticeScreenState();
}

class _WritingPracticeScreenState extends State<WritingPracticeScreen> {
  final GlobalKey<HanziCanvasState> _canvasKey = GlobalKey<HanziCanvasState>();
  double _templateOpacity = 0.25;
  int _strokeCount = 0;
  CjkCharacter? _cjkRecord;

  @override
  void initState() {
    super.initState();
    _loadCjkData();
  }

  Future<void> _loadCjkData() async {
    if (widget.databaseService != null && !widget.character.isNom) {
      final record = await widget.databaseService!.getCjkCharacter(widget.character.character);
      if (mounted) {
        setState(() => _cjkRecord = record);
      }
    }
  }

  void _toggleOpacity() {
    setState(() {
      if (_templateOpacity == 0.25) {
        _templateOpacity = 0.5;
      } else if (_templateOpacity == 0.5) {
        _templateOpacity = 0.0;
      } else {
        _templateOpacity = 0.25;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final char = widget.character;
    final screenWidth = MediaQuery.of(context).size.width;
    final canvasSize = (screenWidth - 44).clamp(260.0, 360.0);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          char.isNom ? 'Luyện viết chữ Nôm' : 'Luyện viết Hán tự',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'Phát âm tiếng Trung (Pinyin)',
            icon: const Icon(Icons.volume_up_rounded, color: _kGreen, size: 26),
            onPressed: () => TtsService.instance.speakChinese(char.character),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Khung tóm tắt thông tin chữ và đa âm
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: char.isNom ? const Color(0xFFFFEBDD) : _kGreenLight,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        char.character,
                        style: TextStyle(
                          fontSize: 32,
                          color: char.isNom ? _kOrange : _kGreen,
                          fontWeight: FontWeight.bold,
                          fontFamilyFallback: const ['NomNaTong', 'HanNomB'],
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                char.isNom ? char.hanVietReading : char.hanVietReading.toUpperCase(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 18,
                                  color: _kOrange,
                                ),
                              ),
                              const SizedBox(width: 6),
                              InkWell(
                                onTap: () => TtsService.instance.speakVietnamese(char.hanVietReading),
                                child: const Icon(Icons.volume_down_rounded, size: 20, color: _kOrange),
                              ),
                              if (_cjkRecord?.pinyin.isNotEmpty ?? false) ...[
                                const SizedBox(width: 10),
                                Text(
                                  _cjkRecord!.pinyin.first,
                                  style: const TextStyle(fontSize: 14, color: _kGreen, fontWeight: FontWeight.w800),
                                ),
                                const SizedBox(width: 4),
                                InkWell(
                                  onTap: () => TtsService.instance.speakChinese(char.character),
                                  child: const Icon(Icons.volume_up_rounded, size: 18, color: _kGreen),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${char.meaning} • Bộ: ${char.radical.isEmpty ? '—' : char.radical}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13, color: Color(0xFF334A3C)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Khung luyện viết thư pháp
              HanziCanvas(
                key: _canvasKey,
                character: char.character,
                size: canvasSize,
                templateOpacity: _templateOpacity,
                onStrokeCountChanged: (count) {
                  setState(() => _strokeCount = count);
                },
              ),

              const SizedBox(height: 16),

              // Thanh công cụ điều khiển nét viết
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: _toggleOpacity,
                    icon: Icon(
                      _templateOpacity > 0 ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                      size: 19,
                    ),
                    label: Text(
                      _templateOpacity == 0.0
                          ? 'Mẫu: Ẩn'
                          : _templateOpacity == 0.25
                              ? 'Mẫu: Vừa'
                              : 'Mẫu: Rõ',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () => _canvasKey.currentState?.undo(),
                    icon: const Icon(Icons.undo_rounded, size: 19),
                    label: const Text('Nét trước', style: TextStyle(fontSize: 13)),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () => _canvasKey.currentState?.clear(),
                    icon: const Icon(Icons.delete_outline_rounded, size: 19, color: _kRed),
                    label: const Text('Xóa hết', style: TextStyle(fontSize: 13, color: _kRed)),
                  ),
                ],
              ),

              const SizedBox(height: 10),
              Text(
                'Đã viết: $_strokeCount nét',
                style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w600, fontSize: 13),
              ),

              const SizedBox(height: 20),

              // Nút hoàn tất luyện viết
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Rất tốt! Bạn đã luyện xong chữ “${char.character}”.'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.check_circle_outline_rounded),
                  label: const Text('Hoàn tất luyện viết'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
