import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../data/repositories/content_repository.dart';
import '../../shared/widgets/app_buttons.dart';
import '../../shared/widgets/byte_avatar.dart';
import '../../shared/widgets/code_block.dart';
import '../../shared/widgets/pressable.dart';
import '../progress/progress_controller.dart';
import 'assistant_controller.dart';
import 'assistant_markup.dart';

class AssistantScreen extends ConsumerStatefulWidget {
  const AssistantScreen({super.key, this.lessonId, this.moduleId, this.topic});

  final String? lessonId;
  final String? moduleId;
  final String? topic;

  @override
  ConsumerState<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends ConsumerState<AssistantScreen> {
  final _text = TextEditingController();
  final _scroll = ScrollController();
  String? _preparedLessonId;

  @override
  void dispose() {
    _text.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(assistantControllerProvider);
    final progress = ref.watch(progressProvider);
    final course = ref.watch(moduleProvider).value;
    final lessonId = widget.lessonId ?? 'lesson-${progress.nextLessonNumber}';
    final lesson = course?.lessons
        .where((item) => item.id == lessonId)
        .firstOrNull;
    final moduleId = widget.moduleId ?? lesson?.moduleId;
    final courseModule = course?.modules
        .where((item) => item.id == moduleId)
        .firstOrNull;
    final contextTitle = lesson == null
        ? 'Текущий учебный маршрут'
        : '${courseModule?.title ?? 'Python'} · ${lesson.title}';
    if (_preparedLessonId != lessonId) {
      _preparedLessonId = lessonId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref
              .read(assistantControllerProvider.notifier)
              .prepareContext(lessonId);
        }
      });
    }
    final contextMatches = state.lessonId == null || state.lessonId == lessonId;
    final messages = contextMatches
        ? state.messages
        : const <AssistantMessage>[];
    final loading = contextMatches && state.loading;
    final requestFailed = contextMatches && state.unavailable;
    final unavailable = requestFailed || progress.backendOffline;
    final showIntro = messages.isEmpty;

    ref.listen(assistantControllerProvider, (previous, next) {
      if (next.messages.length != previous?.messages.length || next.loading) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
      }
    });

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        leadingWidth: 60,
        leading: Padding(
          padding: const EdgeInsets.only(left: AppSpacing.xs),
          child: AppIconButton(
            icon: AppIcons.back,
            label: 'Назад',
            onPressed: () =>
                context.canPop() ? context.pop() : context.go('/home'),
          ),
        ),
        title: const Text('Помощник Byte', style: AppTypography.label),
        centerTitle: true,
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen,
            AppSpacing.xs,
            AppSpacing.screen,
            AppSpacing.sm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (showIntro) ...[
                ByteAvatar(
                  size: 104,
                  mood: unavailable ? ByteMood.offline : ByteMood.thinking,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  unavailable
                      ? 'Помощник сейчас недоступен.'
                      : 'Разберём логику вместе',
                  textAlign: TextAlign.center,
                  style: AppTypography.h1,
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  unavailable
                      ? 'Подсказки урока продолжают работать.'
                      : 'Помнит диалог, знает текущий урок и сразу показывает код, если попросишь.',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodySmall,
                ),
                const SizedBox(height: AppSpacing.sm),
              ] else ...[
                _ContextChip(label: contextTitle),
                const SizedBox(height: AppSpacing.sm),
              ],
              Expanded(
                child: unavailable && messages.isEmpty
                    ? const SingleChildScrollView(child: _OfflineActions())
                    : messages.isEmpty
                    ? _AssistantWelcome(
                        contextTitle: contextTitle,
                        topic: widget.topic,
                        onPrompt: _askPrompt,
                      )
                    : ListView.separated(
                        controller: _scroll,
                        padding: EdgeInsets.zero,
                        itemCount:
                            messages.length + (loading || unavailable ? 1 : 0),
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: AppSpacing.xs),
                        itemBuilder: (context, index) {
                          if (index < messages.length) {
                            return _MessageBubble(message: messages[index]);
                          }
                          return loading
                              ? const _ThinkingBubble()
                              : const _UnavailableBubble();
                        },
                      ),
              ),
              const SizedBox(height: AppSpacing.sm),
              if (!progress.backendOffline)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _text,
                        minLines: 1,
                        maxLines: 4,
                        textInputAction: TextInputAction.send,
                        onSubmitted: loading ? null : (_) => _send(),
                        decoration: const InputDecoration(
                          hintText: 'Спроси про код или условие…',
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    _SendButton(
                      loading: loading,
                      onPressed: loading ? null : _send,
                    ),
                  ],
                )
              else
                PrimaryButton(
                  label: 'Вернуться к урокам',
                  onPressed: () => context.go('/home'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _send() {
    final message = _text.text.trim();
    if (message.isEmpty) return;
    final progress = ref.read(progressProvider);
    final lessonId = widget.lessonId ?? 'lesson-${progress.nextLessonNumber}';
    final course = ref.read(moduleProvider).value;
    final lesson = course?.lessons
        .where((item) => item.id == lessonId)
        .firstOrNull;
    final moduleId = widget.moduleId ?? lesson?.moduleId ?? 'course';
    ref
        .read(assistantControllerProvider.notifier)
        .ask(message, lessonId: lessonId, exerciseId: 'theory-$moduleId');
    _text.clear();
  }

  void _askPrompt(String value) {
    _text.text = value;
    _send();
  }

  void _scrollToBottom() {
    if (!_scroll.hasClients) return;
    _scroll.animateTo(
      _scroll.position.maxScrollExtent,
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOut,
    );
  }
}

class _ContextChip extends StatelessWidget {
  const _ContextChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.sm,
      vertical: AppSpacing.xs,
    ),
    decoration: BoxDecoration(
      color: AppColors.surfaceInteractive,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      border: Border.all(color: AppColors.primary.withValues(alpha: .45)),
    ),
    child: Row(
      children: [
        const AppIcon(AppIcons.book, size: 14, color: AppColors.primary),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    ),
  );
}

class _AssistantWelcome extends StatelessWidget {
  const _AssistantWelcome({
    required this.contextTitle,
    required this.topic,
    required this.onPrompt,
  });

  final String contextTitle;
  final String? topic;
  final ValueChanged<String> onPrompt;

  @override
  Widget build(BuildContext context) {
    final prompts = [
      if (topic != null) 'Объясни раздел «$topic» ещё проще.',
      'Покажи ещё один пример по теме этого урока.',
      'Задай мне вопрос, чтобы проверить понимание.',
    ];
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _ContextChip(label: contextTitle),
        const SizedBox(height: AppSpacing.xs),
        Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.divider),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppIcon(AppIcons.info, size: 16, color: AppColors.primary),
              SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Опиши, что уже понял и на какой строке запутался. Не отправляй личные данные.',
                  style: AppTypography.bodySmall,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        for (final prompt in prompts)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: SecondaryButton(
              label: prompt,
              onPressed: () => onPrompt(prompt),
            ),
          ),
      ],
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});
  final AssistantMessage message;

  @override
  Widget build(BuildContext context) {
    final learner = message.role == AssistantRole.learner;
    final segments = parseAssistantContent(message.text);
    return Align(
      alignment: learner ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 338),
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: learner ? AppColors.surfaceInteractive : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: learner ? AppColors.primary : AppColors.divider,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              learner ? 'ТЫ' : 'BYTE · ИИ',
              style: AppTypography.caption.copyWith(
                color: learner ? AppColors.primary : AppColors.success,
              ),
            ),
            const SizedBox(height: AppSpacing.xxs),
            for (var index = 0; index < segments.length; index += 1) ...[
              if (index > 0) const SizedBox(height: AppSpacing.xs),
              if (segments[index].isCode)
                _PythonCodeSegment(code: segments[index].content)
              else
                Text(segments[index].content, style: AppTypography.bodySmall),
            ],
          ],
        ),
      ),
    );
  }
}

class _PythonCodeSegment extends StatelessWidget {
  const _PythonCodeSegment({required this.code});
  final String code;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: 3,
        ),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: .12),
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.sm),
          ),
        ),
        child: Text(
          'PYTHON',
          style: AppTypography.caption.copyWith(
            color: AppColors.primary,
            letterSpacing: 1,
          ),
        ),
      ),
      CodeBlock(lines: code.split(RegExp(r'\r?\n'))),
    ],
  );
}

class _ThinkingBubble extends StatelessWidget {
  const _ThinkingBubble();

  @override
  Widget build(BuildContext context) => const Align(
    alignment: Alignment.centerLeft,
    child: SizedBox(width: 54, child: LinearProgressIndicator(minHeight: 3)),
  );
}

class _UnavailableBubble extends StatelessWidget {
  const _UnavailableBubble();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.sm),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.md),
      border: Border.all(color: AppColors.error.withValues(alpha: .6)),
    ),
    child: const Text(
      'Byte не получил ответ от сервера. Теория и подсказки урока продолжают работать.',
      style: AppTypography.bodySmall,
    ),
  );
}

class _SendButton extends StatelessWidget {
  const _SendButton({required this.loading, required this.onPressed});
  final bool loading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => Pressable(
    semanticLabel: 'Отправить',
    onTap: onPressed == null
        ? null
        : () {
            HapticFeedback.lightImpact();
            onPressed!();
          },
    child: ClipPath(
      clipper: const CutCornerClipper(cut: 9),
      child: Container(
        width: 52,
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: onPressed == null ? AppColors.surfaceInteractive : null,
          gradient: onPressed == null
              ? null
              : const LinearGradient(
                  colors: [AppColors.primary, AppColors.secondaryAccent],
                ),
        ),
        child: loading
            ? const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.background,
                ),
              )
            : const AppIcon(
                AppIcons.send,
                size: 18,
                color: AppColors.background,
              ),
      ),
    ),
  );
}

class _OfflineActions extends StatelessWidget {
  const _OfflineActions();

  @override
  Widget build(BuildContext context) => Column(
    children: [
      _OfflineRow(
        icon: AppIcons.lightbulb,
        title: 'Открыть подсказки урока',
        copy: 'Краткие объяснения и примеры работают локально.',
        onTap: () => context.go('/home'),
      ),
      const SizedBox(height: AppSpacing.xs),
      _OfflineRow(
        icon: AppIcons.rotate,
        title: 'Возвращайся позже',
        copy: 'Твой прогресс уже сохранён на устройстве.',
        onTap: () => context.canPop() ? context.pop() : context.go('/home'),
      ),
    ],
  );
}

class _OfflineRow extends StatelessWidget {
  const _OfflineRow({
    required this.icon,
    required this.title,
    required this.copy,
    required this.onTap,
  });
  final FaIconData icon;
  final String title;
  final String copy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(AppRadius.md),
    child: Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          AppIcon(icon, color: AppColors.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.title),
                const SizedBox(height: AppSpacing.xxs),
                Text(copy, style: AppTypography.caption),
              ],
            ),
          ),
          const AppIcon(AppIcons.next, size: 15, color: AppColors.textMuted),
        ],
      ),
    ),
  );
}
