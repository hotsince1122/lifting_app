import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lifting_tracker_app/features/cloud_backup/data/backup_gzip_decoder.dart';
import 'package:lifting_tracker_app/features/cloud_backup/domain/cloud_backup_exception.dart';

void main() {
  group('decompressBackupBytes', () {
    test('restores the original bytes when output is under the limit', () {
      final originalBytes = List<int>.generate(100000, (index) => index % 251);
      final compressedBytes = gzip.encode(originalBytes);

      final result = decompressBackupBytes(
        compressedBytes,
        maxOutputBytes: originalBytes.length,
      );

      expect(result, originalBytes);
    });

    test('accepts output exactly at the limit', () {
      final originalBytes = List<int>.filled(1024, 42);
      final compressedBytes = gzip.encode(originalBytes);

      final result = decompressBackupBytes(
        compressedBytes,
        maxOutputBytes: originalBytes.length,
      );

      expect(result, originalBytes);
    });

    test('rejects decompressed output larger than the limit', () {
      final originalBytes = List<int>.filled(1025, 42);
      final compressedBytes = gzip.encode(originalBytes);

      expect(
        () => decompressBackupBytes(compressedBytes, maxOutputBytes: 1024),
        throwsA(
          isA<CloudBackupException>().having(
            (error) => error.code,
            'code',
            CloudBackupErrorCode.sizeLimitExceeded,
          ),
        ),
      );
    });

    test('rejects bytes that are not a valid gzip archive', () {
      expect(
        () => decompressBackupBytes(const <int>[
          1,
          2,
          3,
          4,
        ], maxOutputBytes: 1024),
        throwsFormatException,
      );
    });
  });
}
