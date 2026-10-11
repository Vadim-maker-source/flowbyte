import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flowbyte/app/app.dart';
import 'package:flowbyte/app/router.dart';
import 'package:flowbyte/data/models/module_models.dart';
import 'package:flowbyte/data/repositories/content_repository.dart';
import 'package:flowbyte/features/progress/progress_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('full required route has no navigation dead ends', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({
      'flowbyte.progress.v1': jsonEncode({
        'installationId': '00000000-0000-4000-8000-000000000003',
        'onboardingComplete': true,
        'completedLessons': <String>[],
        'xp': 0,
        'attempts': <String, int>{},
        'usedHints': <String, int>{},
        'finalComplete': false,
        'backendOffline': true,
      }),
    });
    final module = ModuleModel.fromJson(
      jsonDecode(File('assets/content/module.json').readAsStringSync())
          as Map<String, dynamic>,
    );
    expect(module.modules, hasLength(2));
    expect(module.lessons, hasLength(8));
    expect(module.lessons.expand((lesson) => lesson.exercises), hasLength(32));
    expect(module.nextExercise('prediction-door')?.id, 'prediction-low-energy');
    final container = ProviderContainer(
      overrides: [moduleProvider.overrideWith((ref) async => module)],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const FlowbyteApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    appRouter.go('/home');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Python: условный оператор'), findsOneWidget);

    for (var lesson = 1; lesson <= 8; lesson += 1) {
      appRouter.go('/lesson/lesson-$lesson');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.textContaining('К практике'), findsOneWidget);
      await container
          .read(progressProvider.notifier)
          .completeLesson('lesson-$lesson', 40);
    }

    appRouter.go('/final');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('Запрограммируй маршрут'), findsOneWidget);
    await container.read(progressProvider.notifier).completeFinal(100);
    appRouter.go('/complete');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('Курс пройден'), findsOneWidget);
  });
}
