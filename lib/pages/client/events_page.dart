import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../data/repository.dart';
import '../../l10n/strings.dart';
import '../../models.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../../widgets/hover.dart';
import '../../widgets/playful_icons.dart';
import '../../widgets/site_scaffold.dart';

class EventsPage extends StatelessWidget {
  const EventsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = context.locWatch;
    final repo = context.watch<AppRepository>();
    final upcoming = [...repo.events]
      ..sort((a, b) => a.startsAt.compareTo(b.startsAt));
    return SiteScaffold(
      currentRoute: '/events',
      children: [
        PageHero(
          title: loc.t('nav.events'),
          subtitle: loc.t('events.subtitle'),
          icon: Icons.event_outlined,
        ),
        Section(
          child: upcoming.isEmpty
              ? const EmptyHint(icon: Icons.event_busy_outlined)
              : Column(
                  children: [
                    for (final e in upcoming) ...[
                      _EventCard(e),
                      const SizedBox(height: 16),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard(this.event);
  final CommunityEvent event;

  @override
  Widget build(BuildContext context) {
    final loc = context.locWatch;
    final when = DateFormat.yMMMEd(loc.lang).add_Hm().format(event.startsAt);
    return HoverLift(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                trLoc(event.title, loc.lang),
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
              ),
              const SizedBox(height: 8),
              Text(when, style: TextStyle(color: AppColors.muted)),
              const SizedBox(height: 4),
              Text(trLoc(event.place, loc.lang)),
              const SizedBox(height: 10),
              Text(trLoc(event.description, loc.lang),
                  style: const TextStyle(height: 1.45)),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (event.capacity > 0)
                    Pill(
                      event.isFull
                          ? loc.t('events.full')
                          : '${loc.t('events.left')}: ${event.seatsLeft}',
                      color: event.isFull
                          ? const Color(0xFFFECACA)
                          : AppColors.accent,
                    ),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: event.isFull
                        ? null
                        : () => _rsvp(context, event),
                    icon: const PlayfulIcon(Icons.how_to_reg_outlined, size: 18),
                    label: Text(loc.t('events.rsvp')),
                  ).hoverLift(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _rsvp(BuildContext context, CommunityEvent event) async {
    final loc = context.read<LocaleController>();
    final repo = context.read<AppRepository>();
    final name = TextEditingController();
    final phone = TextEditingController();
    final email = TextEditingController();
    final guests = TextEditingController(text: '1');
    final err = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.t('events.rsvp')),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                decoration: InputDecoration(labelText: loc.t('common.name')),
              ),
              TextField(
                controller: phone,
                decoration: InputDecoration(labelText: loc.t('common.phone')),
              ),
              TextField(
                controller: email,
                decoration: InputDecoration(labelText: loc.t('common.email')),
              ),
              TextField(
                controller: guests,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: loc.t('events.guests')),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(loc.t('common.close')),
          ),
          FilledButton(
            onPressed: () {
              final result = repo.rsvpEvent(
                event: event,
                name: name.text,
                phone: phone.text,
                email: email.text,
                guests: int.tryParse(guests.text) ?? 1,
              );
              Navigator.pop(ctx, result ?? 'ok');
            },
            child: Text(loc.t('events.rsvp')),
          ),
        ],
      ),
    );
    name.dispose();
    phone.dispose();
    email.dispose();
    guests.dispose();
    if (!context.mounted || err == null) return;
    final msg = switch (err) {
      'ok' => loc.t('events.rsvp.thanks'),
      'full' => loc.t('events.full'),
      _ => loc.t('common.required'),
    };
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}
