import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/features/progress/data/favorite_exercise_commands.dart'
    as commands;
import 'package:lifting_tracker_app/features/progress/data/favorite_exercise_queries.dart'
    as queries;

final favoriteExerciseIdsProvider =
    AsyncNotifierProvider<FavoriteExerciseIdsController, Set<String>>(
      FavoriteExerciseIdsController.new,
    );

class FavoriteExerciseIdsController extends AsyncNotifier<Set<String>> {
  @override
  Future<Set<String>> build() {
    return queries.loadFavoriteExerciseIds();
  }

  Future<void> setFavorite(
    String exerciseId, {
    required bool isFavorite,
  }) async {
    if (isFavorite) {
      await commands.addFavoriteExercise(exerciseId);
    } else {
      await commands.removeFavoriteExercise(exerciseId);
    }

    if (ref.mounted) ref.invalidateSelf();
  }
}
