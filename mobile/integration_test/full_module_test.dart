import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flowbyte/app/app.dart';
import 'package:flowbyte/app/router.dart';
import 'package:flowbyte/features/progress/progress_controller.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'Welcome through four lessons and final completion remains navigable',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        'flowbyte.progress.v1': jsonEncode({
          'installationId': '00000000-0000-4000-8000-000000000002',
          'onboardingComplete': true,
          'completedLessons': <String>[],
          'xp': 0,
          'attempts': <String, int>{},
          'usedHints': <String, int>{},
          'finalComplete': false,
          'backendOffline': true,
        }),
      });
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const FlowbyteApp(),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 1));
      expect(find.text('Решения и повторения'), findsOneWidget);

      for (var lesson = 1; lesson <= 4; lesson += 1) {
        appRouter.go('/lesson/lesson-$lesson');
        await tester.pumpAndSettle();
        expect(find.textContaining('К практике'), findsOneWidget);
        await container
            .read(progressProvider.notifier)
            .completeLesson('lesson-$lesson', 40);
      }

      appRouter.go('/final');
      await tester.pumpAndSettle();
      expect(find.text('Запрограммируй маршрут'), findsOneWidget);
      await container.read(progressProvider.notifier).completeFinal(100);
      appRouter.go('/complete');
      await tester.pumpAndSettle();
      expect(find.text('Модуль завершён'), findsOneWidget);
    },
  );
}
