import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/module_models.dart';
import '../../data/repositories/content_repository.dart';
import '../../shared/widgets/app_buttons.dart';
import '../../shared/widgets/code_block.dart';
import '../../shared/widgets/live_trace_stage.dart';
import '../exercises/exercise_controller.dart';
import '../live_trace/live_trace_controller.dart';
import '../progress/progress_controller.dart';

class FinalMissionScreen extends ConsumerStatefulWidget {
  const FinalMissionScreen({super.key});

  @override
  ConsumerState<FinalMissionScreen> createState() => _FinalMissionScreenState();
}

class _FinalMissionScreenState extends ConsumerState<FinalMissionScreen> {
  var _initialized = false;

  Future<void> _run(ExerciseModel mission) async {
    final correct = ref
        .read(exerciseControllerProvider.notifier)
        .submit(mission);
    final exercise = ref.read(exerciseControllerProvider);
    await ref
        .read(progressProvider.notifier)
        .recordAttempt(
          mission.id,
          correct: correct,
          hintsUsed: exercise.hintIndex,
        );
    if (!mounted) return;
    if (!correct) {
      await _showStoppedSheet(mission);
      return;
    }
    await ref.read(liveTraceProvider.notifier).play(mission.trace);
    if (!mounted) return;
    HapticFeedback.mediumImpact();
    await ref.read(progressProvider.notifier).completeFinal(mission.xpReward);
    if (mounted) context.go('/reward/${mission.id}');
  }

  Future<void> _showStoppedSheet(ExerciseModel mission) async {
    final state = ref.read(exerciseControllerProvider);
    final hint =
        mission.hints[state.hintIndex.clamp(0, mission.hints.length - 1)];
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screen,
          0,
          AppSpacing.screen,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Byte остановился здесь.', style: AppTypography.h2),
            const SizedBox(height: AppSpacing.xs),
            const Text(
              'Посмотри, что произойдёт на второй итерации.',
              style: AppTypography.bodySmall,
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.divider),
              ),
              child: Row(
                children: [
                  const AppIcon(
                    AppIcons.lightbulb,
                    size: 17,
                    color: AppColors.warning,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: Text(hint, style: AppTypography.bodySmall)),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            PrimaryButton(
              label: 'Исправить программу',
              onPressed: () {
                ref.read(exerciseControllerProvider.notifier).retry();
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: AppSpacing.xs),
            SecondaryButton(
              label: 'Посмотреть выполнение ещё раз',
              icon: AppIcons.rotate,
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final module = ref.watch(moduleProvider);
    final exercise = ref.watch(exerciseControllerProvider);
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
        title: const Text('Финальная миссия', style: AppTypography.label),
        centerTitle: true,
      ),
      body: module.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        error: (error, stackTrace) =>
            const Center(child: Text('Миссия не загрузилась.')),
        data: (content) {
          final mission = content.finalMission;
          if (!_initialized) {
            _initialized = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                ref
                    .read(exerciseControllerProvider.notifier)
                    .initialize(mission);
              }
            });
          }
          final ordered = exercise.ordered.isEmpty
              ? mission.options
              : exercise.ordered;
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
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      children: [
                        const Text(
                          'Запрограммируй маршрут',
                          style: AppTypography.h1,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(mission.prompt, style: AppTypography.bodySmall),
                        const SizedBox(height: AppSpacing.md),
                        LiveTraceStage(
                          trace: trace,
                          plan: mission.trace,
                          systemLabel: mission.systemLabel,
                          level: progress.byteLevel,
                          finalMission: true,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        CodeBlock(
                          lines: mission.code,
                          activeLine: trace.step?.activeLine ?? -1,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'ТВОЯ ПРОГРАММА',
                          style: AppTypography.label.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        ReorderableListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          buildDefaultDragHandles: false,
                          itemCount: ordered.length,
                          onReorder: (oldIndex, newIndex) {
                            HapticFeedback.selectionClick();
                            ref
                                .read(exerciseControllerProvider.notifier)
                                .reorder(oldIndex, newIndex);
                          },
                          proxyDecorator: (child, index, animation) => Material(
                            elevation: 5,
                            color: Colors.transparent,
                            child: child,
                          ),
                          itemBuilder: (context, index) => Container(
                            key: ValueKey('${ordered[index]}-$index'),
                            margin: const EdgeInsets.only(
                              bottom: AppSpacing.xs,
                            ),
                            padding: const EdgeInsets.only(left: AppSpacing.md),
                            constraints: const BoxConstraints(minHeight: 50),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceInteractive,
                              borderRadius: BorderRadius.circular(AppRadius.md),
                              border: Border.all(color: AppColors.divider),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    ordered[index],
                                    style: AppTypography.code,
                                  ),
                                ),
                                AppIconButton(
                                  icon: AppIcons.up,
                                  label: 'Выше',
                                  onPressed: index == 0
                                      ? null
                                      : () => ref
                                            .read(
                                              exerciseControllerProvider
                                                  .notifier,
                                            )
                                            .move(index, -1),
                                ),
                                AppIconButton(
                                  icon: AppIcons.down,
                                  label: 'Ниже',
                                  onPressed: index == ordered.length - 1
                                      ? null
                                      : () => ref
                                            .read(
                                              exerciseControllerProvider
                                                  .notifier,
                                            )
                                            .move(index, 1),
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
                    ),
                  ),
                  PrimaryButton(
                    label: trace.running
                        ? 'Автопилот работает…'
                        : 'Запустить автопилот',
                    icon: AppIcons.play,
                    loading: trace.running,
                    onPressed: trace.running ? null : () => _run(mission),
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
