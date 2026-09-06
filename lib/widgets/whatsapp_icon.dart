import 'package:flutter/material.dart';

/// WhatsApp brand mark from PNG asset (CanvasKit-safe; no CustomPaint paths).
class WhatsAppIcon extends StatelessWidget {
  const WhatsAppIcon({super.key, this.size = 24, this.color = Colors.white});

  final double size;
  /// Kept for API compatibility; PNG glyph is white — tint via [ColorFiltered] if needed.
  final Color color;

  static const assetPath = 'assets/images/whatsapp.png';

  @override
  Widget build(BuildContext context) {
    final img = Image.asset(
      assetPath,
      width: size,
      height: size,
      filterQuality: FilterQuality.high,
      errorBuilder: (_, __, ___) => Icon(
        Icons.chat,
        size: size,
        color: color,
      ),
    );
    // Default asset is white; if a non-white color is requested, tint it.
    if (color == Colors.white) return img;
    return ColorFiltered(
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      child: img,
    );
  }
}
