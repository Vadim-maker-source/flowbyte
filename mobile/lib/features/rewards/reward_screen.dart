import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
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
import '../progress/progress_controller.dart';

class RewardScreen extends ConsumerWidget {
  const RewardScreen({super.key, required this.exerciseId});
  final String exerciseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final module = ref.watch(moduleProvider);
    final progress = ref.watch(progressProvider);
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(
            child: ExcludeSemantics(
              child: CustomPaint(painter: _RewardBackdrop()),
            ),
          ),
          SafeArea(
            child: module.when(
              loading: () => const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              error: (error, stackTrace) => const Center(
                child: Text('Результат сохранён на устройстве.'),
              ),
              data: (content) {
                final exercise = content.exerciseById(exerciseId);
                final finalMission = exerciseId == content.finalMission.id;
                final nextExercise = finalMission
                    ? null
                    : content.nextExercise(exerciseId);
                final chain = progress.completedExercises.length;
                return Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screen,
                    AppSpacing.sm,
                    AppSpacing.screen,
                    AppSpacing.md,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                finalMission
                                    ? 'СТАНЦИЯ СПАСЕНА'
                                    : 'МИССИЯ ВЫПОЛНЕНА',
                                textAlign: TextAlign.center,
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.primary,
                                  letterSpacing: 2,
                                ),
                              ),
                              ByteAvatar(
                                size: 210,
                                level: progress.byteLevel,
                                mood: finalMission
                                    ? ByteMood.trophy
                                    : ByteMood.success,
                              ),
                              const Text(
                                'Система отвечает!',
                                textAlign: TextAlign.center,
                                style: AppTypography.display,
                              ),
                              const SizedBox(height: AppSpacing.xxs),
                              TweenAnimationBuilder<int>(
                                duration: AppMotion.reward,
                                tween: IntTween(
                                  begin: 0,
                                  end: exercise.xpReward,
                                ),
                                builder: (context, value, _) => Text(
                                  '+$value XP',
                                  textAlign: TextAlign.center,
                                  style: AppTypography.display.copyWith(
                                    color: AppColors.success,
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              _MissionResult(
                                systemLabel: exercise.systemLabel,
                                message: exercise.successMessage,
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              _LevelProgress(
                                level: progress.byteLevel,
                                xp: progress.xp,
                                value: progress.levelProgress,
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Row(
                                children: [
                                  Expanded(
                                    child: _RewardStat(
                                      icon: AppIcons.bolt,
                                      label: 'Цепочка',
                                      value: '$chain задач',
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.xs),
                                  const Expanded(
                                    child: _RewardStat(
                                      icon: AppIcons.trophy,
                                      label: 'Система',
                                      value: 'в сети',
                                    ),
                                  ),
                                ],
                              ),
                              if (nextExercise != null) ...[
                                const SizedBox(height: AppSpacing.sm),
                                _NextMissionPreview(exercise: nextExercise),
                              ],
                              const SizedBox(height: AppSpacing.md),
                            ],
                          ),
                        ),
                      ),
                      PrimaryButton(
                        label: finalMission
                            ? 'Завершить модуль'
                            : nextExercise != null
                            ? 'Следующая миссия'
                            : 'На карту миссий',
                        icon: finalMission ? AppIcons.flag : AppIcons.next,
                        onPressed: () => context.go(
                          finalMission
                              ? '/complete'
                              : nextExercise != null
                              ? '/exercise/${nextExercise.id}'
                              : '/home',
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _NextMissionPreview extends StatelessWidget {
  const _NextMissionPreview({required this.exercise});
  final ExerciseModel exercise;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.sm),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.md),
      border: Border.all(color: AppColors.primary.withValues(alpha: .32)),
    ),
    child: Row(
      children: [
        const ByteAvatar(size: 74, mood: ByteMood.explaining),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'СЛЕДУЮЩАЯ ЦЕЛЬ',
                style: AppTypography.caption.copyWith(
                  color: AppColors.primary,
                  letterSpacing: .8,
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(exercise.title, style: AppTypography.label),
              Text(
                exercise.missionBrief,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.caption,
              ),
            ],
          ),
        ),
        const AppIcon(AppIcons.next, size: 14, color: AppColors.textMuted),
      ],
    ),
  );
}

class _MissionResult extends StatelessWidget {
  const _MissionResult({required this.systemLabel, required this.message});
  final String systemLabel;
  final String message;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: AppColors.surfaceInteractive,
      borderRadius: BorderRadius.circular(AppRadius.md),
      border: Border.all(color: AppColors.success.withValues(alpha: .55)),
      boxShadow: [
        BoxShadow(
          color: AppColors.success.withValues(alpha: .08),
          blurRadius: 20,
        ),
      ],
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.success,
          ),
          child: const AppIcon(
            AppIcons.check,
            size: 14,
            color: AppColors.background,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$systemLabel · В НОРМЕ',
                style: AppTypography.caption.copyWith(
                  color: AppColors.success,
                  letterSpacing: .7,
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(message, style: AppTypography.bodySmall),
            ],
          ),
        ),
      ],
    ),
  );
}

class _LevelProgress extends StatelessWidget {
  const _LevelProgress({
    required this.level,
    required this.xp,
    required this.value,
  });
  final int level;
  final int xp;
  final double value;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.md),
      border: Border.all(color: AppColors.divider),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Byte · уровень $level',
              style: AppTypography.label.copyWith(color: AppColors.textPrimary),
            ),
            const Spacer(),
            Text('$xp XP', style: AppTypography.caption),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.xs),
          child: LinearProgressIndicator(
            value: value,
            minHeight: 7,
            backgroundColor: AppColors.divider,
            color: AppColors.success,
          ),
        ),
      ],
    ),
  );
}

class _RewardStat extends StatelessWidget {
  const _RewardStat({
    required this.icon,
    required this.label,
    required this.value,
  });
  final FaIconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.sm),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.md),
      border: Border.all(color: AppColors.divider),
    ),
    child: Row(
      children: [
        AppIcon(icon, size: 17, color: AppColors.primary),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTypography.caption),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.label.copyWith(color: AppColors.success),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _RewardBackdrop extends CustomPainter {
  const _RewardBackdrop();

  @override
  void paint(Canvas canvas, Size size) {
    final glow = Paint()
      ..shader =
          RadialGradient(
            colors: [
              AppColors.primary.withValues(alpha: .16),
              AppColors.background.withValues(alpha: 0),
            ],
          ).createShader(
            Rect.fromCircle(
              center: Offset(size.width / 2, size.height * .18),
              radius: size.width * .62,
            ),
          );
    canvas.drawRect(Offset.zero & size, glow);

    final colors = [AppColors.primary, AppColors.success, AppColors.warning];
    for (var i = 0; i < 18; i++) {
      final x = ((i * 73) % 101) / 101 * size.width;
      final y = 36 + ((i * 47) % 210).toDouble();
      final paint = Paint()
        ..color = colors[i % colors.length].withValues(alpha: .72);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(i * math.pi / 7);
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: 7, height: 4),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
