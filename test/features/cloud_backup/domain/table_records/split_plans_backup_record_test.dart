import 'package:flutter_test/flutter_test.dart';
import 'package:lifting_tracker_app/features/cloud_backup/domain/backup_format_exception.dart';
import 'package:lifting_tracker_app/features/cloud_backup/domain/table_records/split_plans_backup_record.dart';

void main() {
  group('SplitPlansBackupRecord', () {
    const path = r'$.data.split_plans[0]';

    test('reads a valid database row', () {
      // Arrange
      final row = <String, Object?>{
        'id': 7,
        'name': 'Push Pull Legs',
        'is_preset': 0,
        'is_active': 1,
      };

      // Act
      final record = SplitPlansBackupRecord.fromDatabaseRow(row, path);

      // Assert
      expect(record.id, 7);
      expect(record.name, 'Push Pull Legs');
      expect(record.isPreset, 0);
      expect(record.isActive, 1);
    });

    test('serializes using the snapshot field names', () {
      // Arrange
      const record = SplitPlansBackupRecord(
        id: 7,
        name: 'Push Pull Legs',
        isPreset: 0,
        isActive: 1,
      );

      // Act
      final json = record.toJson();

      // Assert
      expect(json, {
        'id': 7,
        'name': 'Push Pull Legs',
        'is_preset': 0,
        'is_active': 1,
      });
    });

    test('rejects an id with an invalid type', () {
      // Arrange
      final row = <String, Object?>{
        'id': '7',
        'name': 'Push Pull Legs',
        'is_preset': 0,
        'is_active': 1,
      };

      // Act + Assert
      expect(
        () => SplitPlansBackupRecord.fromDatabaseRow(row, path),
        throwsA(
          isA<BackupFormatException>()
              .having(
                (exception) => exception.code,
                'code',
                BackupFormatErrorCode.invalidType,
              )
              .having(
                (exception) => exception.path,
                'path',
                r'$.data.split_plans[0].id',
              ),
        ),
      );
    });
  });
}