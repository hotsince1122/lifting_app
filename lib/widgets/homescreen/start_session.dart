import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/providers/persisted/active_session_id.dart';
import 'package:lifting_tracker_app/providers/persisted/current_session_status.dart';
import 'package:lifting_tracker_app/providers/presentation/next_in_cycle.dart';
import 'package:lifting_tracker_app/screens/active_session.dart';
import 'package:lifting_tracker_app/theme/app_colors.dart';
import 'package:lifting_tracker_app/widgets/solid_button.dart';

class StartSession extends ConsumerWidget {
  const StartSession({super.key});

  void _showStartSessionError(BuildContext context) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Could not open the session. Please try again.'),
        ),
      );
  }

  Future<void> _handlePressed(BuildContext context, WidgetRef ref) async {
    try {
      final sessionStatusNotifier = ref.read(
        currentSessionStatusProvider.notifier,
      );
      final isSessionAlreadyActive = await ref.read(
        currentSessionStatusProvider.future,
      );

      final int? activeSessionId = isSessionAlreadyActive
          ? await ref.read(activeSessionProvider.future)
          : await sessionStatusNotifier.startSession();

      if (!context.mounted) return;

      if (activeSessionId == null) {
        _showStartSessionError(context);
        return;
      }

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ActiveSessionScreen(activeSessionId),
        ),
      );
    } catch (_) {
      if (!context.mounted) return;
      _showStartSessionError(context);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: SolidButton(
        isActive: false,
        onPressed: () {
          _handlePressed(context, ref);
        },
        buttonHeight: 62,
        child: _SessionName(),
      ),
    );
  }
}

class _SessionName extends ConsumerWidget {
  const _SessionName();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nextInCycleAsync = ref.watch(nextInCycleProvider);
    final sessionStatusAsync = ref.watch(currentSessionStatusProvider);

    if (nextInCycleAsync.isLoading || sessionStatusAsync.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (nextInCycleAsync.hasError || sessionStatusAsync.hasError) {
      return const Center(child: Text('An error has occured!'));
    }

    final nextInCycle = nextInCycleAsync.requireValue;
    final isSessionAlreadyActive = sessionStatusAsync.requireValue;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.play_arrow, size: 32, color: AppColors.background),
        const SizedBox(width: 6),
        Text(
          isSessionAlreadyActive ? 'Resume ' : 'Start ',
          style: Theme.of(
            context,
          ).textTheme.titleLarge!.copyWith(color: AppColors.background),
        ),
        Text(
          nextInCycle.workoutName,
          style: Theme.of(context).textTheme.titleLarge!.copyWith(
            color: AppColors.background,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}
