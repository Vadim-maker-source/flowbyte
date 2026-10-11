import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/widgets/app_buttons.dart';
import '../../shared/widgets/byte_avatar.dart';
import '../../shared/widgets/code_block.dart';
import '../progress/progress_controller.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  var _page = 0;

  Future<void> _finish() async {
    await ref.read(progressProvider.notifier).completeOnboarding();
    if (mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.screen),
        child: Column(
          children: [
            Row(
              children: [
                Text('Знакомство · ${_page + 1}/2', style: AppTypography.label),
                const Spacer(),
                TextButton(onPressed: _finish, child: const Text('Пропустить')),
              ],
            ),
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (value) => setState(() => _page = value),
                children: const [
                  _OnboardingPage(
                    title: 'Код влияет на Byte сразу',
                    copy:
                        'Запусти решение и увидишь, какую строку выполняет программа и куда движется Byte.',
                    child: Column(
                      children: [
                        CodeBlock(
                          lines: [
                            'if energy > 20:',
                            '    move()',
                            'else:',
                            '    charge()',
                          ],
                          activeLine: 3,
                        ),
                        SizedBox(height: AppSpacing.lg),
                        ByteAvatar(size: 126, mood: ByteMood.charging),
                      ],
                    ),
                  ),
                  _OnboardingPage(
                    title: 'Два модуля · восемь миссий',
                    copy:
                        'Сначала решения, затем автоматизация. В каждом уроке — понятная теория и три практики. Прогресс сохраняется без сети.',
                    child: _RoutePreview(),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                2,
                (index) => AnimatedContainer(
                  duration: AppMotion.state,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: _page == index ? 22 : 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: _page == index
                        ? AppColors.primary
                        : AppColors.divider,
                    borderRadius: BorderRadius.circular(AppRadius.xs),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            PrimaryButton(
              label: _page == 0 ? 'Дальше' : 'К карте миссий',
              onPressed: () => _page == 0
                  ? _controller.nextPage(
                      duration: AppMotion.page,
                      curve: Curves.easeOutCubic,
                    )
                  : _finish(),
            ),
          ],
        ),
      ),
    ),
  );
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({
    required this.title,
    required this.copy,
    required this.child,
  });
  final String title;
  final String copy;
  final Widget child;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.only(top: AppSpacing.xl),
    children: [
      Text(title, style: AppTypography.h1),
      const SizedBox(height: AppSpacing.sm),
      Text(copy, style: AppTypography.bodySmall),
      const SizedBox(height: AppSpacing.xl),
      child,
    ],
  );
}

class _RoutePreview extends StatelessWidget {
  const _RoutePreview();
  @override
  Widget build(BuildContext context) => Column(
    children: const [
      _PreviewRow(label: 'Модуль 1 · Условия', active: true),
      _PreviewRow(label: 'if · else · elif · and/or'),
      _PreviewRow(label: 'Модуль 2 · Циклы'),
      _PreviewRow(label: 'for · while · break/continue'),
    ],
  );
}

class _PreviewRow extends StatelessWidget {
  const _PreviewRow({required this.label, this.active = false});
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: active ? AppColors.surfaceInteractive : AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.md),
      border: Border.all(color: active ? AppColors.primary : AppColors.divider),
    ),
    child: Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active ? AppColors.primary : AppColors.textMuted,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(label, style: AppTypography.title),
      ],
    ),
  );
}
