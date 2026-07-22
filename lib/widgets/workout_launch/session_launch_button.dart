import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/providers/persisted/active_session_id.dart';
import 'package:lifting_tracker_app/providers/persisted/active_session_lifecycle.dart';
import 'package:lifting_tracker_app/providers/persisted/workout_name.dart';
import 'package:lifting_tracker_app/providers/presentation/workout_focus.dart';
import 'package:lifting_tracker_app/screens/workout_editor.dart';
import 'package:lifting_tracker_app/widgets/workout_launch/workout_launch_flow.dart';

class SessionLaunchButton extends ConsumerWidget {
  const SessionLaunchButton({
    required this.launchFlow,
    required this.buttonBuilder,
    required this.contentBuilder,
    super.key,
  });

  final WorkoutLaunchFlow launchFlow;

  final Widget Function(
    BuildContext context,
    VoidCallback onPressed,
    bool isSessionAlreadyActive,
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
      final isSessionAlreadyActive = await ref.read(
        activeSessionLifecycleProvider.future,
      );

      final int? activeSessionId = isSessionAlreadyActive
          ? await ref.read(activeSessionIdProvider.future)
          : await launchFlow.startNewSession(ref);

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

  Widget _loading() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _error() {
    return const Center(child: Text('An error has occured!'));
  }

  Widget _buildLaunchButton(
    BuildContext context,
    WidgetRef ref, {
    required bool isSessionAlreadyActive,
    required String workoutName,
  }) {
    final child = contentBuilder(context, isSessionAlreadyActive, workoutName);

    return buttonBuilder(
      context,
      () => _handlePressed(context, ref),
      isSessionAlreadyActive,
      child,
    );
  }

  Widget _buildActiveSessionButton(BuildContext context, WidgetRef ref) {
    return ref
        .watch(activeSessionIdProvider)
        .when(
          loading: _loading,
          error: (_, _) => _error(),
          data: (activeSessionId) {
            if (activeSessionId == null) return _error();

            return ref
                .watch(workoutNameProvider(activeSessionId))
                .when(
                  loading: _loading,
                  error: (_, _) => _error(),
                  data: (workoutName) => _buildLaunchButton(
                    context,
                    ref,
                    isSessionAlreadyActive: true,
                    workoutName: workoutName,
                  ),
                );
          },
        );
  }

  Widget _buildNewSessionButton(BuildContext context, WidgetRef ref) {
    return ref
        .watch(workoutFocusProvider)
        .when(
          loading: _loading,
          error: (_, _) => _error(),
          data: (workoutFocus) => _buildLaunchButton(
            context,
            ref,
            isSessionAlreadyActive: false,
            workoutName: workoutFocus.workoutName,
          ),
        );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(activeSessionLifecycleProvider)
        .when(
          loading: _loading,
          error: (_, _) => _error(),
          data: (isSessionAlreadyActive) => isSessionAlreadyActive
              ? _buildActiveSessionButton(context, ref)
              : _buildNewSessionButton(context, ref),
        );
  }
}
