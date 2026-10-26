import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/features/progress/data/exercise_progress_queries.dart';

final exerciseHasHistoryProvider = FutureProvider.family
    .autoDispose<bool, String>((ref, exerciseId) async {
      return await loadIfExerciseHasHistory(exerciseId);
    });
