import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/strings.dart';
import '../models.dart';
import '../theme.dart';

/// Convenience access to the current [LocaleController].
extension LocContext on BuildContext {
  LocaleController get loc => read<LocaleController>();
  LocaleController get locWatch => watch<LocaleController>();
  String get lang => watch<LocaleController>().lang;
}

bool isMobile(BuildContext context) =>
    MediaQuery.sizeOf(context).width < 820;
bool isTablet(BuildContext context) =>
    MediaQuery.sizeOf(context).width < 1280;

/// Centered, width-constrained content column.
class MaxWidthBox extends StatelessWidget {
  const MaxWidthBox({
    super.key,
    required this.child,
    this.maxWidth = 1200,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
  });
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

/// A section title with an optional subtitle and gold underline.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.center = false,
  });
  final String title;
  final String? subtitle;
  final bool center;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          center ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Text(title,
            textAlign: center ? TextAlign.center : null,
            style: Theme.of(context)
                .textTheme
                .headlineMedium
                ?.copyWith(fontSize: 30)),
        const SizedBox(height: 10),
        Container(
          width: 64,
          height: 4,
          decoration: BoxDecoration(
            gradient: AppColors.goldGradient,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 12),
          Text(
            subtitle!,
            textAlign: center ? TextAlign.center : null,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(color: Colors.black54, height: 1.4),
          ),
        ],
      ],
    );
  }
}

/// A gradient "image" placeholder that always renders (no network needed).
class GradientImage extends StatelessWidget {
  const GradientImage({
    super.key,
    required this.color,
    this.icon,
    this.label,
    this.height,
    this.borderRadius = 0,
    this.badge,
  });
  final int color;
  final IconData? icon;
  final String? label;
  final double? height;
  final double borderRadius;
  final Widget? badge;

  @override
  Widget build(BuildContext context) {
    final base = Color(color);
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Container(
        height: height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              base,
              Color.alphaBlend(Colors.black.withValues(alpha: 0.35), base),
            ],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -20,
              bottom: -20,
              child: Icon(Icons.star,
                  size: 120, color: Colors.white.withValues(alpha: 0.06)),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null)
                    Icon(icon, size: 46, color: Colors.white.withValues(alpha: 0.92)),
                  if (label != null) ...[
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(label!,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                ],
              ),
            ),
            if (badge != null) Positioned(top: 10, left: 10, child: badge!),
          ],
        ),
      ),
    );
  }
}

/// A small rounded tag/pill.
class Pill extends StatelessWidget {
  const Pill(this.text, {super.key, this.color, this.icon});
  final String text;
  final Color? color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: c),
            const SizedBox(width: 6),
          ],
          Text(text,
              style: TextStyle(
                  color: c, fontWeight: FontWeight.w600, fontSize: 12.5)),
        ],
      ),
    );
  }
}

/// Simple statistic card used on home + admin dashboard.
class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.value,
    required this.label,
    required this.icon,
    this.color = AppColors.primary,
  });
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 14),
          Text(value,
              style: const TextStyle(
                  fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.ink)),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(color: Colors.black54, fontSize: 13)),
        ],
      ),
    );
  }
}

/// Responsive grid that lays children out in [columns] columns.
class ResponsiveGrid extends StatelessWidget {
  const ResponsiveGrid({
    super.key,
    required this.children,
    required this.columns,
    this.spacing = 18,
    this.runSpacing = 18,
  });
  final List<Widget> children;
  final int columns;
  final double spacing;
  final double runSpacing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final totalSpacing = spacing * (columns - 1);
      final w = (c.maxWidth - totalSpacing) / columns;
      return Wrap(
        spacing: spacing,
        runSpacing: runSpacing,
        children: [
          for (final child in children)
            SizedBox(width: w.clamp(0, c.maxWidth), child: child),
        ],
      );
    });
  }
}

/// Resolve number of columns based on width.
int gridColumns(BuildContext context, {int max = 3}) {
  final w = MediaQuery.sizeOf(context).width;
  if (w < 620) return 1;
  if (w < 1000) return max >= 2 ? 2 : max;
  return max;
}

String localeName(BuildContext context, Loc map) => trLoc(map, context.lang);

/// Gradient banner shown at the top of interior pages.
class PageHero extends StatelessWidget {
  const PageHero({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
  });
  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(gradient: AppColors.heroGradient),
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: MaxWidthBox(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: AppColors.accent, size: 28),
            ),
            const SizedBox(height: 16),
            Text(title,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            Text(subtitle,
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 16,
                    height: 1.4)),
          ],
        ),
      ),
    );
  }
}

/// Vertically-padded, width-constrained content section.
class Section extends StatelessWidget {
  const Section({super.key, required this.child, this.padTop = 40, this.padBottom = 8});
  final Widget child;
  final double padTop;
  final double padBottom;
  @override
  Widget build(BuildContext context) {
    return MaxWidthBox(
      padding: EdgeInsets.fromLTRB(20, padTop, 20, padBottom),
      child: child,
    );
  }
}
