import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/providers/persisted/active_session_id.dart';
import 'package:lifting_tracker_app/providers/persisted/active_session_lifecycle.dart';
import 'package:lifting_tracker_app/providers/presentation/next_in_cycle.dart';
import 'package:lifting_tracker_app/screens/workout_editor.dart';

class SessionLaunchButton extends ConsumerWidget {
  const SessionLaunchButton({
    required this.buttonBuilder,
    required this.contentBuilder,
    super.key,
  });

  final Widget Function(
    BuildContext context,
    VoidCallback onPressed,
    Widget child,
  )
  buttonBuilder;

  final Widget Function(
    BuildContext context,
    bool isSessionAlreadyActive,
    String workoutName,
  )
  contentBuilder;

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
        activeSessionLifecycleProvider.notifier,
      );
      final isSessionAlreadyActive = await ref.read(
        activeSessionLifecycleProvider.future,
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
          builder: (context) => WorkoutEditorScreen.active(activeSessionId),
        ),
      );
    } catch (_) {
      if (!context.mounted) return;
      _showStartSessionError(context);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nextInCycleAsync = ref.watch(nextInCycleProvider);
    final sessionStatusAsync = ref.watch(activeSessionLifecycleProvider);

    if (nextInCycleAsync.isLoading || sessionStatusAsync.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (nextInCycleAsync.hasError || sessionStatusAsync.hasError) {
      return const Center(child: Text('An error has occured!'));
    }

    final nextInCycle = nextInCycleAsync.requireValue;
    final isSessionAlreadyActive = sessionStatusAsync.requireValue;

    final child = contentBuilder(
      context,
      isSessionAlreadyActive,
      nextInCycle.workoutName,
    );

    return buttonBuilder(context, () => _handlePressed(context, ref), child);
  }
}
