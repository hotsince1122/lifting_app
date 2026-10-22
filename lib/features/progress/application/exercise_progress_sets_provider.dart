import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/features/progress/data/exercise_progress_queries.dart';
import 'package:lifting_tracker_app/features/progress/domain/exercise_progress_set.dart';

final exerciseProgressSetsProvider = FutureProvider.family
    .autoDispose<List<ExerciseProgressSet>, String>((ref, exerciseId) async {
      return await loadExerciseProgressSets(exerciseId);
    });
