import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/module_models.dart';

class ExerciseState {
  const ExerciseState({
    this.selected,
    this.ordered = const [],
    this.hintIndex = 0,
    this.submitted = false,
    this.correct = false,
  });

  final String? selected;
  final List<String> ordered;
  final int hintIndex;
  final bool submitted;
  final bool correct;

  ExerciseState copyWith({
    String? selected,
    List<String>? ordered,
    int? hintIndex,
    bool? submitted,
    bool? correct,
  }) => ExerciseState(
    selected: selected ?? this.selected,
    ordered: ordered ?? this.ordered,
    hintIndex: hintIndex ?? this.hintIndex,
    submitted: submitted ?? this.submitted,
    correct: correct ?? this.correct,
  );
}

class ExerciseController extends Notifier<ExerciseState> {
  @override
  ExerciseState build() => const ExerciseState();

  void initialize(ExerciseModel exercise) {
    if (state.ordered.isEmpty &&
        (exercise.type == ExerciseType.reorder ||
            exercise.type == ExerciseType.finalMission)) {
      state = ExerciseState(ordered: List<String>.from(exercise.options));
    }
  }

  void select(String value) =>
      state = state.copyWith(selected: value, submitted: false);

  void reorder(int oldIndex, int newIndex) {
    final items = List<String>.from(state.ordered);
    if (newIndex > oldIndex) newIndex -= 1;
    final item = items.removeAt(oldIndex);
    items.insert(newIndex, item);
    state = state.copyWith(ordered: items, submitted: false);
  }

  void move(int index, int delta) {
    final destination = index + delta;
    if (destination < 0 || destination >= state.ordered.length) return;
    final items = List<String>.from(state.ordered);
    final item = items.removeAt(index);
    items.insert(destination, item);
    state = state.copyWith(ordered: items, submitted: false);
  }

  bool submit(ExerciseModel exercise) {
    final actual =
        exercise.type == ExerciseType.reorder ||
            exercise.type == ExerciseType.finalMission
        ? state.ordered
        : [if (state.selected != null) state.selected!];
    final correct =
        actual.length == exercise.correctAnswer.length &&
        List.generate(
          actual.length,
          (index) => actual[index] == exercise.correctAnswer[index],
        ).every((value) => value);
    state = state.copyWith(submitted: true, correct: correct);
    return correct;
  }

  void showNextHint(int max) =>
      state = state.copyWith(hintIndex: (state.hintIndex + 1).clamp(0, max));
  void retry() => state = state.copyWith(submitted: false, correct: false);
  void reset() => state = const ExerciseState();
}

final exerciseControllerProvider =
    NotifierProvider.autoDispose<ExerciseController, ExerciseState>(
      ExerciseController.new,
    );
