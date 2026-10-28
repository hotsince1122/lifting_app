import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/core/errors/snack_bar_error.dart';
import 'package:lifting_tracker_app/features/progress/application/favorite_exercise_ids_controller.dart';

class FavoriteExerciseAction extends ConsumerStatefulWidget {
  const FavoriteExerciseAction({
    super.key,
    required this.exerciseId,
    required this.builder,
  });

  final String exerciseId;
  final Widget Function(bool isFavorite, VoidCallback? onPressed) builder;

  @override
  ConsumerState<FavoriteExerciseAction> createState() =>
      _FavoriteExerciseActionState();
}

class _FavoriteExerciseActionState
    extends ConsumerState<FavoriteExerciseAction> {
  bool _isSaving = false;

  Future<void> _toggle() async {
    if (_isSaving) return;
    final exerciseId = widget.exerciseId;
    setState(() => _isSaving = true);

    try {
      if (ref.read(favoriteExerciseIdsProvider).hasError) {
        ref.invalidate(favoriteExerciseIdsProvider);
      }
      final ids = await ref.read(favoriteExerciseIdsProvider.future);
      if (!mounted) return;

      await ref
          .read(favoriteExerciseIdsProvider.notifier)
          .setFavorite(exerciseId, isFavorite: !ids.contains(exerciseId));
      if (!mounted) return;

      // Keep the action disabled until every star has the refreshed state.
      await ref.read(favoriteExerciseIdsProvider.future);
    } catch (_) {
      if (mounted) {
        SnackBarError.show(
          context,
          'Could not update favorites. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final favorites = ref.watch(favoriteExerciseIdsProvider);
    final isFavorite = favorites.value?.contains(widget.exerciseId) ?? false;

    return widget.builder(
      isFavorite,
      _isSaving || favorites.isLoading ? null : _toggle,
    );
  }
}
