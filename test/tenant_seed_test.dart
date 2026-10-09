import 'dart:typed_data';

import 'package:flutter_app/tenant/tenant_blank_config.dart';
import 'package:flutter_app/tenant/tenant_config.dart';
import 'package:flutter_app/tenant/tenant_resolver.dart';
import 'package:flutter_app/tenant/tenant_seed.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('tenant seed', () {
    test('tenantConfigFromSeed maps colors and about', () {
      final cfg = tenantConfigFromSeed({
        'id': 'demo',
        'name': {'en': 'Demo', 'he': 'דמו', 'ru': 'Демо'},
        'city': {'en': 'City', 'he': 'עיר', 'ru': 'Город'},
        'address': {'en': '1 Main St'},
        'phone': '+1',
        'email': 'a@b.c',
        'about': {'en': 'About us'},
        'languages': ['en', 'ru'],
        'colors': {'primary': '#112233', 'accent': '#AABBCC'},
        'logo': 'logo.png',
        'sourceCredit': 'credit',
      }, tenantId: 'demo');
      expect(cfg.tenantId, 'demo');
      expect(cfg.primaryColorHex, '#112233');
      expect(cfg.accentColorHex, '#AABBCC');
      expect(cfg.sourceCredit, 'credit');
      expect(cfg.emblemAssetPath, 'assets/tenants/demo/logo.png');
    });

    test('blank tenant is not NSK', () {
      final b = blankTenantConfig('x');
      expect(b.tenantId, 'x');
      expect(b.communityName['en'], '');
    });

    test('unknown query tenant does not normalize to nsk', () {
      expect(resolveTenantId(queryTenant: 'tomsk'), 'tomsk');
      expect(resolveTenantId(queryTenant: 'missing-xyz'), 'missing-xyz');
    });
  });

  group('TenantSeedPackage export', () {
    test('round-trip base64 images', () {
      final pkg = TenantSeedPackage(
        id: 't',
        json: {'id': 't', 'name': {'en': 'T'}},
        imageFiles: {'a.png': Uint8List.fromList([1, 2, 3])},
      );
      final out = pkg.toExportJson();
      final back = TenantSeedPackage.fromExportJson(out);
      expect(back.id, 't');
      expect(back.imageFiles['a.png'], pkg.imageFiles['a.png']);
    });
  });
}
