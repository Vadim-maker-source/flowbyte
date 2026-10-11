import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/remote/assistant_api.dart';
import '../../data/repositories/content_repository.dart';
import '../progress/progress_controller.dart';

enum AssistantRole { learner, byte }

class AssistantMessage {
  const AssistantMessage({required this.role, required this.text});
  final AssistantRole role;
  final String text;
}

class AssistantState {
  const AssistantState({
    this.lessonId,
    this.messages = const [],
    this.loading = false,
    this.unavailable = false,
  });
  final String? lessonId;
  final List<AssistantMessage> messages;
  final bool loading;
  final bool unavailable;

  AssistantState copyWith({
    List<AssistantMessage>? messages,
    bool? loading,
    bool? unavailable,
    String? lessonId,
  }) => AssistantState(
    lessonId: lessonId ?? this.lessonId,
    messages: messages ?? this.messages,
    loading: loading ?? this.loading,
    unavailable: unavailable ?? this.unavailable,
  );
}

class AssistantController extends Notifier<AssistantState> {
  @override
  AssistantState build() => const AssistantState();

  void prepareContext(String lessonId) {
    if (state.lessonId == null) {
      state = AssistantState(lessonId: lessonId, messages: state.messages);
    } else if (state.lessonId != lessonId) {
      state = AssistantState(lessonId: lessonId);
    }
  }

  Future<void> ask(
    String message, {
    required String lessonId,
    required String exerciseId,
  }) async {
    final progress = ref.read(progressProvider);
    final previousMessages = state.lessonId == lessonId
        ? state.messages
        : const <AssistantMessage>[];
    final withQuestion = [
      ...previousMessages,
      AssistantMessage(role: AssistantRole.learner, text: message),
    ];
    if (progress.backendOffline) {
      state = AssistantState(
        lessonId: lessonId,
        messages: withQuestion,
        unavailable: true,
      );
      return;
    }
    state = AssistantState(
      lessonId: lessonId,
      messages: withQuestion,
      loading: true,
    );
    try {
      final course = ref.read(moduleProvider).value;
      final lesson = course?.lessons
          .where((item) => item.id == lessonId)
          .firstOrNull;
      final courseModule = lesson == null
          ? null
          : course?.modules
                .where((item) => item.id == lesson.moduleId)
                .firstOrNull;
      final exercise = lesson?.exercises
          .where((item) => item.id == exerciseId)
          .firstOrNull;
      final history = previousMessages.length > 12
          ? previousMessages.sublist(previousMessages.length - 12)
          : previousMessages;
      final reply = await ref
          .read(assistantApiProvider)
          .ask(
            installationId: progress.installationId,
            lessonId: lessonId,
            exerciseId: exerciseId,
            message: message,
            attempts: progress.totalAttempts,
            hintsUsed: progress.totalHints,
            history: history
                .map(
                  (item) => {
                    'role': item.role == AssistantRole.learner
                        ? 'user'
                        : 'assistant',
                    'content': item.text,
                  },
                )
                .toList(),
            moduleTitle: courseModule?.title,
            lessonTitle: lesson?.title,
            lessonSummary: lesson == null
                ? null
                : [
                    lesson.concept,
                    lesson.ruleOfThumb,
                    ...lesson.deepDive,
                  ].join(' '),
            exercisePrompt: exercise?.prompt,
            currentCode: exercise?.code ?? lesson?.code ?? const [],
          );
      state = AssistantState(
        lessonId: lessonId,
        messages: [
          ...withQuestion,
          AssistantMessage(role: AssistantRole.byte, text: reply),
        ],
      );
    } catch (_) {
      state = AssistantState(
        lessonId: lessonId,
        messages: withQuestion,
        unavailable: true,
      );
    }
  }
}

final assistantControllerProvider =
    NotifierProvider<AssistantController, AssistantState>(
      AssistantController.new,
    );
