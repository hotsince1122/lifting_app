import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/data/muscle_groups.dart';
import 'package:lifting_tracker_app/providers/all_exercises_from_a_muscle_group.dart';
import 'package:lifting_tracker_app/theme/app_colors.dart';

class AddExerciseSelector extends ConsumerStatefulWidget {
  const AddExerciseSelector(this.screenWidth, {super.key});

  final double screenWidth;

  @override
  ConsumerState<AddExerciseSelector> createState() =>
      AddExerciseSelectorState();
}

class AddExerciseSelectorState extends ConsumerState<AddExerciseSelector> {
  final _navKey = GlobalKey<NavigatorState>();

  String? _title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 32),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.72,
          width: widget.screenWidth,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: AppColors.darkCardsMain.withAlpha(253),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                child: _Header(
                  canGoBack: _title == null ? false : true,
                  onBack: () {
                    setState(() {
                      _title = null;
                    });
                    _navKey.currentState?.maybePop();
                  },
                  onClose: () => Navigator.of(context).pop(),
                  title: _title,
                ),
              ),
              const SizedBox(height: 6),
              Expanded(
                child: Navigator(
                  clipBehavior: Clip.hardEdge,
                  key: _navKey,
                  onGenerateRoute: (_) => _sheetParallaxRoute(
                    _MuscleGroupList(
                      onSelectGroup: (label) {
                        setState(() {
                          _title = label;
                        });
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.canGoBack,
    required this.onBack,
    required this.onClose,
  });

  final String? title;
  final bool canGoBack;
  final VoidCallback onClose;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: canGoBack ? onBack : onClose,
          iconSize: 18,
          icon: Icon(canGoBack ? Icons.arrow_back_ios_rounded : Icons.close),
        ),
        Text(
          title ?? 'Select Exercise',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        IconButton(onPressed: () {}, iconSize: 21, icon: Icon(Icons.add)),
      ],
    );
  }
}

class _MuscleGroupList extends StatelessWidget {
  const _MuscleGroupList({required this.onSelectGroup});

  final void Function(String label) onSelectGroup;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      child: ListView.separated(
        padding: EdgeInsets.zero,
        itemCount: MuscleGroups.names.length,
        separatorBuilder: (_, _) =>
            const Divider(height: 1, color: AppColors.darkCardsSecodary),
        itemBuilder: (context, i) {
          final muscleGroup = MuscleGroups.names[i];
          final label = muscleGroup[0].toUpperCase() + muscleGroup.substring(1);

          return ListTile(
            dense: true,
            visualDensity: const VisualDensity(horizontal: 0, vertical: 0),
            minVerticalPadding: 0,
            contentPadding: const EdgeInsets.symmetric(horizontal: 6),
            title: Text(label, style: Theme.of(context).textTheme.bodyLarge),
            trailing: const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppColors.darkCardsSecodary,
            ),
            onTap: () {
              onSelectGroup(label);
              Navigator.of(
                context,
              ).push(_sheetParallaxRoute(_ExercisesForGroupPage(muscleGroup)));
            },
          );
        },
      ),
    );
  }
}

class _ExercisesForGroupPage extends ConsumerWidget {
  const _ExercisesForGroupPage(this.muscleGroup);

  final String muscleGroup;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exercisesAsync = ref.watch(exercisesFromAMuscleGroup(muscleGroup));

    return exercisesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => Text('An error occured! Try again.'),
      data: (exercises) => Container(
        height: double.infinity,
        width: double.infinity,
        color: AppColors.darkCardsMain.withAlpha(253),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: ListView.separated(
            padding: EdgeInsets.zero,
            itemCount: exercises.length,
            separatorBuilder: (_, _) =>
                const Divider(height: 1, color: AppColors.darkCardsSecodary),
            itemBuilder: (context, i) {
              final exercise = exercises[i];

              final label =
                  exercise.name[0].toUpperCase() +
                  exercise.name.substring(1);
          
              return ListTile(
                dense: true,
                visualDensity: const VisualDensity(horizontal: 0, vertical: 0),
                minVerticalPadding: 0,
                contentPadding: const EdgeInsets.symmetric(horizontal: 6),
                trailing: Icon(Icons.info_outline, size: 21,),
                title: Text(label, style: Theme.of(context).textTheme.bodyLarge),
                onTap: () => Navigator.of(context, rootNavigator: true).pop(exercise),
              );
            },
          ),
        ),
      ),
    );
  }
}

Route<T> _sheetParallaxRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    opaque: true,
    transitionDuration: const Duration(milliseconds: 280),
    reverseTransitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      // Cum intră pagina asta (de sus): din dreapta
      final inCurve = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );

      final inSlide = Tween<Offset>(
        begin: const Offset(1, 0),
        end: Offset.zero,
      ).animate(inCurve);

      // Cum se mișcă pagina asta când devine "în spate" (când altă pagină e împinsă peste ea)
      final backCurve = CurvedAnimation(
        parent: secondaryAnimation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );

      final backSlide = Tween<Offset>(
        begin: Offset.zero,
        end: const Offset(-0.20, 0), // puțin spre stânga
      ).animate(backCurve);

      final backScale = Tween<double>(
        begin: 1.0,
        end: 0.98, // ușor "în spate"
      ).animate(backCurve);

      // IMPORTANT: fără Opacity/Fade/Color overlay. Doar transformări.
      return SlideTransition(
        position: backSlide,
        child: ScaleTransition(
          scale: backScale,
          child: SlideTransition(position: inSlide, child: child),
        ),
      );
    },
  );
}
