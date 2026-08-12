import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../l10n/strings.dart';
import '../models.dart';
import '../theme.dart';
import '../data/repository.dart';

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
                ?.copyWith(fontSize: 32, height: 1.2, letterSpacing: -0.4)),
        const SizedBox(height: 12),
        Container(
          width: 72,
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
    this.bytes,
  });
  final int color;
  final IconData? icon;
  final String? label;
  final double? height;
  final double borderRadius;
  final Widget? badge;
  final Uint8List? bytes;

  @override
  Widget build(BuildContext context) {
    if (bytes != null && bytes!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: SizedBox(
          height: height,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.memory(bytes!, fit: BoxFit.cover, gaplessPlayback: true),
              if (badge != null)
                PositionedDirectional(top: 10, start: 10, child: badge!),
            ],
          ),
        ),
      );
    }
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
              Color.alphaBlend(Colors.black.withValues(alpha: 0.28), base),
              Color.alphaBlend(AppColors.primaryDark.withValues(alpha: 0.45), base),
            ],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -30,
              top: -24,
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
            ),
            Positioned(
              left: -18,
              bottom: -28,
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.12), width: 8),
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null)
                    Icon(icon, size: 46, color: Colors.white.withValues(alpha: 0.95)),
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
            if (badge != null)
              PositionedDirectional(top: 10, start: 10, child: badge!),
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
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.cardShadow,
        border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 16),
          Text(value,
              style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                  height: 1)),
          const SizedBox(height: 6),
          Text(label,
              style: const TextStyle(color: AppColors.muted, fontSize: 13, height: 1.3)),
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
/// If the admin uploaded a photo for this route, it replaces the blue fill.
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
    final path = GoRouterState.of(context).uri.path;
    final banner = context.watch<AppRepository>().bannerFor(path);
    return Container(
      width: double.infinity,
      decoration: banner.hasImage
          ? const BoxDecoration(color: AppColors.primaryDark)
          : const BoxDecoration(gradient: AppColors.heroGradient),
      child: Stack(
        children: [
          BannerFill(banner: banner),
          if (!banner.hasImage) ...[
            Positioned(
              left: -40,
              top: -50,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: AppColors.accent.withValues(alpha: 0.18), width: 18),
                ),
              ),
            ),
            Positioned(
              right: 40,
              bottom: -60,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
            ),
          ],
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 52),
            child: MaxWidthBox(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.28),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: AppColors.accent.withValues(alpha: 0.5)),
                        ),
                        child: Icon(icon, color: AppColors.accentSoft, size: 28),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          height: 1.15,
                          shadows: [
                            Shadow(color: Colors.black54, blurRadius: 12)
                          ])),
                  const SizedBox(height: 10),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 640),
                    child: Text(subtitle,
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.92),
                            fontSize: 16.5,
                            height: 1.5,
                            shadows: const [
                              Shadow(color: Colors.black45, blurRadius: 8)
                            ])),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Photo (cover-cropped) or empty — sits behind hero content.
class BannerFill extends StatelessWidget {
  const BannerFill({super.key, required this.banner});
  final PageBanner banner;

  @override
  Widget build(BuildContext context) {
    if (!banner.hasImage) return const SizedBox.shrink();
    return Positioned.fill(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.memory(
            banner.bytes!,
            fit: BoxFit.cover,
            alignment: banner.alignment,
            gaplessPlayback: true,
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x660B1C3A),
                  Color(0x990B1C3A),
                ],
              ),
            ),
          ),
        ],
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
