import 'package:flutter/material.dart';

const Color _hanBadgeGreen = Color(0xFFE4F1E8);
const Color _hanBadgeGreenText = Color(0xFF28664F);
const Color _nomBadgeOrange = Color(0xFFFFEBDD);
const Color _nomBadgeOrangeText = Color(0xFF9A4B1F);

class TypeBadge extends StatelessWidget {
  final String type;
  final bool compact;

  const TypeBadge({super.key, required this.type, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final isNom = type == 'Nôm';
    final foreground = isNom ? _nomBadgeOrangeText : _hanBadgeGreenText;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 11, vertical: compact ? 4 : 6),
      decoration: BoxDecoration(
        color: isNom ? _nomBadgeOrange : _hanBadgeGreen,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: foreground.withOpacity(0.24)),
      ),
      child: Text(
        isNom ? 'CHỮ NÔM' : 'HÁN TỰ',
        style: TextStyle(
          fontSize: compact ? 9 : 11,
          letterSpacing: 0.8,
          color: foreground,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
