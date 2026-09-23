import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_app/services/content_freshness.dart';

void main() {
  group('localAdminSnapshotWins', () {
    test('guests never beat published cloud', () {
      expect(
        localAdminSnapshotWins(
          signedIn: false,
          diskHadSnapshot: true,
          localUpdatedAt: DateTime.utc(2026, 9, 23),
          cloudUpdatedAt: DateTime.utc(2026, 9, 1),
          localSeq: 9999,
          cloudSeq: 1,
        ),
        isFalse,
      );
    });

    test('empty disk does not win', () {
      expect(
        localAdminSnapshotWins(
          signedIn: true,
          diskHadSnapshot: false,
          localUpdatedAt: DateTime.utc(2026, 9, 23),
          cloudUpdatedAt: DateTime.utc(2026, 9, 1),
          localSeq: 9999,
          cloudSeq: 1,
        ),
        isFalse,
      );
    });

    test('signed-in admin keeps a newer local stamp', () {
      expect(
        localAdminSnapshotWins(
          signedIn: true,
          diskHadSnapshot: true,
          localUpdatedAt: DateTime.utc(2026, 9, 23, 12),
          cloudUpdatedAt: DateTime.utc(2026, 9, 23, 10),
          localSeq: 10,
          cloudSeq: 10,
        ),
        isTrue,
      );
    });

    test('signed-in admin takes newer cloud', () {
      expect(
        localAdminSnapshotWins(
          signedIn: true,
          diskHadSnapshot: true,
          localUpdatedAt: DateTime.utc(2026, 9, 23, 10),
          cloudUpdatedAt: DateTime.utc(2026, 9, 23, 12),
          localSeq: 10,
          cloudSeq: 11,
        ),
        isFalse,
      );
    });
  });
}
