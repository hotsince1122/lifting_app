import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/features/cloud_backup/data/firebase_cloud_backup_repository.dart';
import 'package:lifting_tracker_app/features/cloud_backup/data/shared_preferences_last_backup_date_repository.dart';
import 'package:lifting_tracker_app/features/cloud_backup/data/sqlite_local_backup_repository.dart';
import 'package:lifting_tracker_app/features/cloud_backup/domain/cloud_backup_repository.dart';
import 'package:lifting_tracker_app/features/cloud_backup/domain/local_backup_repository.dart';
import 'package:lifting_tracker_app/features/cloud_backup/domain/last_backup_date_repository.dart';

final firebaseStorageProvider = Provider<FirebaseStorage>((ref) {
  final storage = FirebaseStorage.instance;
  storage.setMaxOperationRetryTime(const Duration(seconds: 15));
  storage.setMaxUploadRetryTime(const Duration(seconds: 30));
  return storage;
});

final cloudBackupRepositoryProvider = Provider<CloudBackupRepository>((ref) {
  final storage = ref.watch(firebaseStorageProvider);

  return FirebaseCloudBackupRepository(storage);
});

final localBackupRepositoryProvider = Provider<LocalBackupRepository>((ref) {
  return const SqliteLocalBackupRepository();
});

final lastBackupDateRepositoryProvider = Provider<LastBackupDateRepository>((
  ref,
) {
  return SharedPreferencesLastBackupDateRepository();
});

final lastBackupDateProvider = FutureProvider.family<DateTime?, String>((
  ref,
  userId,
) {
  return ref.watch(lastBackupDateRepositoryProvider).read(userId);
});
