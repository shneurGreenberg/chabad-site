import 'package:flutter/material.dart';

/// WhatsApp brand mark — CustomPainter (CanvasKit-safe, no asset/Image.asset).
/// White glyph on transparent background for the green FAB.
///
/// Uses [Path.combine] difference (not BlendMode.dstOut/saveLayer), because
/// CanvasKit on Flutter web does not apply dstOut reliably — only the bubble
/// would show, looking like Icons.chat.
class WhatsAppIcon extends StatelessWidget {
  const WhatsAppIcon({super.key, this.size = 24, this.color = Colors.white});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _WhatsAppLogoPainter(color: color),
      ),
    );
  }
}

class _WhatsAppLogoPainter extends CustomPainter {
  _WhatsAppLogoPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    // Speech bubble body + tail (single path)
    final bubbleBody = Path()
      ..addOval(Rect.fromCircle(
        center: Offset(w * 0.52, h * 0.45),
        radius: w * 0.36,
      ));
    final tail = Path()
      ..moveTo(w * 0.22, h * 0.68)
      ..quadraticBezierTo(w * 0.08, h * 0.95, w * 0.32, h * 0.78)
      ..quadraticBezierTo(w * 0.26, h * 0.74, w * 0.22, h * 0.68)
      ..close();
    final bubbleWithTail = Path.combine(PathOperation.union, bubbleBody, tail);

    // Handset silhouette (cut out of bubble)
    final phone = Path();
    final cx = w * 0.52;
    final cy = h * 0.45;
    phone.moveTo(cx - w * 0.14, cy + h * 0.08);
    phone.cubicTo(
      cx - w * 0.20, cy - h * 0.02,
      cx - w * 0.06, cy - h * 0.16,
      cx + w * 0.04, cy - h * 0.14,
    );
    phone.cubicTo(
      cx + w * 0.09, cy - h * 0.12,
      cx + w * 0.10, cy - h * 0.06,
      cx + w * 0.06, cy - h * 0.03,
    );
    phone.cubicTo(
      cx + w * 0.01, cy + h * 0.00,
      cx - w * 0.02, cy + h * 0.03,
      cx - w * 0.01, cy + h * 0.07,
    );
    phone.cubicTo(
      cx + w * 0.03, cy + h * 0.12,
      cx + w * 0.13, cy + h * 0.09,
      cx + w * 0.15, cy + h * 0.01,
    );
    phone.cubicTo(
      cx + w * 0.18, cy - h * 0.07,
      cx + w * 0.20, cy - h * 0.14,
      cx + w * 0.12, cy - h * 0.17,
    );
    phone.cubicTo(
      cx + w * 0.02, cy - h * 0.22,
      cx - w * 0.14, cy - h * 0.18,
      cx - w * 0.18, cy - h * 0.02,
    );
    phone.cubicTo(
      cx - w * 0.22, cy + h * 0.08,
      cx - w * 0.18, cy + h * 0.14,
      cx - w * 0.14, cy + h * 0.08,
    );
    phone.close();

    final logo = Path.combine(PathOperation.difference, bubbleWithTail, phone);
    canvas.drawPath(logo, paint);
  }

  @override
  bool shouldRepaint(covariant _WhatsAppLogoPainter oldDelegate) =>
      oldDelegate.color != color;
}