import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/repository.dart';
import '../theme.dart';

/// Chabad flame emblem (from Chabad.org) on a navy disc, or an admin upload.
class ChabadEmblem extends StatelessWidget {
  const ChabadEmblem({super.key, this.size = 44});
  final double size;

  @override
  Widget build(BuildContext context) {
    Uint8List? bytes;
    String? url;
    try {
      final repo = context.watch<AppRepository>();
      bytes = repo.emblemBytes;
      url = repo.emblemUrl;
    } catch (_) {
      url = 'assets/images/chabad-emblem.png';
    }

    Widget mark;
    if (bytes != null && bytes.isNotEmpty) {
      mark = Image.memory(bytes, fit: BoxFit.contain, gaplessPlayback: true);
    } else if (url != null && url.isNotEmpty) {
      mark = url.startsWith('assets/')
          ? Image.asset(url, fit: BoxFit.contain)
          : Image.network(url, fit: BoxFit.contain);
    } else {
      mark = CustomPaint(painter: const _ChabadEmblemPainter());
    }

    return Semantics(
      label: 'חב״ד',
      image: true,
      child: SizedBox(
        width: size,
        height: size,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primaryDark,
            border: Border.all(color: AppColors.accent, width: math.max(1.4, size * 0.045)),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryDark.withValues(alpha: 0.25),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(size * 0.18),
            child: mark,
          ),
        ),
      ),
    );
  }
}

class _ChabadEmblemPainter extends CustomPainter {
  const _ChabadEmblemPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.shortestSide / 2;
    canvas.drawCircle(c, r, Paint()..color = AppColors.primaryDark);
    canvas.drawCircle(
      c,
      r - 1.2,
      Paint()
        ..color = AppColors.accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Country flag for a UI language: he → Israel, ru → Russia, en → UK.
class LangFlag extends StatelessWidget {
  const LangFlag({super.key, required this.code, this.width = 22, this.height = 15});
  final String code;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: code,
      image: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(3),
          border: Border.all(color: const Color(0x33000000), width: 0.6),
          boxShadow: const [
            BoxShadow(color: Color(0x1A000000), blurRadius: 2, offset: Offset(0, 1)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(2.4),
          child: SizedBox(
            width: width,
            height: height,
            child: CustomPaint(painter: _FlagPainter(code)),
          ),
        ),
      ),
    );
  }
}

class _FlagPainter extends CustomPainter {
  const _FlagPainter(this.code);
  final String code;

  @override
  void paint(Canvas canvas, Size size) {
    switch (code) {
      case 'he':
        _israel(canvas, size);
      case 'ru':
        _russia(canvas, size);
      default:
        _uk(canvas, size);
    }
  }

  void _israel(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.white);
    final stripe = size.height * 0.18;
    final gap = size.height * 0.14;
    final blue = Paint()..color = const Color(0xFF0038B8);
    canvas.drawRect(Rect.fromLTWH(0, gap, size.width, stripe), blue);
    canvas.drawRect(
      Rect.fromLTWH(0, size.height - gap - stripe, size.width, stripe),
      blue,
    );
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.height * 0.22;
    final star = Paint()
      ..color = const Color(0xFF0038B8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.0, size.height * 0.07)
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(_triangle(cx, cy - r * 0.12, r, up: true), star);
    canvas.drawPath(_triangle(cx, cy + r * 0.12, r, up: false), star);
  }

  Path _triangle(double cx, double cy, double r, {required bool up}) {
    final path = Path();
    for (var i = 0; i < 3; i++) {
      final a = -math.pi / 2 + (up ? 0 : math.pi) + i * 2 * math.pi / 3;
      final x = cx + r * math.cos(a);
      final y = cy + r * math.sin(a);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    return path;
  }

  void _russia(Canvas canvas, Size size) {
    final h = size.height / 3;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, h), Paint()..color = Colors.white);
    canvas.drawRect(
      Rect.fromLTWH(0, h, size.width, h),
      Paint()..color = const Color(0xFF1C47B7),
    );
    canvas.drawRect(
      Rect.fromLTWH(0, h * 2, size.width, size.height - h * 2),
      Paint()..color = const Color(0xFFE4181C),
    );
  }

  void _uk(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF012169));
    final w = size.width;
    final h = size.height;
    final white = Paint()
      ..color = Colors.white
      ..strokeWidth = h * 0.28
      ..strokeCap = StrokeCap.square;
    final red = Paint()
      ..color = const Color(0xFFC8102E)
      ..strokeWidth = h * 0.12
      ..strokeCap = StrokeCap.square;
    canvas.drawLine(Offset.zero, Offset(w, h), white);
    canvas.drawLine(Offset(w, 0), Offset(0, h), white);
    canvas.drawLine(Offset.zero, Offset(w, h), red);
    canvas.drawLine(Offset(w, 0), Offset(0, h), red);
    canvas.drawRect(
      Rect.fromCenter(center: Offset(w / 2, h / 2), width: w, height: h * 0.34),
      Paint()..color = Colors.white,
    );
    canvas.drawRect(
      Rect.fromCenter(center: Offset(w / 2, h / 2), width: w * 0.22, height: h),
      Paint()..color = Colors.white,
    );
    canvas.drawRect(
      Rect.fromCenter(center: Offset(w / 2, h / 2), width: w, height: h * 0.20),
      Paint()..color = const Color(0xFFC8102E),
    );
    canvas.drawRect(
      Rect.fromCenter(center: Offset(w / 2, h / 2), width: w * 0.12, height: h),
      Paint()..color = const Color(0xFFC8102E),
    );
  }

  @override
  bool shouldRepaint(covariant _FlagPainter oldDelegate) => oldDelegate.code != code;
}
