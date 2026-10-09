import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models.dart';
import '../../services/web_prefs.dart';
import '../../services/tenant_cloud.dart';
import '../../state/auth.dart';
import '../../tenant/nsk_tenant_config.dart';
import '../../tenant/tenant_registry.dart';
import '../../tenant/tenant_seed.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import 'admin.dart';

/// Super-admin listing at `/admin/communities`.
class CommunitiesAdminPage extends StatelessWidget {
  const CommunitiesAdminPage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    if (!auth.isLoggedIn) return const AdminLogin();
    return const _CommunitiesListBody();
  }
}

class _CommunitiesListBody extends StatefulWidget {
  const _CommunitiesListBody();

  @override
  State<_CommunitiesListBody> createState() => _CommunitiesListBodyState();
}

class _CommunitiesListBodyState extends State<_CommunitiesListBody> {
  bool _loading = true;
  List<_Row> _rows = const [];

  @override
  void initState() {
    super.initState();
    unawaited(_reload());
  }

  Future<void> _reload() async {
    setState(() => _loading = true);
    final byId = <String, _Row>{};
    byId['nsk'] = _Row(
      id: 'nsk',
      name: trLoc(nskTenantConfig.communityName, 'ru'),
      city: trLoc(nskTenantConfig.cityName, 'ru'),
      langs: nskTenantConfig.enabledLanguages,
      status: 'bundled',
    );
    for (final id in bundledTenantIds) {
      final json = await loadBundledTenantJson(id);
      byId[id] = _Row(
        id: id,
        name: trLoc(_loc(json?['name']), 'ru'),
        city: trLoc(_loc(json?['city']), 'ru'),
        langs: _langs(json?['languages']),
        status: 'bundled',
      );
    }
    final local = await TenantRegistry.instance.loadAll();
    for (final e in local.entries) {
      byId[e.key] = _Row(
        id: e.key,
        name: trLoc(_loc(e.value.json['name']), 'ru'),
        city: trLoc(_loc(e.value.json['city']), 'ru'),
        langs: _langs(e.value.json['languages']),
        status: 'local',
      );
    }
    final cloud = await TenantCloudService.instance.listFirestoreTenants();
    for (final m in cloud) {
      final id = '${m['id']}';
      if (id.isEmpty) continue;
      byId[id] = _Row(
        id: id,
        name: trLoc(_loc(m['name']), 'ru'),
        city: trLoc(_loc(m['city']), 'ru'),
        langs: _langs(m['languages']),
        status: byId.containsKey(id) && byId[id]!.status == 'bundled'
            ? 'bundled'
            : 'cloud',
      );
    }
    if (!mounted) return;
    setState(() {
      _rows = byId.values.toList()
        ..sort((a, b) => a.id.compareTo(b.id));
      _loading = false;
    });
  }

  Loc _loc(dynamic v) {
    if (v is Map) {
      return Map<String, String>.from(v.cast<String, dynamic>());
    }
    return const {};
  }

  List<String> _langs(dynamic v) {
    if (v is! List) return const [];
    return [for (final e in v) '$e'];
  }

  String _previewUrl(String id) {
    final base = Uri.base;
    final q = Map<String, String>.from(base.queryParameters);
    q['tenant'] = id;
    return Uri(
      scheme: base.scheme,
      host: base.host,
      port: base.hasPort ? base.port : null,
      path: base.path,
      queryParameters: q,
      fragment: base.fragment.isEmpty ? '/' : base.fragment,
    ).toString();
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.locWatch;
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(loc.t('admin.communities.title')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/admin'),
        ),
        actions: [
          FilledButton.icon(
            onPressed: () => context.go('/admin/communities/new'),
            icon: const Icon(Icons.add, size: 18),
            label: Text(loc.t('admin.communities.new')),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: _rows.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final r = _rows[i];
                return Card(
                  child: ListTile(
                    title: Text(r.name.isEmpty ? r.id : r.name,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text(
                      '${r.city} · ${r.id} · ${r.langs.join(', ')} · ${loc.t('admin.communities.status.${r.status}')}',
                    ),
                    trailing: TextButton(
                      onPressed: () => openUrl(_previewUrl(r.id)),
                      child: Text(loc.t('admin.communities.preview')),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _Row {
  const _Row({
    required this.id,
    required this.name,
    required this.city,
    required this.langs,
    required this.status,
  });
  final String id;
  final String name;
  final String city;
  final List<String> langs;
  final String status;
}
