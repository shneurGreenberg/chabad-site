import 'package:flutter/material.dart';

/// Official WhatsApp mark (`assets/images/whatsapp.png`).
///
/// The previous CustomPainter drew a rough bubble that did not read as
/// WhatsApp. The asset is the brand glyph (green tile, white handset).
class WhatsAppIcon extends StatelessWidget {
  const WhatsAppIcon({super.key, this.size = 24, this.color = Colors.white});

  final double size;

  /// Kept so existing call sites compile. The asset is full color.
  final Color color;

  /// Same green as the floating WhatsApp button.
  static const Color brandGreen = Color(0xFF25D366);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'WhatsApp',
      image: true,
      child: ClipOval(
        child: Image.asset(
          'assets/images/whatsapp.png',
          width: size,
          height: size,
          fit: BoxFit.cover,
          gaplessPlayback: true,
          filterQuality: FilterQuality.medium,
          excludeFromSemantics: true,
        ),
      ),
    );
  }
}
