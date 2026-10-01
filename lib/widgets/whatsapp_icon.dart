import 'dart:math' as math;

import 'package:flutter/material.dart';

/// WhatsApp mark: the speech-bubble and handset, with no background plate.
///
/// The button behind this widget supplies the color (green on the floating
/// button, the same translucent tile as the other footer icons). The glyph
/// itself is only [color], so a second circle or a white tile cannot sit
/// behind the handset.
class WhatsAppIcon extends StatelessWidget {
  const WhatsAppIcon({super.key, this.size = 24, this.color = Colors.white});

  final double size;
  final Color color;

  /// Same green as the floating WhatsApp button.
  static const Color brandGreen = Color(0xFF25D366);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'WhatsApp',
      image: true,
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _WhatsAppMarkPainter(color),
        ),
      ),
    );
  }
}

/// Official mark path (24×24), filled with the caller's color.
const _kMark =
    'M17.472 14.382c-.297-.149-1.758-.867-2.03-.967-.273-.099-.471-.148-.67.15-.197.297-.767.966-.94 1.164-.173.199-.347.223-.644.075-.297-.15-1.255-.463-2.39-1.475-.883-.788-1.48-1.761-1.653-2.059-.173-.297-.018-.458.13-.606.134-.133.298-.347.446-.52.149-.174.198-.298.298-.497.099-.198.05-.371-.025-.52-.075-.149-.669-1.612-.916-2.207-.242-.579-.487-.5-.669-.51-.173-.008-.371-.01-.57-.01-.198 0-.52.074-.792.372-.272.297-1.04 1.016-1.04 2.479 0 1.462 1.065 2.875 1.213 3.074.149.198 2.096 3.2 5.077 4.487.709.306 1.262.489 1.694.625.712.227 1.36.195 1.871.118.571-.085 1.758-.719 2.006-1.413.248-.694.248-1.289.173-1.413-.074-.124-.272-.198-.57-.347m-5.421 7.403h-.004a9.87 9.87 0 01-5.031-1.378l-.361-.214-3.741.982.998-3.648-.235-.374a9.86 9.86 0 01-1.51-5.26c.001-5.45 4.436-9.884 9.888-9.884 2.64 0 5.122 1.03 6.988 2.898a9.825 9.825 0 012.893 6.994c-.003 5.45-4.437 9.884-9.885 9.884m8.413-18.297A11.815 11.815 0 0012.05 0C5.495 0 .16 5.335.157 11.892c0 2.096.547 4.142 1.588 5.945L.057 24l6.305-1.654a11.882 11.882 0 005.683 1.448h.005c6.554 0 11.89-5.335 11.893-11.893a11.821 11.821 0 00-3.48-8.413Z';

final Path _markPath = _svgPath(_kMark);

class _WhatsAppMarkPainter extends CustomPainter {
  const _WhatsAppMarkPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 24, size.height / 24);
    canvas.drawPath(_markPath, Paint()..color = color);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _WhatsAppMarkPainter oldDelegate) =>
      oldDelegate.color != color;
}

Path _svgPath(String source) {
  final scan = _SvgScan(source);
  final path = Path();
  var cx = 0.0;
  var cy = 0.0;
  var sx = 0.0;
  var sy = 0.0;
  String? cmd;
  while (scan.hasMore) {
    final next = scan.peekCommand();
    if (next != null) {
      cmd = scan.command();
    } else if (cmd == null) {
      break;
    } else if (cmd == 'M') {
      cmd = 'L';
    } else if (cmd == 'm') {
      cmd = 'l';
    }
    switch (cmd) {
      case 'M':
        cx = scan.number();
        cy = scan.number();
        path.moveTo(cx, cy);
        sx = cx;
        sy = cy;
      case 'm':
        cx += scan.number();
        cy += scan.number();
        path.moveTo(cx, cy);
        sx = cx;
        sy = cy;
      case 'L':
        cx = scan.number();
        cy = scan.number();
        path.lineTo(cx, cy);
      case 'l':
        cx += scan.number();
        cy += scan.number();
        path.lineTo(cx, cy);
      case 'H':
        cx = scan.number();
        path.lineTo(cx, cy);
      case 'h':
        cx += scan.number();
        path.lineTo(cx, cy);
      case 'V':
        cy = scan.number();
        path.lineTo(cx, cy);
      case 'v':
        cy += scan.number();
        path.lineTo(cx, cy);
      case 'C':
        final x1 = scan.number();
        final y1 = scan.number();
        final x2 = scan.number();
        final y2 = scan.number();
        cx = scan.number();
        cy = scan.number();
        path.cubicTo(x1, y1, x2, y2, cx, cy);
      case 'c':
        final x1 = cx + scan.number();
        final y1 = cy + scan.number();
        final x2 = cx + scan.number();
        final y2 = cy + scan.number();
        cx += scan.number();
        cy += scan.number();
        path.cubicTo(x1, y1, x2, y2, cx, cy);
      case 'A':
      case 'a':
        final rx = scan.number();
        final ry = scan.number();
        final rot = scan.number();
        final large = scan.flag();
        final sweep = scan.flag();
        final x = cmd == 'A' ? scan.number() : cx + scan.number();
        final y = cmd == 'A' ? scan.number() : cy + scan.number();
        _arcTo(path, Offset(cx, cy), rx, ry, rot, large, sweep, Offset(x, y));
        cx = x;
        cy = y;
      case 'Z':
      case 'z':
        path.close();
        cx = sx;
        cy = sy;
      default:
        break;
    }
  }
  return path;
}

void _arcTo(
  Path path,
  Offset start,
  double rx,
  double ry,
  double angleDeg,
  bool large,
  bool sweep,
  Offset end,
) {
  if (start == end) return;
  if (rx == 0 || ry == 0) {
    path.lineTo(end.dx, end.dy);
    return;
  }
  rx = rx.abs();
  ry = ry.abs();
  final rad = angleDeg * math.pi / 180;
  final cosA = math.cos(rad);
  final sinA = math.sin(rad);
  final dx2 = (start.dx - end.dx) / 2;
  final dy2 = (start.dy - end.dy) / 2;
  final x1 = cosA * dx2 + sinA * dy2;
  final y1 = -sinA * dx2 + cosA * dy2;
  var rxSq = rx * rx;
  var rySq = ry * ry;
  final cr = x1 * x1 / rxSq + y1 * y1 / rySq;
  if (cr > 1) {
    final s = math.sqrt(cr);
    rx *= s;
    ry *= s;
    rxSq = rx * rx;
    rySq = ry * ry;
  }
  final sign = large == sweep ? -1.0 : 1.0;
  final sq = math.max(
    0.0,
    (rxSq * rySq - rxSq * y1 * y1 - rySq * x1 * x1) /
        (rxSq * y1 * y1 + rySq * x1 * x1),
  );
  final coef = sign * math.sqrt(sq);
  final cx1 = coef * (rx * y1 / ry);
  final cy1 = coef * -(ry * x1 / rx);
  final cx = cosA * cx1 - sinA * cy1 + (start.dx + end.dx) / 2;
  final cy = sinA * cx1 + cosA * cy1 + (start.dy + end.dy) / 2;

  double angle(double ux, double uy, double vx, double vy) {
    final dot = ux * vx + uy * vy;
    final len = math.sqrt((ux * ux + uy * uy) * (vx * vx + vy * vy));
    var ang = math.acos((dot / (len == 0 ? 1 : len)).clamp(-1.0, 1.0));
    if (ux * vy - uy * vx < 0) ang = -ang;
    return ang;
  }

  final startAngle = angle(1, 0, (x1 - cx1) / rx, (y1 - cy1) / ry);
  var delta = angle(
    (x1 - cx1) / rx,
    (y1 - cy1) / ry,
    (-x1 - cx1) / rx,
    (-y1 - cy1) / ry,
  );
  if (!sweep && delta > 0) delta -= 2 * math.pi;
  if (sweep && delta < 0) delta += 2 * math.pi;

  final segments = math.max(1, (delta.abs() / (math.pi / 2)).ceil());
  final step = delta / segments;
  var a0 = startAngle;
  for (var i = 0; i < segments; i++) {
    final a1 = a0 + step;
    final t = a1 - a0;
    final alpha = math.sin(t) *
        (math.sqrt(4 + 3 * math.pow(math.tan(t / 2), 2)) - 1) /
        3;
    Offset onEllipse(double theta) {
      final c = math.cos(theta);
      final s = math.sin(theta);
      return Offset(
        cosA * rx * c - sinA * ry * s + cx,
        sinA * rx * c + cosA * ry * s + cy,
      );
    }

    Offset deriv(double theta) {
      final c = math.cos(theta);
      final s = math.sin(theta);
      return Offset(
        -cosA * rx * s - sinA * ry * c,
        -sinA * rx * s + cosA * ry * c,
      );
    }

    final p0 = onEllipse(a0);
    final p1 = onEllipse(a1);
    final d0 = deriv(a0);
    final d1 = deriv(a1);
    path.cubicTo(
      p0.dx + alpha * d0.dx,
      p0.dy + alpha * d0.dy,
      p1.dx - alpha * d1.dx,
      p1.dy - alpha * d1.dy,
      p1.dx,
      p1.dy,
    );
    a0 = a1;
  }
}

class _SvgScan {
  _SvgScan(this.source);
  final String source;
  int i = 0;

  bool get hasMore {
    _skip();
    return i < source.length;
  }

  void _skip() {
    while (i < source.length) {
      final c = source[i];
      if (c == ' ' || c == ',' || c == '\n' || c == '\t' || c == '\r') {
        i++;
      } else {
        break;
      }
    }
  }

  String? peekCommand() {
    _skip();
    if (i >= source.length) return null;
    final c = source[i];
    if (_isCommand(c)) return c;
    return null;
  }

  String command() {
    _skip();
    final c = source[i];
    i++;
    return c;
  }

  bool flag() {
    _skip();
    final c = source[i];
    i++;
    return c == '1';
  }

  double number() {
    _skip();
    final start = i;
    if (i < source.length && (source[i] == '+' || source[i] == '-')) i++;
    var dot = false;
    while (i < source.length) {
      final c = source.codeUnitAt(i);
      if (c >= 48 && c <= 57) {
        i++;
      } else if (source[i] == '.' && !dot) {
        dot = true;
        i++;
      } else {
        break;
      }
    }
    if (i < source.length && (source[i] == 'e' || source[i] == 'E')) {
      i++;
      if (i < source.length && (source[i] == '+' || source[i] == '-')) i++;
      while (i < source.length) {
        final c = source.codeUnitAt(i);
        if (c >= 48 && c <= 57) {
          i++;
        } else {
          break;
        }
      }
    }
    return double.parse(source.substring(start, i));
  }

  bool _isCommand(String c) {
    return 'MmZzLlHhVvCcSsQqTtAa'.contains(c);
  }
}
