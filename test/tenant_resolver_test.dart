import 'package:flutter_app/tenant/tenant_resolver.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('resolveTenantId', () {
    test('query override wins', () {
      expect(
        resolveTenantId(host: 'kazan.jewishsib.ru', queryTenant: 'demo'),
        'demo',
      );
    });

    test('custom host map', () {
      expect(resolveTenantId(host: 'jewishsib.ru'), 'nsk');
      expect(resolveTenantId(host: 'www.jewishsib.ru'), 'nsk');
    });

    test('subdomain of base domain', () {
      expect(resolveTenantId(host: 'kazan.jewishsib.ru'), 'kazan');
    });

    test('default nsk hosts', () {
      expect(resolveTenantId(host: 'localhost'), 'nsk');
      expect(resolveTenantId(host: '127.0.0.1'), 'nsk');
      expect(resolveTenantId(host: 'jewishsib.amvera.io'), 'nsk');
      expect(resolveTenantId(host: 'unknown.example.org'), 'nsk');
    });

    test('normalize tenant id', () {
      expect(normalizeTenantId('  KAZAN '), 'kazan');
      expect(normalizeTenantId('bad!!'), 'bad');
    });
  });
}
