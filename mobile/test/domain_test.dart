import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flowbyte/data/models/module_models.dart';
import 'package:flowbyte/features/exercises/exercise_controller.dart';
import 'package:flowbyte/features/ai_tutor/assistant_markup.dart';
import 'package:flowbyte/features/live_trace/live_trace_controller.dart';
import 'package:flowbyte/features/progress/progress_state.dart';

ExerciseModel _exercise({ExerciseType type = ExerciseType.prediction}) =>
    ExerciseModel(
      id: 'test',
      lessonId: 'lesson-1',
      order: 1,
      title: 'Test exercise',
      type: type,
      prompt: 'Test',
      code: const ['if value:', '    move()'],
      resolvedCode: const ['if value:', '    move()'],
      options: type == ExerciseType.reorder
          ? const ['move()', 'if value:']
          : const ['A', 'B'],
      correctAnswer: type == ExerciseType.reorder
          ? const ['if value:', 'move()']
          : const ['B'],
      hints: const ['one', 'two', 'three'],
      explanation: 'Explanation',
      xpReward: 40,
      trace: const [
        TraceStep(
          action: TraceAction.checkCondition,
          activeLine: 1,
          label: 'value → true',
        ),
        TraceStep(
          action: TraceAction.move,
          activeLine: 2,
          label: 'move()',
          position: 1,
        ),
      ],
    );

void main() {
  test('scoring accepts only the exact answer', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final subscription = container.listen(
      exerciseControllerProvider,
      (_, _) {},
    );
    addTearDown(subscription.close);
    final controller = container.read(exerciseControllerProvider.notifier);
    final exercise = _exercise();

    controller.select('A');
    expect(controller.submit(exercise), isFalse);
    controller.select('B');
    expect(controller.submit(exercise), isTrue);
  });

  test('reorder scoring and accessible move use the same model', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final subscription = container.listen(
      exerciseControllerProvider,
      (_, _) {},
    );
    addTearDown(subscription.close);
    final controller = container.read(exerciseControllerProvider.notifier);
    final exercise = _exercise(type: ExerciseType.reorder);

    controller.initialize(exercise);
    expect(controller.submit(exercise), isFalse);
    controller.move(1, -1);
    expect(controller.submit(exercise), isTrue);
  });

  test('hint state advances progressively and stops at the last hint', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final subscription = container.listen(
      exerciseControllerProvider,
      (_, _) {},
    );
    addTearDown(subscription.close);
    final controller = container.read(exerciseControllerProvider.notifier);

    controller.showNextHint(2);
    controller.showNextHint(2);
    controller.showNextHint(2);
    expect(container.read(exerciseControllerProvider).hintIndex, 2);
  });

  test('XP levels and lesson unlocking are deterministic', () {
    final progress = ProgressState.initial(installationId: 'test').copyWith(
      xp: 240,
      completedLessons: {'lesson-1', 'lesson-2'},
      hydrated: true,
    );
    expect(progress.byteLevel, 3);
    expect(progress.xpIntoLevel, 40);
    expect(progress.lessonUnlocked(3), isTrue);
    expect(progress.lessonUnlocked(4), isFalse);
  });

  test('module certificate unlocks only after its required route', () {
    final conditions = ProgressState.initial(installationId: 'test').copyWith(
      completedLessons: {'lesson-1', 'lesson-2', 'lesson-3', 'lesson-4'},
    );
    expect(
      conditions.moduleCompleted(const [
        'lesson-1',
        'lesson-2',
        'lesson-3',
        'lesson-4',
      ], requiresFinal: false),
      isTrue,
    );
    expect(
      conditions.moduleCompleted(const [
        'lesson-5',
        'lesson-6',
        'lesson-7',
        'lesson-8',
      ], requiresFinal: true),
      isFalse,
    );
  });

  test('Live Trace preserves condition then action order', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final subscription = container.listen(liveTraceProvider, (_, _) {});
    addTearDown(subscription.close);
    final trace = _exercise().trace;
    await container.read(liveTraceProvider.notifier).play(trace);
    final state = container.read(liveTraceProvider);
    expect(state.complete, isTrue);
    expect(state.stepIndex, 1);
    expect(state.step?.action, TraceAction.move);
  });

  test('assistant separates fenced Python into highlighted code segments', () {
    final segments = parseAssistantContent(
      'Смотри на условие:\n```python\nif energy > 20:\n    move()\n```\nТеперь проверь значение.',
    );
    expect(segments, hasLength(3));
    expect(segments[0].isCode, isFalse);
    expect(segments[1].isCode, isTrue);
    expect(segments[1].content, contains('if energy > 20:'));
    expect(segments[2].content, 'Теперь проверь значение.');
  });

  test('assistant tolerates an unclosed code fence', () {
    final segments = parseAssistantContent(
      'Пример:\n```python\nfor step in range(3):\n    move()\n``',
    );
    expect(segments, hasLength(2));
    expect(segments.last.isCode, isTrue);
    expect(segments.last.content, isNot(contains('``')));
  });

  test('all course traces change position only on move()', () {
    final json =
        jsonDecode(File('assets/content/module.json').readAsStringSync())
            as Map<String, dynamic>;
    final lessons = json['lessons'] as List<dynamic>;
    final exercises = <Map<String, dynamic>>[
      for (final lesson in lessons)
        ...(lesson as Map<String, dynamic>)['exercises'] as List<dynamic>,
      json['finalMission'] as Map<String, dynamic>,
    ];
    expect(exercises, hasLength(33));

    for (final exercise in exercises) {
      final item = Map<String, dynamic>.from(exercise);
      final code = List<String>.from(item['resolvedCode'] ?? item['code']);
      final simulation = List<Map<String, dynamic>>.from(
        (item['simulation'] as List).map(
          (step) => Map<String, dynamic>.from(step as Map),
        ),
      );
      expect(simulation, isNotEmpty, reason: item['id'] as String);
      var previousPosition = simulation.first['position'] as int? ?? 0;
      for (var index = 0; index < simulation.length; index += 1) {
        final step = simulation[index];
        final activeLine = step['activeLine'] as int;
        expect(
          activeLine,
          inInclusiveRange(1, code.length),
          reason: '${item['id']} has an invalid active line',
        );
        final position = step['position'] as int? ?? previousPosition;
        if (index > 0 && position != previousPosition) {
          expect(
            step['action'],
            'move',
            reason: '${item['id']}: only move() may change Byte position',
          );
          expect(
            (position - previousPosition).abs(),
            1,
            reason: '${item['id']}: one move() advances exactly one cell',
          );
        }
        if (step['action'] == 'move') {
          expect(
            code[activeLine - 1],
            contains('move'),
            reason: '${item['id']}: move trace must highlight move() code',
          );
        }
        previousPosition = position;
      }
    }
  });

  test('bug-hunt exercises show corrected code after success', () {
    final json =
        jsonDecode(File('assets/content/module.json').readAsStringSync())
            as Map<String, dynamic>;
    final bugHunts = <Map<String, dynamic>>[
      for (final lesson in json['lessons'] as List<dynamic>)
        for (final exercise
            in (lesson as Map<String, dynamic>)['exercises'] as List<dynamic>)
          if ((exercise as Map<String, dynamic>)['type'] == 'bugHunt') exercise,
    ];
    expect(bugHunts, isNotEmpty);
    for (final exercise in bugHunts) {
      expect(
        exercise['resolvedCode'],
        isNotNull,
        reason: exercise['id'] as String,
      );
      expect(
        exercise['resolvedCode'],
        isNot(equals(exercise['code'])),
        reason: '${exercise['id']} must visibly replace the faulty line',
      );
    }
  });
}
