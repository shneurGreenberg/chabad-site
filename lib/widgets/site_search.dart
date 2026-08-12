import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/repository.dart';
import '../l10n/strings.dart';
import '../models.dart';
import '../theme.dart';
import 'common.dart';

/// Compact header search: field on desktop, icon that expands on mobile.
class HeaderSearch extends StatefulWidget {
  const HeaderSearch({super.key});

  @override
  State<HeaderSearch> createState() => _HeaderSearchState();
}

class _HeaderSearchState extends State<HeaderSearch> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  final _layerLink = LayerLink();
  final _portal = OverlayPortalController();
  List<SearchHit> _hits = const [];

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onQuery(String value) {
    final loc = context.read<LocaleController>();
    final repo = context.read<AppRepository>();
    final hits = repo.searchSite(value, loc.lang);
    setState(() => _hits = hits);
    if (value.trim().length >= 2) {
      if (!_portal.isShowing) _portal.show();
    } else if (_portal.isShowing) {
      _portal.hide();
    }
  }

  void _open(SearchHit hit) {
    _controller.clear();
    _hits = const [];
    _focus.unfocus();
    if (_portal.isShowing) _portal.hide();
    context.go(hit.route);
  }

  void _openMobile() {
    showDialog<void>(
      context: context,
      builder: (ctx) => _SearchDialog(
        onOpen: (hit) {
          Navigator.pop(ctx);
          context.go(hit.route);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.locWatch;
    if (isMobile(context)) {
      return IconButton(
        tooltip: loc.t('common.search'),
        onPressed: _openMobile,
        icon: const Icon(Icons.search),
      );
    }
    final compact = isTablet(context);
    final width = compact ? 168.0 : 220.0;
    return OverlayPortal(
      controller: _portal,
      overlayChildBuilder: (context) {
        final rtl = Directionality.of(context) == TextDirection.rtl;
        return UnconstrainedBox(
          child: CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            targetAnchor: rtl ? Alignment.bottomRight : Alignment.bottomLeft,
            followerAnchor: rtl ? Alignment.topRight : Alignment.topLeft,
            offset: const Offset(0, 6),
            child: _SearchResults(
              width: compact ? 320 : 380,
              hits: _hits,
              onOpen: _open,
            ),
          ),
        );
      },
      child: CompositedTransformTarget(
        link: _layerLink,
        child: SizedBox(
          width: width,
          height: 40,
          child: TextField(
            controller: _controller,
            focusNode: _focus,
            onChanged: _onQuery,
            onTap: () {
              if (_hits.isNotEmpty && !_portal.isShowing) _portal.show();
            },
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              isDense: true,
              hintText: loc.t('common.search'),
              prefixIcon: const Icon(Icons.search, size: 18),
              suffixIcon: _controller.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: loc.t('common.close'),
                      icon: const Icon(Icons.close, size: 16),
                      onPressed: () {
                        _controller.clear();
                        _onQuery('');
                      },
                    ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                    color: Colors.black.withValues(alpha: 0.1)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                    color: Colors.black.withValues(alpha: 0.1)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SearchDialog extends StatefulWidget {
  const _SearchDialog({required this.onOpen});
  final void Function(SearchHit hit) onOpen;

  @override
  State<_SearchDialog> createState() => _SearchDialogState();
}

class _SearchDialogState extends State<_SearchDialog> {
  final _controller = TextEditingController();
  List<SearchHit> _hits = const [];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onQuery(String value) {
    final loc = context.read<LocaleController>();
    final repo = context.read<AppRepository>();
    setState(() => _hits = repo.searchSite(value, loc.lang));
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.locWatch;
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 520),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            children: [
              TextField(
                controller: _controller,
                autofocus: true,
                onChanged: _onQuery,
                decoration: InputDecoration(
                  hintText: loc.t('common.search'),
                  prefixIcon: const Icon(Icons.search),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: _hits.isEmpty
                    ? Center(
                        child: Text(
                          _controller.text.trim().length < 2
                              ? loc.t('search.hint')
                              : loc.t('search.empty'),
                          style: const TextStyle(color: AppColors.muted),
                        ),
                      )
                    : _SearchResults(
                        width: double.infinity,
                        hits: _hits,
                        onOpen: widget.onOpen,
                        inDialog: true,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchResults extends StatelessWidget {
  const _SearchResults({
    required this.width,
    required this.hits,
    required this.onOpen,
    this.inDialog = false,
  });
  final double width;
  final List<SearchHit> hits;
  final void Function(SearchHit hit) onOpen;
  final bool inDialog;

  @override
  Widget build(BuildContext context) {
    final loc = context.locWatch;
    if (hits.isEmpty && !inDialog) {
      return const SizedBox.shrink();
    }
    final groups = <String, List<SearchHit>>{};
    for (final h in hits) {
      groups.putIfAbsent(h.groupKey, () => []).add(h);
    }
    final body = Material(
      elevation: inDialog ? 0 : 10,
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: inDialog ? 420 : 360,
          minWidth: width == double.infinity ? 0 : width,
          maxWidth: width == double.infinity ? double.infinity : width,
        ),
        child: hits.isEmpty
            ? Padding(
                padding: const EdgeInsets.all(16),
                child: Text(loc.t('search.empty'),
                    style: const TextStyle(color: AppColors.muted)),
              )
            : ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                shrinkWrap: true,
                children: [
                  for (final group in groups.entries) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                      child: Text(
                        loc.t(group.key),
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                          color: AppColors.muted,
                        ),
                      ),
                    ),
                    for (final hit in group.value)
                      ListTile(
                        dense: true,
                        leading: Icon(hit.icon,
                            color: AppColors.primary, size: 20),
                        title: Text(
                          hit.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: hit.subtitle.isEmpty
                            ? null
                            : Text(
                                hit.subtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                        onTap: () => onOpen(hit),
                      ),
                  ],
                ],
              ),
      ),
    );
    if (inDialog) return body;
    return SizedBox(width: width, child: body);
  }
}
