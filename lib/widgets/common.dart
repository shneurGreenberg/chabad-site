import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../l10n/strings.dart';
import '../models.dart';
import '../section_heading.dart';
import '../theme.dart';
import '../data/repository.dart';
import '../services/image_compress.dart';
import '../services/links.dart';
import '../services/web_prefs.dart';
import '../util/youtube.dart';
import 'playful_icons.dart';

String copyOf(BuildContext context, Loc map, String fallbackKey) {
  final loc = context.locWatch;
  final v = trLoc(map, loc.lang);
  return v.isNotEmpty ? v : loc.t(fallbackKey);
}

extension LocContext on BuildContext {
  LocaleController get loc => read<LocaleController>();
  LocaleController get locWatch => watch<LocaleController>();
  String get lang => watch<LocaleController>().lang;
}

bool isMobile(BuildContext context) =>
    MediaQuery.sizeOf(context).width < 820;
bool isTablet(BuildContext context) =>
    MediaQuery.sizeOf(context).width < 1280;
bool isWideDesktop(BuildContext context) =>
    MediaQuery.sizeOf(context).width >= 1440;

bool navIsActive(String current, String route) {
  if (current == route) return true;
  if (route != '/' && current.startsWith('$route/')) return true;
  return false;
}

/// Home hero (and any multi-slide banner) advances on this interval.
const heroSlideshowInterval = Duration(seconds: 3);

int imageDecodePx(BuildContext context, double logical) {
  final dpr = MediaQuery.devicePixelRatioOf(context);
  return (logical * dpr).round().clamp(48, 1600);
}

/// Decode size for an admin-compressed jpeg. Do not ask the codec for more
/// pixels than [kMaxImageSide], or a small file is stretched soft.
int _memoryDecodePx(BuildContext context, double logical) {
  final px = imageDecodePx(context, logical);
  return px > kMaxImageSide ? kMaxImageSide : px;
}

/// Keeps phone numbers in reading order under RTL (Hebrew) layout.
class PhoneText extends StatelessWidget {
  const PhoneText(
    this.number, {
    super.key,
    this.style,
    this.maxLines,
    this.overflow,
    this.link = true,
  });
  final String number;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool link;

  @override
  Widget build(BuildContext context) {
    final href = telUrl(number);
    Widget child = Text(
      isolateLtr(number),
      textAlign: TextAlign.left,
      textDirection: TextDirection.ltr,
      style: style,
      maxLines: maxLines,
      overflow: overflow,
    );
    if (link && href != null) {
      child = InkWell(
        onTap: () => openUrl(href),
        mouseCursor: SystemMouseCursors.click,
        child: child,
      );
    }
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: child,
      ),
    );
  }
}

/// Clickable email that stays LTR inside RTL copy.
class EmailText extends StatelessWidget {
  const EmailText(this.email, {super.key, this.style});
  final String email;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final href = mailtoUrl(email: email);
    Widget child = Text(
      isolateLtr(email),
      textAlign: TextAlign.left,
      textDirection: TextDirection.ltr,
      style: (style ?? const TextStyle()).copyWith(
        decoration: href == null ? null : TextDecoration.underline,
      ),
    );
    if (href != null) {
      child = InkWell(
        onTap: () => openUrl(href),
        mouseCursor: SystemMouseCursors.click,
        child: child,
      );
    }
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: child,
      ),
    );
  }
}

/// Turns every email and phone number inside [text] into a tappable LTR link.
class LinkedContactText extends StatelessWidget {
  const LinkedContactText(this.text, {super.key, this.style, this.linkColor});
  final String text;
  final TextStyle? style;
  final Color? linkColor;

  @override
  Widget build(BuildContext context) {
    final base = style ?? DefaultTextStyle.of(context).style;
    final matches = findContactMatches(text);
    if (matches.isEmpty) {
      return Text(text, style: base);
    }
    final spans = <InlineSpan>[];
    var cursor = 0;
    for (final m in matches) {
      if (m.start > cursor) {
        spans.add(TextSpan(text: text.substring(cursor, m.start), style: base));
      }
      final color = linkColor ?? AppColors.primary;
      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.baseline,
          baseline: TextBaseline.alphabetic,
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: InkWell(
              onTap: () => openUrl(m.url),
              mouseCursor: SystemMouseCursors.click,
              child: Text(
                isolateLtr(m.text),
                textDirection: TextDirection.ltr,
                style: base.copyWith(
                  color: color,
                  decoration: TextDecoration.underline,
                  decorationColor: color,
                ),
              ),
            ),
          ),
        ),
      );
      cursor = m.end;
    }
    if (cursor < text.length) {
      spans.add(TextSpan(text: text.substring(cursor), style: base));
    }
    return Text.rich(TextSpan(style: base, children: spans));
  }
}

/// Whether the menu should use [Scaffold.endDrawer] so it slides in from the
/// same side as the button that opens it.
///
/// [Scaffold.drawer] is the start edge and [Scaffold.endDrawer] is the end
/// edge, following [Directionality]. The public hamburger is the last child
/// of the header row, so it sits on the end edge in both Hebrew and English.
/// A leading control (the admin rail button) sits on the start edge.
bool menuDrawerFromEnd(BuildContext context, {required bool leadingButton}) {
  Directionality.of(context);
  return !leadingButton;
}

void openMenuDrawer(BuildContext context, {required bool leadingButton}) {
  final scaffold = Scaffold.of(context);
  if (menuDrawerFromEnd(context, leadingButton: leadingButton)) {
    scaffold.openEndDrawer();
  } else {
    scaffold.openDrawer();
  }
}

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
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: SizedBox(
          width: double.infinity,
          child: Padding(padding: padding, child: child),
        ),
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
    final titleStyle = Theme.of(context)
        .textTheme
        .headlineMedium
        ?.copyWith(fontSize: 32, height: 1.2, letterSpacing: -0.4);
    final subtitleStyle = Theme.of(context)
        .textTheme
        .titleMedium
        ?.copyWith(color: AppColors.muted, height: 1.4);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        linkIfSectionHeading(
          context,
          title,
          textAlign: TextAlign.start,
          style: titleStyle,
        ),
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
          linkIfSectionHeading(
            context,
            subtitle!,
            textAlign: TextAlign.start,
            style: subtitleStyle,
          ),
        ],
      ],
    );
  }
}

/// Renders [text] as a link when it names a real page.
Widget linkIfSectionHeading(
  BuildContext context,
  String text, {
  TextStyle? style,
  TextAlign? textAlign,
  int? maxLines,
  TextOverflow? overflow,
}) {
  final child = Text(
    text,
    textAlign: textAlign,
    maxLines: maxLines,
    overflow: overflow,
    style: style,
  );
  final route = sectionHeadingRoute(text);
  if (route == null || _onSectionPage(context, route)) return child;
  return TextButton(
    style: TextButton.styleFrom(
      foregroundColor: style?.color,
      padding: EdgeInsets.zero,
      minimumSize: Size.zero,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      alignment: AlignmentDirectional.centerStart,
      textStyle: style,
      visualDensity: VisualDensity.compact,
    ),
    onPressed: () => context.go(route),
    child: child,
  );
}

bool _onSectionPage(BuildContext context, String route) {
  final path = _sectionPath(context);
  if (path == null) return false;
  if (route == '/') return path == '/';
  return path == route || path.startsWith('$route/');
}

/// Current route when this widget sits under a GoRouter page. Tests and
/// previews that mount a heading alone have no route.
String? _sectionPath(BuildContext context) {
  if (ModalRoute.of(context) == null) return null;
  try {
    return GoRouterState.of(context).uri.path;
  } catch (_) {
    return null;
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
    this.url,
    this.alignment = Alignment.center,
  });
  final int color;
  final IconData? icon;
  final String? label;
  final double? height;
  final double borderRadius;
  final Widget? badge;
  final Uint8List? bytes;
  final String? url;
  final Alignment alignment;

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
              Image.memory(
                bytes!,
                fit: BoxFit.cover,
                alignment: alignment,
                gaplessPlayback: true,
                cacheWidth: _memoryDecodePx(
                    context, MediaQuery.sizeOf(context).width.clamp(200, 900)),
              ),
              if (badge != null)
                PositionedDirectional(top: 10, start: 10, child: badge!),
            ],
          ),
        ),
      );
    }
    if (url != null && url!.isNotEmpty) {
      final cacheW = imageDecodePx(
          context, MediaQuery.sizeOf(context).width.clamp(200, 900));
      final img = url!.startsWith('assets/')
          ? Image.asset(url!, fit: BoxFit.cover, alignment: alignment, cacheWidth: cacheW)
          : Image.network(
              url!,
              fit: BoxFit.cover,
              alignment: alignment,
              cacheWidth: cacheW,
              filterQuality: FilterQuality.high,
            );
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: SizedBox(
          height: height,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              img,
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
                    PlayfulIcon(icon!, size: 46, color: Colors.white.withValues(alpha: 0.95)),
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
            PlayfulIcon(icon!, size: 14, color: c),
            const SizedBox(width: 6),
          ],
          Text(text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: c, fontWeight: FontWeight.w600, fontSize: 12.5)),
        ],
      ),
    );
  }
}

/// Simple statistic card used on home + admin dashboard.
class StatCard extends StatelessWidget {
  StatCard({
    super.key,
    required this.value,
    required this.label,
    required this.icon,
    Color? color,
  }) : color = color ?? AppColors.primary;
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        color: AppColors.card,
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
            child: PlayfulIcon(icon, color: color),
          ),
          const SizedBox(height: 16),
          Text(value,
              style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                  height: 1)),
          const SizedBox(height: 6),
          Text(label,
              style: TextStyle(color: AppColors.muted, fontSize: 13, height: 1.3)),
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
      decoration: banner.hasMedia
          ? BoxDecoration(color: AppColors.primaryDark)
          : BoxDecoration(gradient: AppColors.heroGradient),
      child: Stack(
        children: [
          BannerFill(banner: banner),
          if (!banner.hasMedia) ...[
            PositionedDirectional(
              start: -40,
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
            PositionedDirectional(
              end: 40,
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
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xCC0B1C3A),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: AppColors.accent.withValues(alpha: 0.5)),
                    ),
                    child: PlayfulIcon(icon, color: AppColors.accentSoft, size: 28),
                  ),
                  const SizedBox(height: 18),
                  Text(title,
                      textAlign: TextAlign.start,
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
                        textAlign: TextAlign.start,
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
class BannerFill extends StatefulWidget {
  const BannerFill({super.key, required this.banner, this.positioned = true});
  final PageBanner banner;
  final bool positioned;

  @override
  State<BannerFill> createState() => _BannerFillState();
}

class _BannerFillState extends State<BannerFill> {
  int _index = 0;
  Timer? _timer;

  List<BannerSlide> get _slides => widget.banner.allSlides;

  @override
  void initState() {
    super.initState();
    _arm();
  }

  @override
  void didUpdateWidget(covariant BannerFill oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_index >= _slides.length) _index = 0;
    _arm();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _arm() {
    _timer?.cancel();
    if (_slides.length < 2) return;
    _timer = Timer.periodic(heroSlideshowInterval, (_) {
      if (!mounted) return;
      setState(() => _index = (_index + 1) % _slides.length);
    });
  }

  Widget _image(BannerSlide slide) {
    if (slide.hasVideo && !slide.hasImage) {
      final id = youtubeIdFrom(slide.videoUrl);
      return Stack(
        fit: StackFit.expand,
        children: [
          if (id != null)
            Image.network(
              youtubeThumbnail(id),
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              filterQuality: FilterQuality.high,
              errorBuilder: (_, _, _) => const ColoredBox(color: Color(0xFF0B1C3A)),
            )
          else
            const ColoredBox(color: Color(0xFF0B1C3A)),
        ],
      );
    }
    final bytes = slide.bytes;
    final url = slide.imageUrl;
    final screenW = imageDecodePx(context, MediaQuery.sizeOf(context).width);
    final w = bytes != null && bytes.isNotEmpty && screenW > kMaxImageSide
        ? kMaxImageSide
        : screenW;
    if (bytes != null && bytes.isNotEmpty) {
      return Image.memory(
        bytes,
        fit: BoxFit.cover,
        alignment: slide.alignment,
        gaplessPlayback: true,
        width: double.infinity,
        height: double.infinity,
        cacheWidth: w,
      );
    }
    if (url != null && url.isNotEmpty) {
      if (url.startsWith('assets/')) {
        return Image.asset(
          url,
          fit: BoxFit.cover,
          alignment: slide.alignment,
          width: double.infinity,
          height: double.infinity,
          cacheWidth: w,
        );
      }
      return Image.network(
        url,
        fit: BoxFit.cover,
        alignment: slide.alignment,
        width: double.infinity,
        height: double.infinity,
        cacheWidth: w,
        filterQuality: FilterQuality.high,
      );
    }
    return const SizedBox.expand();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.banner.hasMedia) return const SizedBox.shrink();
    final slides = _slides;
    if (slides.isEmpty) return const SizedBox.shrink();
    final i = _index.clamp(0, slides.length - 1);
    final body = Stack(
      fit: StackFit.expand,
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 900),
          switchInCurve: Curves.easeInOutCubic,
          switchOutCurve: Curves.easeInOutCubic,
          transitionBuilder: (child, anim) {
            return FadeTransition(
              opacity: anim,
              child: ScaleTransition(
                scale: Tween<double>(begin: 1.06, end: 1).animate(anim),
                child: child,
              ),
            );
          },
          child: KeyedSubtree(
            key: ValueKey('banner-slide-$i'),
            child: _image(slides[i]),
          ),
        ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0x8A0B1C3A),
                Color(0xC20B1C3A),
              ],
            ),
          ),
        ),
        if (slides[i].hasVideo)
          const PositionedDirectional(
            bottom: 18,
            start: 18,
            child: Icon(Icons.play_circle_fill, color: Colors.white, size: 40),
          ),
      ],
    );
    if (!widget.positioned) return body;
    return Positioned.fill(child: body);
  }
}

/// Placeholder shown when a list or grid has no matching items.
class EmptyHint extends StatelessWidget {
  const EmptyHint({super.key, this.icon = Icons.inbox_outlined, this.label});
  final IconData icon;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final loc = context.locWatch;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 36),
      child: Center(
        child: Column(
          children: [
            PlayfulIcon(icon, size: 40, color: AppColors.muted.withValues(alpha: 0.7)),
            const SizedBox(height: 10),
            Text(label ?? loc.t('common.empty'),
                style: TextStyle(color: AppColors.muted, fontSize: 15)),
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

/// Wraps a search result so it can be highlighted and scrolled into view.
class HighlightAnchor extends StatefulWidget {
  const HighlightAnchor({
    super.key,
    required this.id,
    required this.highlightId,
    required this.child,
  });
  final String id;
  final String? highlightId;
  final Widget child;

  @override
  State<HighlightAnchor> createState() => _HighlightAnchorState();
}

class _HighlightAnchorState extends State<HighlightAnchor> {
  @override
  void initState() {
    super.initState();
    _maybeScroll();
  }

  @override
  void didUpdateWidget(HighlightAnchor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.highlightId != widget.highlightId) _maybeScroll();
  }

  void _maybeScroll() {
    if (widget.highlightId != widget.id) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Scrollable.ensureVisible(
        context,
        alignment: 0.15,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final on = widget.highlightId != null && widget.highlightId == widget.id;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: on ? AppColors.accent : Colors.transparent,
          width: on ? 2.5 : 0,
        ),
        boxShadow: on
            ? [
                BoxShadow(
                  color: AppColors.accent.withValues(alpha: 0.28),
                  blurRadius: 16,
                ),
              ]
            : null,
      ),
      child: widget.child,
    );
  }
}
