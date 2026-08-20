import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/repository.dart';
import '../../l10n/strings.dart';
import '../../models.dart';
import '../../theme.dart';
import '../../widgets/common.dart';

class AdminRemindersBanner extends StatefulWidget {
  const AdminRemindersBanner({super.key, required this.onJump});
  final void Function(AdminJump jump) onJump;

  @override
  State<AdminRemindersBanner> createState() => _AdminRemindersBannerState();
}

class _AdminRemindersBannerState extends State<AdminRemindersBanner> {
  final _pc = PageController();
  Timer? _timer;
  int _page = 0;
  int _len = 0;

  @override
  void dispose() {
    _timer?.cancel();
    _pc.dispose();
    super.dispose();
  }

  void _syncTimer(int n) {
    if (_len == n) return;
    _len = n;
    _timer?.cancel();
    if (n < 2) return;
    _timer = Timer.periodic(const Duration(seconds: 6), (_) {
      if (!mounted || !_pc.hasClients) return;
      final next = (_page + 1) % n;
      _pc.animateToPage(
        next,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.locWatch;
    final repo = context.watch<AppRepository>();
    final items = repo.adminReminders(loc.lang);
    if (items.isEmpty) return const SizedBox.shrink();
    _syncTimer(items.length);
    if (_page >= items.length) _page = 0;

    return Material(
      color: const Color(0xFFFFF7ED),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.t('admin.reminders.title'),
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 12,
                color: Color(0xFF9A3412),
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 92,
              child: PageView.builder(
                controller: _pc,
                itemCount: items.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (_, i) {
                  final r = items[i];
                  return _slide(context, loc, r);
                },
              ),
            ),
            if (items.length > 1) ...[
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (int i = 0; i < items.length; i++)
                    Container(
                      width: i == _page ? 16 : 7,
                      height: 7,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        color: i == _page
                            ? const Color(0xFFEA580C)
                            : const Color(0x33EA580C),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _slide(BuildContext context, LocaleController loc, AdminReminder r) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => widget.onJump(r.jump),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: r.color.withValues(alpha: 0.14),
                child: Icon(r.icon, color: r.color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      r.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 15),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      r.body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: AppColors.muted, height: 1.3, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                loc.t('admin.reminders.open'),
                style: TextStyle(
                    color: r.color, fontWeight: FontWeight.w800, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
