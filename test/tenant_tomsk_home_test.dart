import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_app/models.dart';
import 'package:flutter_app/tenant/tenant_seed.dart';
import 'package:flutter_test/flutter_test.dart';

// Tomsk home tagline + stats: https://feor.ru/administrative-units/tomsk/
// Synagogue hours/contacts: https://jewtomsk.ru/
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('bundled Tomsk seed has hero subtitle and verified home stats', () async {
    final raw = await rootBundle
        .loadString('assets/tenants/tomsk/tenant.json');
    final seed = jsonDecode(raw) as Map<String, dynamic>;
    final cfg = tenantConfigFromSeed(seed, tenantId: 'tomsk');

    expect(trLoc(cfg.tagline, 'ru'), isNotEmpty);
    expect(trLoc(cfg.tagline, 'ru'), isNot(contains('Томская еврейская община')));

    expect(cfg.homeStats.length, 4);
    expect(cfg.homeStats[0].value, '1902');
    expect(cfg.homeStats[1].value, '2010');
    expect(trLoc(cfg.homeStats[1].label, 'ru'), contains('реставрации'));
  });
}
