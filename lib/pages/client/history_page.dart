import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/repository.dart';
import '../../models.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../../widgets/hover.dart';
import '../../widgets/site_scaffold.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});
  @override
  Widget build(BuildContext context) {
    final loc = context.locWatch;
    final repo = context.watch<AppRepository>();
    return SiteScaffold(
      currentRoute: '/history',
      children: [
        PageHero(
          title: loc.t('nav.history'),
          subtitle: loc.t('history.subtitle'),
          icon: Icons.account_balance_outlined,
        ),
        Section(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (int i = 0; i < repo.history.length; i++)
                _TimelineTile(
                  event: repo.history[i],
                  isLast: i == repo.history.length - 1,
                ),
            ],
          ),
        ),
        Section(
          padTop: 30,
          child: SectionHeader(
              title: loc.t('history.tour'), subtitle: loc.t('history.subtitle')),
        ),
        Section(
          padTop: 16,
          child: ResponsiveGrid(
            columns: gridColumns(context, max: 2),
            children: [
              for (int i = 0; i < repo.tour.length; i++)
                _TourCard(stop: repo.tour[i], onStart: () => _startTour(context, repo, i)),
            ],
          ),
        ),
      ],
    );
  }

  void _startTour(BuildContext context, AppRepository repo, int start) {
    showDialog(
      context: context,
      builder: (_) => _TourDialog(stops: repo.tour, initial: start),
    );
  }
}

class _TimelineTile extends StatelessWidget {
  const _TimelineTile({required this.event, required this.isLast});
  final HistoryEvent event;
  final bool isLast;
  @override
  Widget build(BuildContext context) {
    final loc = context.locWatch;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: AppColors.goldGradient,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(Icons.flag, size: 20, color: AppColors.primaryDark),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: AppColors.accent.withValues(alpha: 0.4),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.ink.withValues(alpha: 0.08)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Pill(event.year.toUpperCase(), color: AppColors.primary),
                    const SizedBox(height: 8),
                    Text(trLoc(event.title, loc.lang),
                        style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 17,
                            color: AppColors.ink)),
                    const SizedBox(height: 4),
                    Text(trLoc(event.description, loc.lang),
                        style: TextStyle(color: AppColors.muted, height: 1.5)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TourCard extends StatelessWidget {
  const _TourCard({required this.stop, required this.onStart});
  final TourStop stop;
  final VoidCallback onStart;
  @override
  Widget build(BuildContext context) {
    final loc = context.locWatch;
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(children: [
            GradientImage(color: stop.color, icon: stop.icon, height: 150),
            Positioned.fill(
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.35),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.threesixty, color: Colors.white, size: 30),
                ),
              ),
            ),
          ]),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(trLoc(stop.name, loc.lang),
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: AppColors.ink)),
                const SizedBox(height: 4),
                Text(trLoc(stop.description, loc.lang),
                    style: TextStyle(color: AppColors.muted, height: 1.4)),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: onStart,
                  icon: const Icon(Icons.play_circle_outline, size: 18),
                  label: Text(loc.t('history.tour.cta')),
                ).hoverLift(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TourDialog extends StatefulWidget {
  const _TourDialog({required this.stops, required this.initial});
  final List<TourStop> stops;
  final int initial;
  @override
  State<_TourDialog> createState() => _TourDialogState();
}

class _TourDialogState extends State<_TourDialog> {
  late int _i = widget.initial;
  @override
  Widget build(BuildContext context) {
    final loc = context.locWatch;
    final stop = widget.stops[_i];
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(children: [
              GradientImage(color: stop.color, icon: stop.icon, height: 240),
              Positioned.fill(
                child: Center(
                  child: Icon(Icons.threesixty,
                      color: Colors.white.withValues(alpha: 0.85), size: 54),
                ),
              ),
              PositionedDirectional(
                top: 8,
                end: 8,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ).hoverScale(),
              ),
              PositionedDirectional(
                start: 12,
                bottom: 12,
                child: Pill('${_i + 1} / ${widget.stops.length}',
                    color: Colors.black.withValues(alpha: 0.5)),
              ),
            ]),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(trLoc(stop.name, loc.lang),
                      style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 20,
                          color: AppColors.ink)),
                  const SizedBox(height: 6),
                  Text(trLoc(stop.description, loc.lang),
                      style: TextStyle(color: AppColors.muted, height: 1.5)),
                  const SizedBox(height: 16),
                  Row(children: [
                    OutlinedButton.icon(
                      onPressed: _i > 0 ? () => setState(() => _i--) : null,
                      icon: const Icon(Icons.chevron_left),
                      label: Text(loc.t('common.previous')),
                    ).hoverLift(),
                    const Spacer(),
                    FilledButton.icon(
                      onPressed: _i < widget.stops.length - 1
                          ? () => setState(() => _i++)
                          : () => Navigator.pop(context),
                      icon: Icon(
                        _i < widget.stops.length - 1
                            ? Icons.chevron_right
                            : Icons.check,
                      ),
                      label: Text(_i < widget.stops.length - 1
                          ? loc.t('common.next')
                          : loc.t('common.close')),
                    ).hoverLift(),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
