import 'package:flutter/material.dart';
import 'dart:ui' as ui;

/// WhatsApp logo - simplified official mark (phone in speech bubble)
class WhatsAppIcon extends StatelessWidget {
  const WhatsAppIcon({super.key, this.size = 24, this.color = Colors.white});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _WhatsAppIconPainter(color),
    );
  }
}

class _WhatsAppIconPainter extends CustomPainter {
  _WhatsAppIconPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 308;
    canvas.scale(scale);

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    // Official WhatsApp SVG path (simplified from Font Awesome / brand assets)
    // This is the recognizable phone-in-circle logo
    final path = ui.Path()
      // Outer circle (chat bubble)
      ..moveTo(154, 0)
      ..cubicTo(238, 0, 308, 70, 308, 154)
      ..cubicTo(308, 238, 238, 308, 154, 308)
      ..cubicTo(123, 308, 94, 299, 69, 284)
      ..lineTo(0, 308)
      ..lineTo(24, 241)
      ..cubicTo(9, 216, 0, 186, 0, 154)
      ..cubicTo(0, 70, 70, 0, 154, 0)
      ..close()
      // Phone handset (inner path)
      ..moveTo(225, 180)
      ..cubicTo(223, 185, 214, 192, 209, 193)
      ..cubicTo(204, 194, 201, 194, 180, 183)
      ..cubicTo(159, 172, 142, 155, 131, 134)
      ..cubicTo(120, 113, 120, 110, 121, 105)
      ..cubicTo(122, 100, 129, 91, 134, 89)
      ..cubicTo(139, 87, 142, 87, 144, 91)
      ..lineTo(152, 107)
      ..cubicTo(154, 111, 154, 114, 152, 116)
      ..cubicTo(150, 118, 147, 121, 145, 123)
      ..cubicTo(143, 125, 143, 128, 145, 131)
      ..cubicTo(149, 139, 155, 147, 163, 153)
      ..cubicTo(171, 159, 179, 165, 187, 169)
      ..cubicTo(190, 171, 193, 171, 195, 169)
      ..cubicTo(197, 167, 200, 164, 202, 162)
      ..cubicTo(204, 160, 207, 160, 211, 162)
      ..lineTo(227, 170)
      ..cubicTo(231, 172, 227, 175, 225, 180)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_WhatsAppIconPainter oldDelegate) => 
      oldDelegate.color != color;
}
