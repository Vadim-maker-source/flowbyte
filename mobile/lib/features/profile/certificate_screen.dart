import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../data/repositories/content_repository.dart';
import '../../shared/widgets/app_buttons.dart';
import '../../shared/widgets/byte_avatar.dart';
import '../progress/progress_controller.dart';

class CertificateScreen extends ConsumerWidget {
  const CertificateScreen({super.key, required this.moduleId});
  final String moduleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final course = ref.watch(moduleProvider);
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
        title: const Text('Награда', style: AppTypography.label),
        centerTitle: true,
      ),
      body: SafeArea(
        top: false,
        child: course.when(
          loading: () =>
              const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          error: (_, _) =>
              const Center(child: Text('Сертификат не загрузился.')),
          data: (content) {
            final module = content.moduleById(moduleId);
            final complete = progress.moduleCompleted(
              module.lessonIds,
              requiresFinal: module.id == 'loops',
            );
            if (!complete) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.screen),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const ByteAvatar(size: 150, mood: ByteMood.thinking),
                      const Text(
                        'Сертификат пока закрыт',
                        style: AppTypography.h1,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Заверши модуль «${module.title}», чтобы Byte выдал награду.',
                        textAlign: TextAlign.center,
                        style: AppTypography.bodySmall,
                      ),
                    ],
                  ),
                ),
              );
            }
            final shortId = progress.installationId.isEmpty
                ? 'LOCAL'
                : progress.installationId.substring(0, 8).toUpperCase();
            return ListView(
              padding: const EdgeInsets.all(AppSpacing.screen),
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(color: AppColors.warning, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.warning.withValues(alpha: .10),
                        blurRadius: 28,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const ByteAvatar(size: 170, mood: ByteMood.trophy),
                      Text(
                        'СЕРТИФИКАТ FLOWBYTE',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.warning,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      const Text(
                        'Курсант Byte',
                        textAlign: TextAlign.center,
                        style: AppTypography.display,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      const Text(
                        'успешно завершил игровой модуль',
                        textAlign: TextAlign.center,
                        style: AppTypography.bodySmall,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        module.certificateTitle,
                        textAlign: TextAlign.center,
                        style: AppTypography.h1.copyWith(
                          color: AppColors.secondaryAccent,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Container(height: 1, color: AppColors.divider),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        '4 урока · 12 практик · Python',
                        style: AppTypography.label,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        '№ FB-$shortId-${module.order}',
                        style: AppTypography.caption,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                const Text(
                  'Это игровая награда за прохождение модуля и не является официальным документом об образовании.',
                  textAlign: TextAlign.center,
                  style: AppTypography.caption,
                ),
                const SizedBox(height: AppSpacing.lg),
                PrimaryButton(
                  label: 'Вернуться в профиль',
                  icon: AppIcons.profile,
                  onPressed: () => context.go('/profile'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
