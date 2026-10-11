import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../data/repositories/progress_repository.dart';
import 'progress_state.dart';

class ProgressController extends Notifier<ProgressState> {
  @override
  ProgressState build() {
    unawaited(_hydrate());
    return ProgressState.initial();
  }

  Future<void> _hydrate() async {
    final loaded = await ref.read(progressRepositoryProvider).load();
    state = loaded.copyWith(
      installationId: loaded.installationId.isEmpty
          ? const Uuid().v4()
          : loaded.installationId,
      hydrated: true,
    );
  }

  Future<void> _commit(ProgressState next) async {
    state = next;
    await ref.read(progressRepositoryProvider).save(next);
  }

  Future<void> completeOnboarding() =>
      _commit(state.copyWith(onboardingComplete: true));

  Future<void> recordAttempt(
    String exerciseId, {
    required bool correct,
    required int hintsUsed,
  }) async {
    final attempts = Map<String, int>.from(state.attempts)
      ..update(exerciseId, (value) => value + 1, ifAbsent: () => 1);
    final hints = Map<String, int>.from(state.usedHints)
      ..[exerciseId] = hintsUsed;
    await _commit(state.copyWith(attempts: attempts, usedHints: hints));
  }

  Future<void> completeLesson(String lessonId, int xpReward) async {
    final alreadyComplete = state.completedLessons.contains(lessonId);
    final completed = Set<String>.from(state.completedLessons)..add(lessonId);
    await _commit(
      state.copyWith(
        completedLessons: completed,
        xp: alreadyComplete ? state.xp : state.xp + xpReward,
      ),
    );
  }

  Future<void> completeExercise(
    String exerciseId,
    String lessonId,
    int xpReward, {
    required bool lessonComplete,
  }) async {
    final alreadyComplete = state.completedExercises.contains(exerciseId);
    final exercises = Set<String>.from(state.completedExercises)
      ..add(exerciseId);
    final lessons = Set<String>.from(state.completedLessons);
    if (lessonComplete) lessons.add(lessonId);
    await _commit(
      state.copyWith(
        completedExercises: exercises,
        completedLessons: lessons,
        xp: alreadyComplete ? state.xp : state.xp + xpReward,
      ),
    );
  }

  Future<void> completeFinal(int xpReward) => _commit(
    state.copyWith(
      finalComplete: true,
      xp: state.finalComplete ? state.xp : state.xp + xpReward,
    ),
  );

  Future<void> reset() async {
    await ref.read(progressRepositoryProvider).clear();
    await _commit(
      ProgressState.initial(
        installationId: const Uuid().v4(),
      ).copyWith(hydrated: true),
    );
  }

  Future<void> unlockNext() async {
    final number = (state.completedLessons.length + 1).clamp(1, 8);
    await _commit(
      state.copyWith(
        completedLessons: Set<String>.from(state.completedLessons)
          ..add('lesson-$number'),
      ),
    );
  }

  Future<void> setXp(int xp) => _commit(state.copyWith(xp: xp.clamp(0, 999)));
  Future<void> setBackendOffline(bool value) =>
      _commit(state.copyWith(backendOffline: value));
}

final progressProvider = NotifierProvider<ProgressController, ProgressState>(
  ProgressController.new,
);
