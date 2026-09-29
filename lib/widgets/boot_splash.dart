import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/strings.dart';
import '../theme.dart';
import 'brand.dart';

/// First Flutter frame while local content and zmanim are still loading.
/// Shows the community emblem already on [AppRepository], not a generic mark.
class CommunityBootSplash extends StatelessWidget {
  const CommunityBootSplash({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleController>();
    return DecoratedBox(
      decoration: BoxDecoration(gradient: AppColors.heroGradient),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ChabadEmblem(size: 96),
            const SizedBox(height: 22),
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                color: AppColors.accent,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              locale.t('common.loading'),
              key: const ValueKey('boot-loading-label'),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
