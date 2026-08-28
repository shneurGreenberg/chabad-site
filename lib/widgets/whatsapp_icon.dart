import 'package:flutter/material.dart';

/// Custom WhatsApp logo painter — phone-in-speech-bubble glyph
class WhatsAppIcon extends StatelessWidget {
  const WhatsAppIcon({super.key, this.size = 24, this.color = Colors.white});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _WhatsAppPainter(color),
    );
  }
}

class _WhatsAppPainter extends CustomPainter {
  _WhatsAppPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final cy = h / 2;

    // Speech bubble outline circle
    final outerRadius = w * 0.46;
    final path = Path();
    
    // Main circle (speech bubble)
    path.addOval(Rect.fromCircle(center: Offset(cx, cy * 0.92), radius: outerRadius));
    
    // Tail of speech bubble (bottom-left)
    path.moveTo(cx - outerRadius * 0.5, cy + outerRadius * 0.65);
    path.lineTo(cx - outerRadius * 0.85, cy + outerRadius * 1.15);
    path.lineTo(cx - outerRadius * 0.25, cy + outerRadius * 0.85);
    path.close();

    canvas.drawPath(path, paint);

    // Phone handset inside the bubble
    final phonePaint = Paint()
      ..color = Color(0xFF25D366) // WhatsApp green background shows through
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.08
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    // Draw the classic phone receiver curve
    final phonePath = Path();
    final phoneStartX = cx - w * 0.18;
    final phoneStartY = cy - h * 0.08;
    final phoneEndX = cx + w * 0.18;
    final phoneEndY = cy + h * 0.08;
    
    phonePath.moveTo(phoneStartX, phoneStartY);
    phonePath.cubicTo(
      phoneStartX + w * 0.08, phoneStartY - h * 0.12,
      phoneEndX - w * 0.08, phoneEndY + h * 0.12,
      phoneEndX, phoneEndY,
    );

    // Fill background where phone will be drawn (create cutout effect)
    final phoneErasePaint = Paint()
      ..color = Color(0xFF25D366)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.15
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;
    
    canvas.drawPath(phonePath, phoneErasePaint);
    canvas.drawPath(phonePath, phonePaint..color = color);
  }

  @override
  bool shouldRepaint(_WhatsAppPainter oldDelegate) => oldDelegate.color != color;
}
