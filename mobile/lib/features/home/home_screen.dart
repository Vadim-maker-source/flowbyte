import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/module_models.dart';
import '../../data/repositories/content_repository.dart';
import '../../shared/widgets/app_buttons.dart';
import '../../shared/widgets/byte_avatar.dart';
import '../../shared/widgets/pressable.dart';
import '../progress/progress_controller.dart';
import '../progress/progress_state.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  void _continue(
    BuildContext context,
    ProgressState progress,
    ModuleModel content,
  ) {
    if (progress.completedLessons.length >= content.lessons.length) {
      context.push(progress.finalComplete ? '/complete' : '/final');
    } else {
      context.push('/lesson/lesson-${progress.nextLessonNumber}');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final module = ref.watch(moduleProvider);
    final progress = ref.watch(progressProvider);
    final compact = MediaQuery.sizeOf(context).height < 720;
    return Scaffold(
      body: SafeArea(
        child: module.when(
          loading: () => const _LocalLoading(),
          error: (error, stackTrace) => const _LocalContentError(),
          data: (content) => CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _MissionHero(
                  progress: progress,
                  height: compact ? 166 : 190,
                  onSettings: () => _showControlSheet(context, ref),
                  onDemo: () => _showDemoSheet(context, ref),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screen,
                  AppSpacing.md,
                  AppSpacing.screen,
                  AppSpacing.lg,
                ),
                sliver: SliverList.list(
                  children: [
                    Text(
                      'PYTHON · УПРАВЛЕНИЕ ПОТОКОМ',
                      style: AppTypography.h1,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(content.description, style: AppTypography.bodySmall),
                    const SizedBox(height: AppSpacing.lg),
                    for (final courseModule in content.modules) ...[
                      Text(
                        'МОДУЛЬ ${courseModule.order}',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.primary,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(courseModule.title, style: AppTypography.h2),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        courseModule.description,
                        style: AppTypography.caption,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _ModuleProgress(
                        completed: courseModule.lessonIds
                            .where(progress.completedLessons.contains)
                            .length,
                        total: courseModule.lessonIds.length,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      for (final lesson in content.lessonsForModule(
                        courseModule.id,
                      ))
                        _LessonRouteTile(
                          lesson: lesson,
                          complete: progress.completedLessons.contains(
                            lesson.id,
                          ),
                          unlocked: progress.lessonUnlocked(lesson.order),
                          active:
                              lesson.order == progress.nextLessonNumber &&
                              progress.completedLessons.length <
                                  content.lessons.length,
                          last:
                              lesson.moduleLessonOrder ==
                              courseModule.lessonIds.length,
                          extent: compact ? 58 : 72,
                          onTap: () => context.push('/lesson/${lesson.id}'),
                        ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    if (progress.completedLessons.length ==
                        content.lessons.length) ...[
                      const SizedBox(height: AppSpacing.xs),
                      _FinalMissionPanel(
                        complete: progress.finalComplete,
                        onTap: () => context.push(
                          progress.finalComplete ? '/complete' : '/final',
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _BottomConsole(
        progress: progress,
        onContinue: () => module.value == null
            ? null
            : _continue(context, progress, module.value!),
        onTasks: () => module.value == null
            ? null
            : _continue(context, progress, module.value!),
        onAssistant: () => context.go('/assistant'),
        onAchievements: () => _showAchievementsSheet(context, progress),
        onProfile: () => context.go('/profile'),
      ),
    );
  }

  Future<void> _showControlSheet(BuildContext context, WidgetRef ref) async {
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
            const Text('Центр управления', style: AppTypography.h2),
            const SizedBox(height: AppSpacing.xs),
            const Text(
              'Обучение и прогресс работают локально.',
              style: AppTypography.bodySmall,
            ),
            const SizedBox(height: AppSpacing.md),
            SecondaryButton(
              label: 'Помощник Byte',
              icon: AppIcons.assistant,
              onPressed: () {
                Navigator.of(context).pop();
                context.push('/assistant');
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAchievementsSheet(
    BuildContext context,
    ProgressState progress,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => _InfoSheet(
        icon: AppIcons.trophy,
        title: 'Достижения',
        lines: [
          '${progress.completedLessons.length} из 8 уроков завершено',
          '${progress.xp} XP получено',
          'Byte достиг уровня ${progress.byteLevel}',
        ],
      ),
    );
  }

  Future<void> _showDemoSheet(BuildContext context, WidgetRef ref) async {
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
        child: Consumer(
          builder: (context, ref, _) {
            final progress = ref.watch(progressProvider);
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Demo helper', style: AppTypography.h2),
                const SizedBox(height: AppSpacing.md),
                SecondaryButton(
                  label: 'Открыть следующий урок',
                  onPressed: () =>
                      ref.read(progressProvider.notifier).unlockNext(),
                ),
                const SizedBox(height: AppSpacing.xs),
                SecondaryButton(
                  label: 'Установить 240 XP',
                  onPressed: () =>
                      ref.read(progressProvider.notifier).setXp(240),
                ),
                const SizedBox(height: AppSpacing.xs),
                SwitchListTile.adaptive(
                  value: progress.backendOffline,
                  onChanged: (value) => ref
                      .read(progressProvider.notifier)
                      .setBackendOffline(value),
                  title: const Text('Backend offline'),
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: AppSpacing.xs),
                SecondaryButton(
                  label: 'Сбросить прогресс',
                  icon: AppIcons.rotate,
                  onPressed: () => ref.read(progressProvider.notifier).reset(),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _MissionHero extends StatelessWidget {
  const _MissionHero({
    required this.progress,
    required this.height,
    required this.onSettings,
    required this.onDemo,
  });

  final ProgressState progress;
  final double height;
  final VoidCallback onSettings;
  final VoidCallback onDemo;

  @override
  Widget build(BuildContext context) => Container(
    height: height,
    decoration: const BoxDecoration(
      color: AppColors.surface,
      border: Border(bottom: BorderSide(color: AppColors.divider)),
    ),
    child: CustomPaint(
      painter: const _MissionBackdropPainter(),
      child: Stack(
        children: [
          Positioned(
            left: AppSpacing.screen,
            top: AppSpacing.sm,
            child: GestureDetector(
              onLongPress: onDemo,
              child: Text(
                'FLOWBYTE',
                style: AppTypography.label.copyWith(
                  color: AppColors.textPrimary,
                  letterSpacing: 2.1,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          Positioned(
            right: AppSpacing.xs,
            top: AppSpacing.xxs,
            child: AppIconButton(
              icon: AppIcons.settings,
              label: 'Центр управления',
              onPressed: onSettings,
              color: AppColors.textSecondary,
            ),
          ),
          Positioned(
            left: AppSpacing.xxs,
            bottom: -5,
            child: GestureDetector(
              onLongPress: onDemo,
              child: ByteAvatar(
                size: height > 170 ? 132 : 114,
                level: progress.byteLevel,
              ),
            ),
          ),
          Positioned(
            left: height > 170 ? 166 : 150,
            right: AppSpacing.screen,
            top: height > 170 ? 68 : 57,
            child: _XpConsole(progress: progress),
          ),
        ],
      ),
    ),
  );
}

class _XpConsole extends StatelessWidget {
  const _XpConsole({required this.progress});
  final ProgressState progress;

  @override
  Widget build(BuildContext context) {
    final target = progress.byteLevel * 100;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'LEVEL ${progress.byteLevel}',
          style: AppTypography.caption.copyWith(
            color: AppColors.textSecondary,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text('${progress.xp} XP', style: AppTypography.h1),
        const SizedBox(height: AppSpacing.xs),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.xs),
          child: LinearProgressIndicator(
            value: progress.levelProgress,
            minHeight: 7,
            backgroundColor: AppColors.divider,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          '${progress.xp} / $target',
          style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _MissionBackdropPainter extends CustomPainter {
  const _MissionBackdropPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = AppColors.primary.withValues(alpha: .09)
      ..strokeWidth = .7;
    for (double x = 12; x < size.width; x += 24) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (double y = 10; y < size.height; y += 24) {
      canvas.drawLine(Offset.zero.translate(0, y), Offset(size.width, y), grid);
    }

    final orbit = Paint()
      ..color = AppColors.primary.withValues(alpha: .55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final rect = Rect.fromCircle(
      center: Offset(size.width * .08, size.height * 1.22),
      radius: size.width * .91,
    );
    canvas.drawArc(rect, math.pi * 1.08, math.pi * .83, false, orbit);
    canvas.drawCircle(
      Offset(size.width * .72, size.height * .48),
      5,
      Paint()..color = AppColors.primary,
    );

    final stars = Paint()..color = AppColors.primary.withValues(alpha: .62);
    const points = [
      Offset(.08, .52),
      Offset(.17, .32),
      Offset(.34, .24),
      Offset(.44, .60),
      Offset(.61, .18),
      Offset(.81, .30),
      Offset(.92, .68),
    ];
    for (final point in points) {
      canvas.drawCircle(
        Offset(size.width * point.dx, size.height * point.dy),
        1.2,
        stars,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ModuleProgress extends StatelessWidget {
  const _ModuleProgress({required this.completed, required this.total});
  final int completed;
  final int total;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        '$completed из $total уроков',
        style: AppTypography.label.copyWith(color: AppColors.textPrimary),
      ),
      const SizedBox(height: AppSpacing.xs),
      Row(
        children: List.generate(
          total,
          (index) => Expanded(
            child: Container(
              margin: EdgeInsets.only(
                right: index == total - 1 ? 0 : AppSpacing.xxs,
              ),
              height: 7,
              decoration: BoxDecoration(
                color: index < completed
                    ? AppColors.primary
                    : AppColors.divider,
                borderRadius: BorderRadius.circular(AppRadius.xs),
              ),
            ),
          ),
        ),
      ),
    ],
  );
}

class _LessonRouteTile extends StatelessWidget {
  const _LessonRouteTile({
    required this.lesson,
    required this.complete,
    required this.unlocked,
    required this.active,
    required this.last,
    required this.extent,
    required this.onTap,
  });

  final LessonModel lesson;
  final bool complete;
  final bool unlocked;
  final bool active;
  final bool last;
  final double extent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: extent,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: 14,
          child: Column(
            children: [
              const SizedBox(height: 21),
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: complete || active
                      ? AppColors.primary
                      : AppColors.textMuted,
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                ),
              ),
              if (!last)
                Expanded(
                  child: Container(
                    width: 2,
                    color: complete
                        ? AppColors.success.withValues(alpha: .65)
                        : AppColors.divider,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xxs),
            child: Pressable(
              semanticLabel: unlocked
                  ? 'Урок ${lesson.order}: ${lesson.title}'
                  : 'Урок ${lesson.order} заблокирован',
              onTap: unlocked ? onTap : null,
              child: active
                  ? _ActiveLessonCard(
                      lesson: lesson,
                      complete: complete,
                      unlocked: unlocked,
                    )
                  : _LessonCard(
                      lesson: lesson,
                      complete: complete,
                      unlocked: unlocked,
                    ),
            ),
          ),
        ),
      ],
    ),
  );
}

class _ActiveLessonCard extends StatelessWidget {
  const _ActiveLessonCard({
    required this.lesson,
    required this.complete,
    required this.unlocked,
  });
  final LessonModel lesson;
  final bool complete;
  final bool unlocked;

  @override
  Widget build(BuildContext context) => ClipPath(
    clipper: const CutCornerClipper(cut: 9),
    child: ColoredBox(
      color: AppColors.primary,
      child: Padding(
        padding: const EdgeInsets.all(1),
        child: ClipPath(
          clipper: const CutCornerClipper(cut: 8),
          child: ColoredBox(
            color: AppColors.surfaceInteractive,
            child: _LessonCardContent(
              lesson: lesson,
              complete: complete,
              unlocked: unlocked,
              active: true,
            ),
          ),
        ),
      ),
    ),
  );
}

class _LessonCard extends StatelessWidget {
  const _LessonCard({
    required this.lesson,
    required this.complete,
    required this.unlocked,
  });
  final LessonModel lesson;
  final bool complete;
  final bool unlocked;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      border: Border.all(color: AppColors.divider),
    ),
    child: _LessonCardContent(
      lesson: lesson,
      complete: complete,
      unlocked: unlocked,
      active: false,
    ),
  );
}

class _LessonCardContent extends StatelessWidget {
  const _LessonCardContent({
    required this.lesson,
    required this.complete,
    required this.unlocked,
    required this.active,
  });

  final LessonModel lesson;
  final bool complete;
  final bool unlocked;
  final bool active;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.sm,
      vertical: AppSpacing.xs,
    ),
    child: Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: complete ? AppColors.success : AppColors.surfaceElevated,
            border: Border.all(
              color: active ? AppColors.primary : AppColors.divider,
              width: active ? 2 : 1,
            ),
          ),
          alignment: Alignment.center,
          child: AppIcon(
            complete
                ? AppIcons.check
                : unlocked
                ? AppIcons.play
                : AppIcons.lock,
            size: 12,
            color: complete
                ? AppColors.background
                : active
                ? AppColors.primary
                : AppColors.textMuted,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                lesson.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.label.copyWith(
                  color: unlocked ? AppColors.textPrimary : AppColors.textMuted,
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                '${lesson.exercises.length} задания · ${6 + lesson.order * 2} минут',
                style: AppTypography.caption,
              ),
            ],
          ),
        ),
        AppIcon(
          unlocked ? AppIcons.next : AppIcons.lock,
          size: 14,
          color: active ? AppColors.primary : AppColors.textMuted,
        ),
      ],
    ),
  );
}

class _FinalMissionPanel extends StatelessWidget {
  const _FinalMissionPanel({required this.complete, required this.onTap});
  final bool complete;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SecondaryButton(
    label: complete ? 'Модуль завершён' : 'Открыть финальную миссию',
    icon: complete ? AppIcons.check : AppIcons.flag,
    onPressed: onTap,
  );
}

class _BottomConsole extends StatelessWidget {
  const _BottomConsole({
    required this.progress,
    required this.onContinue,
    required this.onTasks,
    required this.onAssistant,
    required this.onAchievements,
    required this.onProfile,
  });

  final ProgressState progress;
  final VoidCallback onContinue;
  final VoidCallback onTasks;
  final VoidCallback onAssistant;
  final VoidCallback onAchievements;
  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: ColoredBox(
      color: AppColors.background,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screen,
              AppSpacing.xs,
              AppSpacing.screen,
              AppSpacing.sm,
            ),
            child: PrimaryButton(
              label: progress.finalComplete ? 'Результат миссии' : 'Продолжить',
              icon: AppIcons.next,
              onPressed: onContinue,
            ),
          ),
          Container(
            height: 60,
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.divider)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Expanded(
                  child: _NavItem(
                    icon: AppIcons.home,
                    label: 'Главная',
                    active: true,
                    onTap: () => context.go('/home'),
                  ),
                ),
                Expanded(
                  child: _NavItem(
                    icon: AppIcons.tasks,
                    label: 'Задания',
                    onTap: onTasks,
                  ),
                ),
                Expanded(
                  child: _NavItem(
                    icon: AppIcons.assistant,
                    label: 'Byte AI',
                    onTap: onAssistant,
                  ),
                ),
                Expanded(
                  child: _NavItem(
                    icon: AppIcons.trophy,
                    label: 'Достижения',
                    onTap: onAchievements,
                  ),
                ),
                Expanded(
                  child: _NavItem(
                    icon: AppIcons.profile,
                    label: 'Профиль',
                    onTap: onProfile,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
  });

  final FaIconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) => Pressable(
    onTap: onTap,
    child: SizedBox(
      height: 56,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AppIcon(
            icon,
            size: 17,
            color: active ? AppColors.primary : AppColors.textMuted,
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            label,
            maxLines: 1,
            style: AppTypography.caption.copyWith(
              fontSize: 10,
              color: active ? AppColors.primary : AppColors.textMuted,
            ),
          ),
        ],
      ),
    ),
  );
}

class _InfoSheet extends StatelessWidget {
  const _InfoSheet({
    required this.icon,
    required this.title,
    required this.lines,
  });
  final FaIconData icon;
  final String title;
  final List<String> lines;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      AppSpacing.screen,
      0,
      AppSpacing.screen,
      AppSpacing.lg,
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            AppIcon(icon, color: AppColors.primary),
            const SizedBox(width: AppSpacing.sm),
            Text(title, style: AppTypography.h2),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        for (final line in lines)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Row(
              children: [
                const AppIcon(
                  AppIcons.check,
                  size: 13,
                  color: AppColors.success,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(child: Text(line, style: AppTypography.bodySmall)),
              ],
            ),
          ),
      ],
    ),
  );
}

class _LocalLoading extends StatelessWidget {
  const _LocalLoading();
  @override
  Widget build(BuildContext context) => const Center(
    child: SizedBox.square(
      dimension: 24,
      child: CircularProgressIndicator(strokeWidth: 2),
    ),
  );
}

class _LocalContentError extends StatelessWidget {
  const _LocalContentError();
  @override
  Widget build(BuildContext context) => const Center(
    child: Padding(
      padding: EdgeInsets.all(AppSpacing.screen),
      child: Text(
        'Не удалось открыть локальный модуль.',
        style: AppTypography.body,
      ),
    ),
  );
}
