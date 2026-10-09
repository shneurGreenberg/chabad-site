import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../tenant/tenant_runtime.dart';
import '../../theme.dart';
import '../../widgets/common.dart';

class CommunityNotFoundPage extends StatelessWidget {
  const CommunityNotFoundPage({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = context.locWatch;
    final id = TenantRuntime.instance.tenantId;
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.search_off, size: 56, color: AppColors.muted),
                const SizedBox(height: 16),
                Text(
                  loc.t('tenant.notFound.title'),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                ),
                const SizedBox(height: 10),
                Text(
                  '${loc.t('tenant.notFound.body')} ($id)',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.muted, height: 1.5),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => context.go('/'),
                  child: Text(loc.t('tenant.notFound.home')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
