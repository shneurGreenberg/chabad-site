import 'tenant_registry.dart';
import 'tenant_seed.dart';

final _slugRe = RegExp(r'^[a-z0-9]+(?:-[a-z0-9]+)*$');

/// Validates community slug / id for onboarding.
Future<String?> validateTenantSlug(String raw) async {
  final id = raw.trim().toLowerCase();
  if (id.isEmpty) return 'empty';
  if (id == 'nsk') return 'reserved';
  if (!_slugRe.hasMatch(id)) return 'format';
  if (isBundledTenantId(id)) return 'taken';
  final local = await TenantRegistry.instance.get(id);
  if (local != null) return 'taken';
  return null;
}
