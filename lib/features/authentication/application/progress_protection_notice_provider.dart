import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/features/authentication/application/auth_providers.dart';

enum ProgressProtectionNoticeContent { guest, verificationRequired }

final progressProtectionNoticeProvider =
    FutureProvider<ProgressProtectionNoticeContent?>((ref) async {
      final authState = await ref.watch(authStateProvider.future);

      if (authState == null) return ProgressProtectionNoticeContent.guest;

      if (!authState.isEmailVerified) {
        return ProgressProtectionNoticeContent.verificationRequired;
      }

      return null;
    });
