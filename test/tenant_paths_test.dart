import 'package:flutter_app/tenant/tenant_paths.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('legacy nsk storage prefix', () {
    final paths = TenantPaths(tenantId: 'nsk', nskMigrated: false);
    expect(paths.legacyNsk, isTrue);
    expect(paths.storagePrefix('img'), 'site/img');
  });

  test('migrated nsk storage prefix', () {
    final paths = TenantPaths(tenantId: 'nsk', nskMigrated: true);
    expect(paths.legacyNsk, isFalse);
    expect(paths.storagePrefix(), 'tenants/nsk');
  });

  test('other tenants always namespaced storage', () {
    final paths = TenantPaths(tenantId: 'kazan', nskMigrated: false);
    expect(paths.legacyNsk, isFalse);
    expect(paths.storagePrefix('media/x'), 'tenants/kazan/media/x');
  });
}
