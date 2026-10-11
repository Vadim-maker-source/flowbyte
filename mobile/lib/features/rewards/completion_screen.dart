import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/widgets/app_buttons.dart';
import '../../shared/widgets/byte_avatar.dart';
import '../progress/progress_controller.dart';

class CompletionScreen extends ConsumerWidget {
  const CompletionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(progressProvider);
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.screen),
          children: [
            const SizedBox(
              height: 190,
              child: Center(
                child: ByteAvatar(size: 178, level: 8, mood: ByteMood.trophy),
              ),
            ),
            const Text(
              'Курс пройден',
              textAlign: TextAlign.center,
              style: AppTypography.display,
            ),
            const SizedBox(height: AppSpacing.xs),
            const Text(
              'Ты научил Byte принимать решения, повторять действия и собирать из них настоящий алгоритм на Python.',
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall,
            ),
            const SizedBox(height: AppSpacing.lg),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: AppColors.success),
              ),
              child: const Column(
                children: [
                  _ResultRow(label: 'Условия: if, elif и else'),
                  _ResultRow(label: 'Сравнения: ==, !=, > и <'),
                  _ResultRow(label: 'Логика: and, or и not'),
                  _ResultRow(label: 'Циклы: for, range и while'),
                  _ResultRow(label: 'Управление: break и continue'),
                  _ResultRow(
                    label: '8 уроков · 32 практики · финальная миссия',
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              '${progress.xp} XP · Byte уровень ${progress.byteLevel}',
              textAlign: TextAlign.center,
              style: AppTypography.label.copyWith(
                color: AppColors.secondaryAccent,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            PrimaryButton(
              label: 'Открыть сертификаты',
              icon: AppIcons.certificate,
              onPressed: () => context.go('/profile'),
            ),
            const SizedBox(height: AppSpacing.xs),
            SecondaryButton(
              label: 'На карту миссий',
              icon: AppIcons.map,
              onPressed: () => context.go('/home'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
    child: Row(
      children: [
        const AppIcon(AppIcons.check, size: 15, color: AppColors.success),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    ),
  );
}
