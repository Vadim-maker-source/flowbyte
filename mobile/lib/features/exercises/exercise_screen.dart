import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/module_models.dart';
import '../../data/repositories/content_repository.dart';
import '../../shared/widgets/app_buttons.dart';
import '../../shared/widgets/byte_avatar.dart';
import '../../shared/widgets/code_block.dart';
import '../../shared/widgets/live_trace_stage.dart';
import '../../shared/widgets/pressable.dart';
import '../live_trace/live_trace_controller.dart';
import '../progress/progress_controller.dart';
import 'exercise_controller.dart';

class ExerciseScreen extends ConsumerStatefulWidget {
  const ExerciseScreen({super.key, required this.exerciseId});
  final String exerciseId;

  @override
  ConsumerState<ExerciseScreen> createState() => _ExerciseScreenState();
}

class _ExerciseScreenState extends ConsumerState<ExerciseScreen> {
  String? _initializedFor;

  void _ensureInitialized(ExerciseModel exercise) {
    if (_initializedFor == exercise.id) {
      return;
    }
    _initializedFor = exercise.id;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(liveTraceProvider.notifier).reset();
        ref.read(exerciseControllerProvider.notifier).initialize(exercise);
      }
    });
  }

  Future<void> _submit(ExerciseModel exercise, ModuleModel content) async {
    final controller = ref.read(exerciseControllerProvider.notifier);
    final correct = controller.submit(exercise);
    final exerciseState = ref.read(exerciseControllerProvider);
    await ref
        .read(progressProvider.notifier)
        .recordAttempt(
          exercise.id,
          correct: correct,
          hintsUsed: exerciseState.hintIndex,
        );
    if (!mounted) return;
    if (!correct) {
      await _showWrongSheet(exercise);
      return;
    }
    await ref.read(liveTraceProvider.notifier).play(exercise.trace);
    if (!mounted) return;
    final lesson = content.lessonForExercise(exercise.id);
    final lessonComplete = lesson.exercises.last.id == exercise.id;
    await ref
        .read(progressProvider.notifier)
        .completeExercise(
          exercise.id,
          exercise.lessonId,
          exercise.xpReward,
          lessonComplete: lessonComplete,
        );
    if (mounted) context.pushReplacement('/reward/${exercise.id}');
  }

  Future<void> _showWrongSheet(ExerciseModel exercise) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        var hintVisible = false;
        return StatefulBuilder(
          builder: (context, setSheetState) => Consumer(
            builder: (context, ref, _) {
              final state = ref.watch(exerciseControllerProvider);
              final hintIndex = state.hintIndex.clamp(
                0,
                exercise.hints.length - 1,
              );
              return SafeArea(
                top: false,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.screen,
                    0,
                    AppSpacing.screen,
                    MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          const ByteAvatar(size: 76, mood: ByteMood.error),
                          const SizedBox(width: AppSpacing.sm),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Почти.', style: AppTypography.h2),
                                Text(
                                  'Byte остановился до нужного действия.',
                                  style: AppTypography.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (hintVisible) ...[
                        const SizedBox(height: AppSpacing.md),
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            border: Border.all(
                              color: AppColors.warning.withValues(alpha: .45),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Подсказка ${hintIndex + 1} из ${exercise.hints.length}',
                                style: AppTypography.label.copyWith(
                                  color: AppColors.warning,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                exercise.hints[hintIndex],
                                style: AppTypography.body,
                              ),
                              if (hintIndex < exercise.hints.length - 1) ...[
                                const SizedBox(height: AppSpacing.xs),
                                TextButton(
                                  onPressed: () {
                                    ref
                                        .read(
                                          exerciseControllerProvider.notifier,
                                        )
                                        .showNextHint(
                                          exercise.hints.length - 1,
                                        );
                                    setSheetState(() {});
                                  },
                                  child: const Text('Ещё подсказка'),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.md),
                      PrimaryButton(
                        label: 'Попробовать ещё',
                        onPressed: () {
                          ref.read(exerciseControllerProvider.notifier).retry();
                          ref.read(liveTraceProvider.notifier).reset();
                          Navigator.pop(context);
                        },
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      if (!hintVisible)
                        SecondaryButton(
                          label: 'Подсказка',
                          icon: AppIcons.lightbulb,
                          onPressed: () =>
                              setSheetState(() => hintVisible = true),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final module = ref.watch(moduleProvider);
    final state = ref.watch(exerciseControllerProvider);
    final trace = ref.watch(liveTraceProvider);
    final progress = ref.watch(progressProvider);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        leadingWidth: 60,
        leading: Padding(
          padding: const EdgeInsets.only(left: AppSpacing.xs),
          child: AppIconButton(
            icon: AppIcons.back,
            label: 'Назад',
            onPressed: context.pop,
          ),
        ),
        title: const Text('Практика', style: AppTypography.label),
        centerTitle: true,
      ),
      body: module.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        error: (error, stackTrace) =>
            const Center(child: Text('Задание не загрузилось.')),
        data: (content) {
          final exercise = content.exerciseById(widget.exerciseId);
          final lesson = content.lessonForExercise(exercise.id);
          final exerciseIndex = lesson.exercises.indexWhere(
            (item) => item.id == exercise.id,
          );
          _ensureInitialized(exercise);
          final canSubmit =
              exercise.type == ExerciseType.reorder || state.selected != null;
          return SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.xs,
                AppSpacing.md,
                AppSpacing.md,
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Text(
                        'Задание ${exerciseIndex + 1} из ${lesson.exercises.length}',
                        style: AppTypography.caption,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadius.xs),
                          child: LinearProgressIndicator(
                            value:
                                (exerciseIndex + 1) / lesson.exercises.length,
                            minHeight: 5,
                            backgroundColor: AppColors.divider,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.lg,
                      ),
                      children: [
                        _MissionConsole(exercise: exercise),
                        const SizedBox(height: AppSpacing.md),
                        Text(exercise.title, style: AppTypography.h1),
                        const SizedBox(height: AppSpacing.xs),
                        Text(exercise.prompt, style: AppTypography.bodySmall),
                        const SizedBox(height: AppSpacing.md),
                        CodeBlock(
                          lines: state.correct
                              ? exercise.resolvedCode
                              : exercise.code,
                          activeLine: trace.step?.activeLine ?? -1,
                          selectedLine: exercise.type == ExerciseType.bugHunt
                              ? int.tryParse(state.selected ?? '')
                              : null,
                          onLineTap: exercise.type == ExerciseType.bugHunt
                              ? (line) {
                                  HapticFeedback.selectionClick();
                                  ref.read(liveTraceProvider.notifier).reset();
                                  ref
                                      .read(exerciseControllerProvider.notifier)
                                      .select('$line');
                                }
                              : null,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        LiveTraceStage(
                          trace: trace,
                          plan: exercise.trace,
                          systemLabel: exercise.systemLabel,
                          level: progress.byteLevel,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        if (exercise.type == ExerciseType.bugHunt)
                          _BugHuntGuide(selected: state.selected != null)
                        else if (exercise.type == ExerciseType.reorder)
                          _ReorderEditor(exercise: exercise, state: state)
                        else
                          _ChoiceEditor(exercise: exercise, state: state),
                      ],
                    ),
                  ),
                  PrimaryButton(
                    label: trace.running ? 'Byte выполняет код…' : 'Запустить',
                    icon: AppIcons.play,
                    loading: trace.running,
                    onPressed: canSubmit && !trace.running
                        ? () => _submit(exercise, content)
                        : null,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MissionConsole extends StatelessWidget {
  const _MissionConsole({required this.exercise});
  final ExerciseModel exercise;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(
      AppSpacing.sm,
      AppSpacing.xs,
      AppSpacing.md,
      AppSpacing.xs,
    ),
    decoration: BoxDecoration(
      color: AppColors.surfaceInteractive,
      borderRadius: BorderRadius.circular(AppRadius.md),
      border: Border.all(color: AppColors.primary.withValues(alpha: .45)),
    ),
    child: Row(
      children: [
        ByteAvatar(
          size: 70,
          mood: switch (exercise.type) {
            ExerciseType.bugHunt => ByteMood.thinking,
            ExerciseType.reorder => ByteMood.moving,
            ExerciseType.finalMission => ByteMood.charging,
            _ => ByteMood.explaining,
          },
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                exercise.systemLabel.toUpperCase(),
                style: AppTypography.caption.copyWith(
                  color: AppColors.primary,
                  letterSpacing: .8,
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(exercise.missionBrief, style: AppTypography.bodySmall),
            ],
          ),
        ),
      ],
    ),
  );
}

class _BugHuntGuide extends StatelessWidget {
  const _BugHuntGuide({required this.selected});
  final bool selected;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.sm),
    decoration: BoxDecoration(
      color: selected
          ? AppColors.primary.withValues(alpha: .10)
          : AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.md),
      border: Border.all(
        color: selected ? AppColors.primary : AppColors.divider,
      ),
    ),
    child: Row(
      children: [
        AppIcon(
          selected ? AppIcons.check : AppIcons.info,
          size: 16,
          color: selected ? AppColors.success : AppColors.primary,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            selected
                ? 'Строка отмечена. Запусти диагностику.'
                : 'Найди сбой: нажми прямо на ошибочную строку кода.',
            style: AppTypography.bodySmall,
          ),
        ),
      ],
    ),
  );
}

class _ChoiceEditor extends ConsumerWidget {
  const _ChoiceEditor({required this.exercise, required this.state});
  final ExerciseModel exercise;
  final ExerciseState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Column(
    children: [
      for (final option in exercise.options)
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
          child: Pressable(
            onTap: () {
              HapticFeedback.selectionClick();
              ref.read(liveTraceProvider.notifier).reset();
              ref.read(exerciseControllerProvider.notifier).select(option);
            },
            child: AnimatedContainer(
              duration: AppMotion.state,
              constraints: const BoxConstraints(minHeight: 56),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: state.selected == option
                    ? AppColors.surfaceInteractive
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: state.selected == option
                      ? AppColors.primary
                      : AppColors.divider,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: state.selected == option
                            ? AppColors.primary
                            : AppColors.textMuted,
                        width: 2,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: state.selected == option
                        ? Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primary,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: Text(option, style: AppTypography.body)),
                ],
              ),
            ),
          ),
        ),
    ],
  );
}

class _ReorderEditor extends ConsumerWidget {
  const _ReorderEditor({required this.exercise, required this.state});
  final ExerciseModel exercise;
  final ExerciseState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordered = state.ordered.isEmpty ? exercise.options : state.ordered;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ПОРЯДОК БЛОКОВ',
          style: AppTypography.label.copyWith(color: AppColors.textMuted),
        ),
        const SizedBox(height: AppSpacing.xs),
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          buildDefaultDragHandles: false,
          proxyDecorator: (child, index, animation) => ScaleTransition(
            scale: Tween(begin: 1.0, end: 1.03).animate(animation),
            child: Material(
              color: Colors.transparent,
              elevation: 4,
              child: child,
            ),
          ),
          itemCount: ordered.length,
          onReorder: (oldIndex, newIndex) {
            HapticFeedback.selectionClick();
            ref.read(liveTraceProvider.notifier).reset();
            ref
                .read(exerciseControllerProvider.notifier)
                .reorder(oldIndex, newIndex);
          },
          itemBuilder: (context, index) => Container(
            key: ValueKey('${ordered[index]}-$index'),
            margin: const EdgeInsets.only(bottom: AppSpacing.xs),
            constraints: const BoxConstraints(minHeight: 52),
            padding: const EdgeInsets.only(left: AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surfaceInteractive,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.divider),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(ordered[index], style: AppTypography.code),
                ),
                AppIconButton(
                  icon: AppIcons.up,
                  label: 'Переместить выше',
                  onPressed: index == 0
                      ? null
                      : () {
                          ref.read(liveTraceProvider.notifier).reset();
                          ref
                              .read(exerciseControllerProvider.notifier)
                              .move(index, -1);
                        },
                ),
                AppIconButton(
                  icon: AppIcons.down,
                  label: 'Переместить ниже',
                  onPressed: index == ordered.length - 1
                      ? null
                      : () {
                          ref.read(liveTraceProvider.notifier).reset();
                          ref
                              .read(exerciseControllerProvider.notifier)
                              .move(index, 1);
                        },
                ),
                ReorderableDragStartListener(
                  index: index,
                  child: const SizedBox(
                    width: 44,
                    height: 44,
                    child: Center(
                      child: AppIcon(
                        AppIcons.grip,
                        size: 17,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
