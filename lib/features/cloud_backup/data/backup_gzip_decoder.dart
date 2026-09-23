import 'dart:io';
import 'dart:typed_data';

import 'package:lifting_tracker_app/features/cloud_backup/domain/cloud_backup_exception.dart';

final class _LimitedBytesSink implements Sink<List<int>> {
  _LimitedBytesSink(this.maxBytes);

  final int maxBytes;
  final BytesBuilder _buffer = BytesBuilder();

  @override
  void add(List<int> chunk) {
    if (_buffer.length + chunk.length > maxBytes) {
      throw const CloudBackupException(CloudBackupErrorCode.sizeLimitExceeded);
    }

    _buffer.add(chunk);
  }

  @override
  void close() {}

  Uint8List takeBytes() => _buffer.takeBytes();
}

Uint8List decompressBackupBytes(
  List<int> compressedBytes, {
  required int maxOutputBytes,
}) {
  final output = _LimitedBytesSink(maxOutputBytes);
  final input = gzip.decoder.startChunkedConversion(output);

  input.add(compressedBytes);
  input.close();

  return output.takeBytes();
}
