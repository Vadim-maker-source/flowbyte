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
import '../progress/progress_controller.dart';
import '../progress/progress_state.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(progressProvider);
    final course = ref.watch(moduleProvider);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        leadingWidth: 60,
        leading: Padding(
          padding: const EdgeInsets.only(left: AppSpacing.xs),
          child: AppIconButton(
            icon: AppIcons.back,
            label: 'Назад',
            onPressed: () => context.go('/home'),
          ),
        ),
        title: const Text('Профиль', style: AppTypography.label),
        centerTitle: true,
      ),
      body: SafeArea(
        top: false,
        child: course.when(
          loading: () =>
              const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          error: (_, _) =>
              const Center(child: Text('Профиль временно недоступен.')),
          data: (content) => ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screen,
              AppSpacing.md,
              AppSpacing.screen,
              AppSpacing.xl,
            ),
            children: [
              _ProfileHero(progress: progress),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      value: '${progress.xp}',
                      label: 'XP',
                      icon: AppIcons.bolt,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: _StatCard(
                      value: '${progress.completedLessons.length}/8',
                      label: 'уроков',
                      icon: AppIcons.book,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: _StatCard(
                      value: '${progress.completedExercises.length}',
                      label: 'практик',
                      icon: AppIcons.tasks,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'СЕРТИФИКАТЫ МОДУЛЕЙ',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textMuted,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              for (final courseModule in content.modules)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: _CertificateTile(
                    module: courseModule,
                    complete: progress.moduleCompleted(
                      courseModule.lessonIds,
                      requiresFinal: courseModule.id == 'loops',
                    ),
                    onTap: () =>
                        context.push('/certificate/${courseModule.id}'),
                  ),
                ),
              const SizedBox(height: AppSpacing.md),
              SecondaryButton(
                label: 'Спросить помощника Byte',
                icon: AppIcons.assistant,
                onPressed: () => context.push('/assistant'),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Профиль локальный: регистрация и персональные данные не нужны. Сертификаты подтверждают прохождение игровых модулей FLOWBYTE и не являются документами об образовании.',
                style: AppTypography.caption,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({required this.progress});
  final ProgressState progress;

  @override
  Widget build(BuildContext context) {
    final shortId = progress.installationId.isEmpty
        ? 'LOCAL'
        : progress.installationId.substring(0, 8).toUpperCase();
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceInteractive,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.primary.withValues(alpha: .45)),
      ),
      child: Row(
        children: [
          ByteAvatar(
            size: 118,
            level: progress.byteLevel,
            mood: progress.finalComplete ? ByteMood.trophy : ByteMood.idle,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Курсант Byte', style: AppTypography.h2),
                const SizedBox(height: AppSpacing.xxs),
                Text('Локальный ID · $shortId', style: AppTypography.caption),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Уровень ${progress.byteLevel}',
                  style: AppTypography.label.copyWith(
                    color: AppColors.secondaryAccent,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                LinearProgressIndicator(
                  value: progress.levelProgress,
                  minHeight: 6,
                  color: AppColors.primary,
                  backgroundColor: AppColors.divider,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.value,
    required this.label,
    required this.icon,
  });
  final String value;
  final String label;
  final FaIconData icon;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.xs,
      vertical: AppSpacing.sm,
    ),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.md),
      border: Border.all(color: AppColors.divider),
    ),
    child: Column(
      children: [
        AppIcon(icon, size: 16, color: AppColors.primary),
        const SizedBox(height: AppSpacing.xxs),
        Text(value, style: AppTypography.h2),
        Text(label, style: AppTypography.caption),
      ],
    ),
  );
}

class _CertificateTile extends StatelessWidget {
  const _CertificateTile({
    required this.module,
    required this.complete,
    required this.onTap,
  });
  final CourseModuleModel module;
  final bool complete;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.md),
      border: Border.all(
        color: complete ? AppColors.success : AppColors.divider,
      ),
    ),
    child: Row(
      children: [
        Container(
          width: 42,
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: complete
                ? AppColors.success.withValues(alpha: .16)
                : AppColors.surfaceInteractive,
          ),
          child: AppIcon(
            complete ? AppIcons.certificate : AppIcons.lock,
            size: 18,
            color: complete ? AppColors.success : AppColors.textMuted,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(module.title, style: AppTypography.label),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                complete
                    ? 'Сертификат открыт'
                    : '${module.lessonIds.length} урока и итоговая проверка',
                style: AppTypography.caption,
              ),
            ],
          ),
        ),
        AppIconButton(
          icon: complete ? AppIcons.next : AppIcons.lock,
          label: complete ? 'Открыть сертификат' : 'Сертификат заблокирован',
          onPressed: complete ? onTap : null,
        ),
      ],
    ),
  );
}
