import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../models.dart';
import 'hover.dart';

/// Maps a daily zman to a matching icon.
IconData zmanIconOf(ZmanKind kind) {
  switch (kind) {
    case ZmanKind.dawn:
      return Icons.wb_twilight_outlined;
    case ZmanKind.sunrise:
      return Icons.wb_sunny_outlined;
    case ZmanKind.shema:
      return Icons.menu_book_outlined;
    case ZmanKind.shacharit:
      return Icons.auto_stories_outlined;
    case ZmanKind.midday:
      return Icons.wb_sunny;
    case ZmanKind.mincha:
      return Icons.south_outlined;
    case ZmanKind.sunset:
      return Icons.wb_twilight;
    case ZmanKind.stars:
      return Icons.auto_awesome;
    case ZmanKind.candle:
      return Icons.local_fire_department;
    case ZmanKind.havdala:
      return Icons.nightlight_round;
  }
}

PlayfulKind playfulKindForIcon(IconData icon) {
  if (icon == Icons.schedule) return PlayfulKind.clock;
  if (icon == Icons.favorite ||
      icon == Icons.favorite_outline ||
      icon == Icons.favorite_border) {
    return PlayfulKind.heart;
  }
  if (icon == Icons.wb_sunny || icon == Icons.wb_sunny_outlined) {
    return PlayfulKind.sun;
  }
  if (icon == Icons.wb_twilight || icon == Icons.wb_twilight_outlined) {
    return PlayfulKind.sunset;
  }
  if (icon == Icons.auto_awesome || icon == Icons.star || icon == Icons.star_outline) {
    return PlayfulKind.stars;
  }
  if (icon == Icons.nights_stay || icon == Icons.nights_stay_outlined) {
    return PlayfulKind.dawn;
  }
  if (icon == Icons.menu_book_outlined || icon == Icons.auto_stories_outlined) {
    return PlayfulKind.book;
  }
  if (icon == Icons.local_fire_department) return PlayfulKind.flame;
  if (icon == Icons.south_outlined) return PlayfulKind.mincha;
  return PlayfulKind.soft;
}

PlayfulKind playfulKindForZman(ZmanKind kind) {
  switch (kind) {
    case ZmanKind.dawn:
      return PlayfulKind.dawn;
    case ZmanKind.sunrise:
    case ZmanKind.midday:
      return PlayfulKind.sun;
    case ZmanKind.shema:
    case ZmanKind.shacharit:
      return PlayfulKind.book;
    case ZmanKind.mincha:
      return PlayfulKind.mincha;
    case ZmanKind.sunset:
      return PlayfulKind.sunset;
    case ZmanKind.stars:
    case ZmanKind.havdala:
      return PlayfulKind.stars;
    case ZmanKind.candle:
      return PlayfulKind.flame;
  }
}

enum PlayfulKind {
  clock,
  heart,
  sun,
  sunset,
  stars,
  dawn,
  book,
  flame,
  mincha,
  soft,
}

/// Small icon that plays a gentle hover animation.
class PlayfulIcon extends StatelessWidget {
  const PlayfulIcon(
    this.icon, {
    super.key,
    this.kind,
    this.size = 24,
    this.color,
    this.hovering,
  });

  final IconData icon;
  final PlayfulKind? kind;
  final double size;
  final Color? color;
  final bool? hovering;

  @override
  Widget build(BuildContext context) {
    final resolved = kind ?? playfulKindForIcon(icon);
    if (hovering != null) {
      return _PlayfulIconCore(
        icon: icon,
        kind: resolved,
        size: size,
        color: color,
        hovering: hovering!,
      );
    }
    return HoverAware(
      builder: (hovering) => _PlayfulIconCore(
        icon: icon,
        kind: resolved,
        size: size,
        color: color,
        hovering: hovering,
      ),
    );
  }
}

class _PlayfulIconCore extends StatelessWidget {
  const _PlayfulIconCore({
    required this.icon,
    required this.kind,
    required this.size,
    required this.hovering,
    this.color,
  });

  final IconData icon;
  final PlayfulKind kind;
  final double size;
  final Color? color;
  final bool hovering;

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    final on = hovering && !reduce;
    final target = on ? 1.0 : 0.0;
    final painted = switch (kind) {
      PlayfulKind.clock => _ClockIcon(size: size, color: color, t: target),
      PlayfulKind.heart => _HeartIcon(size: size, color: color, hovering: on),
      _ => Icon(icon, size: size, color: color),
    };

    Widget child = painted;
    switch (kind) {
      case PlayfulKind.clock:
        return child;
      case PlayfulKind.heart:
        return child;
      case PlayfulKind.sun:
        return child
            .animate(target: target)
            .rotate(
              begin: 0,
              end: 0.12,
              duration: 700.ms,
              curve: Curves.easeInOut,
            )
            .scale(
              begin: const Offset(1, 1),
              end: const Offset(1.12, 1.12),
              duration: 700.ms,
            );
      case PlayfulKind.sunset:
        return child
            .animate(target: target)
            .slideY(begin: 0, end: 0.22, duration: 650.ms, curve: Curves.easeInOut)
            .fade(begin: 1, end: 0.82, duration: 650.ms);
      case PlayfulKind.stars:
        return child
            .animate(target: target)
            .scale(
              begin: const Offset(1, 1),
              end: const Offset(1.18, 1.18),
              duration: 500.ms,
              curve: Curves.easeOutBack,
            )
            .fade(begin: 1, end: 0.7, duration: 280.ms)
            .then()
            .fade(begin: 0.7, end: 1, duration: 280.ms);
      case PlayfulKind.dawn:
        return child
            .animate(target: target)
            .slideY(begin: 0.18, end: 0, duration: 700.ms, curve: Curves.easeOut)
            .fade(begin: 0.55, end: 1, duration: 700.ms);
      case PlayfulKind.book:
        return child
            .animate(target: target)
            .rotate(begin: 0, end: -0.08, duration: 420.ms)
            .then()
            .rotate(begin: -0.08, end: 0.06, duration: 380.ms)
            .then()
            .rotate(begin: 0.06, end: 0, duration: 280.ms);
      case PlayfulKind.flame:
        return child
            .animate(target: target)
            .moveY(begin: 0, end: -2.5, duration: 280.ms)
            .then()
            .moveY(begin: -2.5, end: 1.5, duration: 240.ms)
            .then()
            .moveY(begin: 1.5, end: 0, duration: 240.ms)
            .shimmer(duration: 700.ms, color: const Color(0x66F59E0B));
      case PlayfulKind.mincha:
        return child
            .animate(target: target)
            .rotate(begin: 0, end: 0.35, duration: 650.ms, curve: Curves.easeInOut);
      case PlayfulKind.soft:
        return child.animate(target: target).scale(
              begin: const Offset(1, 1),
              end: const Offset(1.12, 1.12),
              duration: kHoverDuration,
            );
    }
  }
}

class _HeartIcon extends StatelessWidget {
  const _HeartIcon({required this.size, required this.hovering, this.color});
  final double size;
  final Color? color;
  final bool hovering;

  @override
  Widget build(BuildContext context) {
    final target = hovering ? 1.0 : 0.0;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(Icons.favorite_border, size: size, color: color),
          Icon(Icons.favorite, size: size, color: const Color(0xFFE11D48))
              .animate(target: target)
              .fade(duration: 280.ms)
              .scale(
                begin: const Offset(0.65, 0.65),
                end: const Offset(1, 1),
                duration: 320.ms,
                curve: Curves.easeOutBack,
              ),
        ],
      ),
    )
        .animate(target: target)
        .shake(
          hz: 3.2,
          duration: 520.ms,
          rotation: 0.04,
          offset: const Offset(1.6, 0),
        );
  }
}

class _ClockIcon extends StatelessWidget {
  const _ClockIcon({required this.size, required this.t, this.color});
  final double size;
  final Color? color;
  final double t;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: t),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeInOutCubic,
      builder: (context, value, _) => SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _ClockPainter(color: color ?? Colors.black87, t: value),
        ),
      ),
    );
  }
}

class _ClockPainter extends CustomPainter {
  const _ClockPainter({required this.color, required this.t});
  final Color color;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.shortestSide / 2 - 1.2;
    final ring = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.4, size.shortestSide * 0.08);
    canvas.drawCircle(c, r, ring);
    canvas.drawCircle(c, 1.3, Paint()..color = color);

    final hour = -math.pi / 2 + t * math.pi * 2;
    final minute = -math.pi / 2 + t * math.pi * 4;
    final hand = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round
      ..strokeWidth = math.max(1.3, size.shortestSide * 0.08);
    canvas.drawLine(c, Offset(c.dx + math.cos(hour) * r * 0.45, c.dy + math.sin(hour) * r * 0.45), hand);
    canvas.drawLine(
      c,
      Offset(c.dx + math.cos(minute) * r * 0.72, c.dy + math.sin(minute) * r * 0.72),
      hand..strokeWidth = math.max(1.1, size.shortestSide * 0.06),
    );
  }

  @override
  bool shouldRepaint(covariant _ClockPainter oldDelegate) =>
      oldDelegate.t != t || oldDelegate.color != color;
}
