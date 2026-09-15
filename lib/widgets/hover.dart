import 'package:flutter/material.dart';

import '../theme.dart';

const Duration kHoverDuration = Duration(milliseconds: 200);

/// Premium web hover: scale + optional gold lift. Layout size never changes.
///
/// Uses [AnimatedScale] instead of `flutter_animate` so scrolling a grid of
/// cards cannot detach a RenderObject that an animation still paints.
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
    if (!mounted || !widget.enabled || _hovering == value) return;
    setState(() => _hovering = value);
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;
    final reduce = MediaQuery.disableAnimationsOf(context);
    final duration = reduce ? Duration.zero : kHoverDuration;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final on = _hovering && !reduce;

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
              child: AnimatedScale(
                duration: duration,
                curve: Curves.easeOutCubic,
                scale: on ? 1 : 0,
                alignment:
                    rtl ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  height: 2,
                  decoration: BoxDecoration(
                    gradient: AppColors.goldGradient,
                    borderRadius: const BorderRadius.all(Radius.circular(2)),
                  ),
                ),
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
      child: AnimatedScale(
        scale: on ? widget.scale : 1,
        duration: duration,
        curve: Curves.easeOutCubic,
        alignment: Alignment.center,
        child: AnimatedContainer(
          duration: duration,
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            boxShadow: widget.lift && on
                ? [
                    BoxShadow(
                      color: AppColors.gold.withValues(alpha: 0.20),
                      blurRadius: 18,
                      offset: const Offset(0, 7),
                    ),
                  ]
                : const [],
          ),
          child: child,
        ),
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

/// Exposes whether the pointer is over [builder]'s child.
class HoverAware extends StatefulWidget {
  const HoverAware({super.key, required this.builder});
  final Widget Function(bool hovering) builder;

  @override
  State<HoverAware> createState() => _HoverAwareState();
}

class _HoverAwareState extends State<HoverAware> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        if (mounted && !_hovering) setState(() => _hovering = true);
      },
      onExit: (_) {
        if (mounted && _hovering) setState(() => _hovering = false);
      },
      child: widget.builder(_hovering),
    );
  }
}
