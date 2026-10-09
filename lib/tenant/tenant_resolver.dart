/// Maps custom hostnames to tenant ids (no subdomain on these domains).
const Map<String, String> customHostToTenant = {
  'jewishsib.ru': 'nsk',
  'www.jewishsib.ru': 'nsk',
  'jewishsib.com': 'nsk',
  'www.jewishsib.com': 'nsk',
};

/// Hosts where tenant subdomains may appear: `kazan.example.org` → `kazan`.
const List<String> tenantSubdomainBases = [
  'jewishsib.ru',
  'chabad-site.local',
];

bool _isIpv4(String host) {
  final parts = host.split('.');
  if (parts.length != 4) return false;
  for (final p in parts) {
    final n = int.tryParse(p);
    if (n == null || n < 0 || n > 255) return false;
  }
  return true;
}

bool _isDefaultNskHost(String host) {
  if (host.isEmpty) return true;
  if (host == 'localhost' || host.endsWith('.localhost')) return true;
  if (_isIpv4(host)) return true;
  if (host.endsWith('.amvera.io')) return true;
  if (customHostToTenant.containsKey(host)) return true;
  return false;
}

String normalizeTenantId(String raw) {
  final id = raw.trim().toLowerCase();
  if (id.isEmpty) return 'nsk';
  final cleaned = id.replaceAll(RegExp(r'[^a-z0-9_-]'), '');
  return cleaned.isEmpty ? 'nsk' : cleaned;
}

/// Resolve tenant from host, optional `?tenant=` override, and custom domain map.
String resolveTenantId({
  String? host,
  String? queryTenant,
}) {
  if (queryTenant != null && queryTenant.trim().isNotEmpty) {
    return normalizeTenantId(queryTenant);
  }
  final h = (host ?? '').toLowerCase().trim();
  if (h.isEmpty) return 'nsk';

  if (customHostToTenant.containsKey(h)) {
    return customHostToTenant[h]!;
  }

  for (final base in tenantSubdomainBases) {
    final suffix = '.$base';
    if (h.endsWith(suffix) && h.length > suffix.length) {
      final sub = h.substring(0, h.length - suffix.length);
      if (sub.isNotEmpty && !sub.contains('.')) {
        return normalizeTenantId(sub);
      }
    }
  }

  if (_isDefaultNskHost(h)) return 'nsk';
  return 'nsk';
}

/// Web entry: reads [Uri.base] host and `tenant` query param.
String resolveTenantIdFromUri(Uri uri) {
  return resolveTenantId(
    host: uri.host,
    queryTenant: uri.queryParameters['tenant'],
  );
}
