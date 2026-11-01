import 'dart:async';
import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

class AdService {
  static final AdService instance = AdService._internal();
  AdService._internal();

  /// Hiển thị video quảng cáo nhận thưởng (Rewarded Ad)
  /// Có bộ đếm thời gian 10s chân thực, thanh tiến trình, cảnh báo nếu thoát sớm,
  /// và kích hoạt phần thưởng onRewardGranted khi hoàn thành.
  Future<void> showRewardedAd(
    BuildContext context, {
    required VoidCallback onRewardGranted,
    String rewardDescription = '1 Tim ❤️',
  }) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _RewardedAdDialog(
        rewardDescription: rewardDescription,
        onRewardGranted: onRewardGranted,
      ),
    );
  }
}

class _RewardedAdDialog extends StatefulWidget {
  final String rewardDescription;
  final VoidCallback onRewardGranted;

  const _RewardedAdDialog({
    required this.rewardDescription,
    required this.onRewardGranted,
  });

  @override
  State<_RewardedAdDialog> createState() => _RewardedAdDialogState();
}

class _RewardedAdDialogState extends State<_RewardedAdDialog> {
  static const int _totalSeconds = 10;
  int _secondsRemaining = _totalSeconds;
  Timer? _timer;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_secondsRemaining > 1) {
        setState(() => _secondsRemaining--);
      } else {
        timer.cancel();
        setState(() {
          _secondsRemaining = 0;
          _completed = true;
        });
        widget.onRewardGranted();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _handleClose() {
    if (_completed) {
      Navigator.of(context).pop();
      return;
    }
    // Cảnh báo nếu thoát sớm
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Bỏ lỡ phần thưởng?', style: TextStyle(fontWeight: FontWeight.w900)),
        content: Text(
          'Video chưa kết thúc. Nếu bạn thoát bây giờ, bạn sẽ không nhận được ${widget.rewardDescription}.',
          style: const TextStyle(height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Xem tiếp', style: TextStyle(fontWeight: FontWeight.w800, color: kGreen)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop(true);
              Navigator.of(context).pop();
            },
            child: const Text('Thoát ra', style: TextStyle(color: Colors.black45)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_totalSeconds - _secondsRemaining) / _totalSeconds;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        decoration: BoxDecoration(
          color: const Color(0xFF1E2621),
          borderRadius: BorderRadius.circular(26),
          boxShadow: const [
            BoxShadow(color: Colors.black45, blurRadius: 20, offset: Offset(0, 10)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Thanh tiêu đề quảng cáo
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 14, 10),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFC107),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('QUẢNG CÁO TÀI TRỢ', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.black)),
                  ),
                  const Spacer(),
                  if (_completed)
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white, size: 26),
                      onPressed: _handleClose,
                    )
                  else
                    InkWell(
                      onTap: _handleClose,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white12,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Nhận thưởng sau: ${_secondsRemaining}s',
                              style: const TextStyle(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.close_rounded, size: 16, color: Colors.white60),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Thanh tiến trình
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 5,
                  backgroundColor: Colors.white12,
                  valueColor: AlwaysStoppedAnimation<Color>(_completed ? kGreen : const Color(0xFFFFC107)),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Video player simulation card
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 18),
              height: 200,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF28664F), Color(0xFF133629)],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white10),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _completed ? Icons.verified_rounded : Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 38,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Hán-Việt Duo Premium',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Học chữ Hán & Nôm không giới hạn cùng Duolingo style',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                  Positioned(
                    bottom: 10,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.volume_up_rounded, color: Colors.white70, size: 14),
                          const SizedBox(width: 4),
                          Text(_completed ? 'Xong' : '0:0$_secondsRemaining', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Thẻ nhận thưởng
            Padding(
              padding: const EdgeInsets.all(18),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _completed ? const Color(0xFF28664F).withOpacity(0.3) : Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: _completed ? kGreen : Colors.white12,
                    width: _completed ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: _completed ? kGreen : Colors.white10,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _completed ? Icons.card_giftcard_rounded : Icons.lock_clock_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _completed ? 'Phần thưởng đã sẵn sàng!' : 'Phần thưởng khi xem xong:',
                            style: TextStyle(fontSize: 11, color: _completed ? const Color(0xFF86E3A8) : Colors.white60, fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '+${widget.rewardDescription}',
                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Nút đóng / nhận thưởng
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: _completed ? kGreen : Colors.white24,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: _completed ? () => Navigator.of(context).pop() : null,
                icon: Icon(_completed ? Icons.check_circle_rounded : Icons.hourglass_top_rounded, size: 20),
                label: Text(
                  _completed ? 'Nhận thưởng và tiếp tục' : 'Xem hết để nhận thưởng (${_secondsRemaining}s)',
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
