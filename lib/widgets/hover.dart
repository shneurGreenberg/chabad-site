import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme.dart';

const Duration kHoverDuration = Duration(milliseconds: 200);

/// Premium web hover: scale + optional gold lift. Layout size never changes.
class HoverLift extends StatefulWidget {
  const HoverLift({
    super.key,
    required this.child,
    this.scale = 1.04,
    this.lift = true,
    this.underline = false,
    this.enabled = true,
  });

  final Widget child;
  final double scale;
  final bool lift;
  final bool underline;
  final bool enabled;

  @override
  State<HoverLift> createState() => _HoverLiftState();
}

class _HoverLiftState extends State<HoverLift> {
  bool _hovering = false;

  void _set(bool value) {
    if (!widget.enabled || _hovering == value) return;
    setState(() => _hovering = value);
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;
    final reduce = MediaQuery.disableAnimationsOf(context);
    final target = _hovering && !reduce ? 1.0 : 0.0;
    final rtl = Directionality.of(context) == TextDirection.rtl;

    Widget child = widget.child;
    if (widget.underline) {
      child = Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          child,
          PositionedDirectional(
            start: 8,
            end: 8,
            bottom: 0,
            child: IgnorePointer(
              child: Container(
                height: 2,
                decoration: const BoxDecoration(
                  gradient: AppColors.goldGradient,
                  borderRadius: BorderRadius.all(Radius.circular(2)),
                ),
              )
                  .animate(target: target)
                  .scaleX(
                    begin: 0,
                    end: 1,
                    duration: kHoverDuration,
                    curve: Curves.easeOutCubic,
                    alignment:
                        rtl ? Alignment.centerRight : Alignment.centerLeft,
                  ),
            ),
          ),
        ],
      );
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => _set(true),
      onExit: (_) => _set(false),
      onHover: (_) => _set(true),
      child: child
          .animate(target: target)
          .scale(
            begin: const Offset(1, 1),
            end: Offset(widget.scale, widget.scale),
            duration: kHoverDuration,
            curve: Curves.easeOutCubic,
            alignment: Alignment.center,
          )
          .custom(
            duration: kHoverDuration,
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              final painted = child;
              if (!widget.lift || value == 0) return painted;
              return DecoratedBox(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.gold.withValues(alpha: 0.20 * value),
                      blurRadius: 18 * value,
                      offset: Offset(0, 7 * value),
                    ),
                  ],
                ),
                child: child,
              );
            },
          ),
    );
  }
}

/// Scale-only hover (nav chips, icon buttons, dense rows).
class HoverScale extends StatelessWidget {
  const HoverScale({
    super.key,
    required this.child,
    this.scale = 1.05,
    this.underline = false,
  });

  final Widget child;
  final double scale;
  final bool underline;

  @override
  Widget build(BuildContext context) {
    return HoverLift(
      scale: scale,
      lift: false,
      underline: underline,
      child: child,
    );
  }
}

extension HoverWidgetX on Widget {
  Widget hoverLift({double scale = 1.04, bool lift = true}) =>
      HoverLift(scale: scale, lift: lift, child: this);

  Widget hoverScale({double scale = 1.05, bool underline = false}) =>
      HoverScale(scale: scale, underline: underline, child: this);
}
