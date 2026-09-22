import 'package:flutter_test/flutter_test.dart';

import '../test_fixtures/backup_snapshot_fixture.dart';

void main() {
  test('serializes a complete version 1 snapshot', () {
    final snapshot = buildBackupSnapshotFixture();

    final json = snapshot.toJson();

    expect(json, buildBackupSnapshotJsonFixture());
  });
}
