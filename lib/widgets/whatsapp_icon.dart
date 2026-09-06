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
    final scale = size.width / 175.216;
    canvas.scale(scale);

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    // Official WhatsApp logo path - unmistakable brand icon
    // Based on Font Awesome WhatsApp brand icon (fa-brands fa-whatsapp)
    final path = ui.Path()
      // Main circular speech bubble with tail
      ..moveTo(118.3, 168.2)
      ..lineTo(127.5, 175.2)
      ..lineTo(101.6, 175.2)
      ..lineTo(23.2, 175.2)
      ..lineTo(32.7, 143.9)
      ..cubicTo(18.1, 128.1, 9.2, 108.3, 9.2, 86.7)
      ..cubicTo(9.2, 39.2, 47.8, 0.6, 95.3, 0.6)
      ..cubicTo(142.8, 0.6, 181.4, 39.2, 181.4, 86.7)
      ..cubicTo(181.4, 134.2, 142.8, 172.8, 95.3, 172.8)
      ..cubicTo(102.3, 172.8, 109.1, 171.8, 115.6, 170.1)
      ..close()
      // Phone handset (curved receiver shape)
      ..moveTo(68.6, 55.4)
      ..cubicTo(66.8, 51.5, 64.9, 51.4, 63.3, 51.3)
      ..cubicTo(62.0, 51.2, 60.5, 51.2, 59.0, 51.2)
      ..cubicTo(57.5, 51.2, 55.0, 51.8, 52.9, 53.8)
      ..cubicTo(50.7, 55.9, 45.2, 61.1, 45.2, 71.7)
      ..cubicTo(45.2, 82.3, 53.1, 92.5, 54.2, 94.1)
      ..cubicTo(55.3, 95.6, 68.2, 115.3, 87.9, 123.8)
      ..cubicTo(104.2, 130.9, 107.7, 129.5, 111.4, 129.1)
      ..cubicTo(115.1, 128.7, 123.7, 123.9, 125.5, 119.0)
      ..cubicTo(127.3, 114.1, 127.3, 110.0, 126.7, 109.0)
      ..cubicTo(126.1, 108.0, 124.6, 107.4, 122.3, 106.2)
      ..cubicTo(120.0, 105.0, 110.4, 100.3, 108.4, 99.5)
      ..cubicTo(106.4, 98.7, 104.9, 98.3, 103.4, 100.6)
      ..cubicTo(101.9, 102.9, 98.2, 107.4, 96.9, 109.0)
      ..cubicTo(95.6, 110.5, 94.3, 110.7, 92.0, 109.5)
      ..cubicTo(89.7, 108.3, 82.4, 106.0, 73.7, 98.3)
      ..cubicTo(66.9, 92.3, 62.4, 84.9, 61.1, 82.6)
      ..cubicTo(59.8, 80.3, 60.9, 79.1, 62.1, 77.9)
      ..cubicTo(63.2, 76.8, 64.5, 75.1, 65.7, 73.8)
      ..cubicTo(66.9, 72.5, 67.3, 71.6, 68.1, 70.0)
      ..cubicTo(68.9, 68.4, 68.5, 67.1, 67.9, 65.9)
      ..cubicTo(67.3, 64.7, 63.5, 55.0, 68.6, 55.4)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_WhatsAppIconPainter oldDelegate) => 
      oldDelegate.color != color;
}
