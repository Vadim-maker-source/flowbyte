import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flowbyte/features/exercises/exercise_screen.dart';
import 'package:flowbyte/features/ai_tutor/assistant_screen.dart';
import 'package:flowbyte/features/home/home_screen.dart';
import 'package:flowbyte/features/lessons/lesson_screen.dart';
import 'package:flowbyte/features/onboarding/welcome_screen.dart';
import 'package:flowbyte/features/profile/profile_screen.dart';
import 'package:flowbyte/features/rewards/reward_screen.dart';
import 'package:flowbyte/data/models/module_models.dart';
import 'package:flowbyte/data/repositories/content_repository.dart';
import 'package:flowbyte/data/remote/assistant_api.dart';
import 'package:flowbyte/core/theme/app_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _host(Widget child, {AssistantApi? assistantApi}) {
  final module = ModuleModel.fromJson(
    jsonDecode(File('assets/content/module.json').readAsStringSync())
        as Map<String, dynamic>,
  );
  final router = GoRouter(
    routes: [GoRoute(path: '/', builder: (_, _) => child)],
  );
  return ProviderScope(
    overrides: [
      moduleProvider.overrideWith((ref) async => module),
      if (assistantApi != null)
        assistantApiProvider.overrideWithValue(assistantApi),
    ],
    child: MaterialApp.router(routerConfig: router, theme: ThemeData.dark()),
  );
}

void _setViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(393, 852);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void _progress({
  int xp = 0,
  List<String> completed = const [],
  bool backendOffline = false,
}) {
  SharedPreferences.setMockInitialValues({
    'flowbyte.progress.v1': jsonEncode({
      'installationId': '00000000-0000-4000-8000-000000000001',
      'onboardingComplete': true,
      'completedLessons': completed,
      'xp': xp,
      'attempts': <String, int>{},
      'usedHints': <String, int>{},
      'finalComplete': false,
      'backendOffline': backendOffline,
    }),
  });
}

void main() {
  testWidgets('Welcome explains the value and has no registration', (
    tester,
  ) async {
    _setViewport(tester);
    await tester.pumpWidget(_host(const WelcomeScreen()));
    expect(find.textContaining('Научи Byte'), findsOneWidget);
    expect(find.text('Начать'), findsOneWidget);
    expect(find.textContaining('регистрац'), findsOneWidget);
    expect(find.text('Войти'), findsNothing);
  });

  testWidgets('Home shows progress, active lesson, and continue action', (
    tester,
  ) async {
    _setViewport(tester);
    _progress(xp: 70, completed: ['lesson-1']);
    await tester.pumpWidget(_host(const HomeScreen()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Python: условный оператор'), findsOneWidget);
    expect(find.text('1 из 4 уроков'), findsOneWidget);
    expect(find.text('Byte AI'), findsOneWidget);
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -700));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Продолжить'), findsOneWidget);
  });

  testWidgets('Profile shows local progress and module certificates', (
    tester,
  ) async {
    _setViewport(tester);
    _progress(xp: 90, completed: ['lesson-1', 'lesson-2']);
    await tester.pumpWidget(_host(const ProfileScreen()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Курсант Byte'), findsOneWidget);
    expect(find.text('2/8'), findsOneWidget);
    expect(find.text('СЕРТИФИКАТЫ МОДУЛЕЙ'), findsOneWidget);
    expect(find.text('Python: условный оператор'), findsOneWidget);
  });

  testWidgets('Lesson is short and leads to practice', (tester) async {
    _setViewport(tester);
    _progress();
    await tester.pumpWidget(_host(const LessonScreen(lessonId: 'lesson-2')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Два пути'), findsOneWidget);
    expect(find.textContaining('К практике'), findsOneWidget);
    expect(find.textContaining('if и else'), findsOneWidget);
    expect(find.textContaining('Уточнить у Byte'), findsOneWidget);
    expect(find.byTooltip('Уточнить у Byte'), findsAtLeastNWidgets(1));
  });

  testWidgets('Assistant becomes a compact chat and highlights Python code', (
    tester,
  ) async {
    _setViewport(tester);
    _progress();
    final assistantApi = _FakeAssistantApi();
    await tester.pumpWidget(
      _host(
        const AssistantScreen(
          lessonId: 'lesson-2',
          moduleId: 'conditions',
          topic: 'объяснение на пальцах',
        ),
        assistantApi: assistantApi,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    final fieldRect = tester.getRect(find.byType(TextField));
    final sendIcon = find.byWidgetPredicate(
      (widget) => widget is AppIcon && widget.icon == AppIcons.send,
    );
    expect(sendIcon, findsOneWidget);
    expect(
      (tester.getCenter(sendIcon).dy - fieldRect.center.dy).abs(),
      lessThan(2),
    );

    await tester.tap(find.text('Покажи ещё один пример по теме этого урока.'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Разберём логику вместе'), findsNothing);
    expect(find.text('PYTHON'), findsOneWidget);
    expect(find.textContaining('if energy > 20:'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'А если значения равны?');
    await tester.tap(sendIcon);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(assistantApi.histories, hasLength(2));
    expect(assistantApi.histories.last, hasLength(2));
    expect(assistantApi.histories.last.first['role'], 'user');
    expect(
      assistantApi.histories.last.first['content'],
      'Покажи ещё один пример по теме этого урока.',
    );
  });

  testWidgets('Wrong prediction opens constructive feedback', (tester) async {
    _setViewport(tester);
    _progress();
    await tester.pumpWidget(
      _host(const ExerciseScreen(exerciseId: 'prediction-door')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    await tester.ensureVisible(find.text('Останется на месте'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Останется на месте'));
    await tester.pump();
    await tester.tap(find.text('Запустить'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Почти.'), findsOneWidget);
    expect(find.text('Попробовать ещё'), findsOneWidget);
    expect(find.text('Подсказка'), findsOneWidget);
  });

  testWidgets('Reward exposes XP and explanation', (tester) async {
    _setViewport(tester);
    _progress(xp: 40, completed: ['lesson-1']);
    await tester.pumpWidget(
      _host(const RewardScreen(exerciseId: 'prediction-door')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Система отвечает!'), findsOneWidget);
    expect(find.text('+20 XP'), findsOneWidget);
    expect(find.textContaining('Шлюз A-7'), findsOneWidget);
  });
}

class _FakeAssistantApi extends AssistantApi {
  final List<List<Map<String, String>>> histories = [];

  @override
  Future<String> ask({
    required String installationId,
    required String message,
    required String lessonId,
    required String exerciseId,
    required int attempts,
    required int hintsUsed,
    required List<Map<String, String>> history,
    String? moduleTitle,
    String? lessonTitle,
    String? lessonSummary,
    String? exercisePrompt,
    List<String> currentCode = const [],
  }) async {
    histories.add(history);
    return 'Проверь условие:\n```python\nif energy > 20:\n    move()\n```\nЧто получится?';
  }
}
