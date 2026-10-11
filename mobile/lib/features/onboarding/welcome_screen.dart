import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/widgets/app_buttons.dart';
import '../../shared/widgets/byte_avatar.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.screen),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Text('FLOWBYTE', style: AppTypography.title),
                const Spacer(),
                TextButton(
                  onPressed: () => context.go('/onboarding'),
                  child: const Text('Пропустить'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            Text.rich(
              TextSpan(
                style: AppTypography.display,
                children: [
                  const TextSpan(text: 'Научи Byte принимать '),
                  TextSpan(
                    text: 'решения',
                    style: AppTypography.display.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                  const TextSpan(text: ' и повторять действия.'),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'Короткая теория, быстрые задания и видимый результат каждой строки кода.',
              style: AppTypography.bodySmall,
            ),
            const Expanded(child: _WelcomeStage()),
            PrimaryButton(
              label: 'Начать',
              onPressed: () => context.go('/onboarding'),
            ),
            const SizedBox(height: AppSpacing.xs),
            const Text(
              'Без регистрации. Работает офлайн.',
              textAlign: TextAlign.center,
              style: AppTypography.caption,
            ),
          ],
        ),
      ),
    ),
  );
}

class _WelcomeStage extends StatelessWidget {
  const _WelcomeStage();

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      const Positioned.fill(child: CustomPaint(painter: _MissionPathPainter())),
      const Positioned(
        right: AppSpacing.xl,
        top: AppSpacing.xl,
        child: AppIcon(AppIcons.flag, size: 42, color: AppColors.primary),
      ),
      const Positioned(
        left: AppSpacing.sm,
        bottom: AppSpacing.xs,
        child: ByteAvatar(size: 184),
      ),
    ],
  );
}

class _MissionPathPainter extends CustomPainter {
  const _MissionPathPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final top = Paint()..color = AppColors.surfaceInteractive;
    final side = Paint()..color = AppColors.surfaceElevated;
    final edge = Paint()
      ..color = AppColors.primary.withValues(alpha: .35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final centers = <Offset>[
      Offset(size.width * .27, size.height * .82),
      Offset(size.width * .52, size.height * .69),
      Offset(size.width * .70, size.height * .52),
      Offset(size.width * .80, size.height * .33),
    ];
    for (var index = 0; index < centers.length; index += 1) {
      final center = centers[index];
      final width = 92.0 - index * 7;
      const height = 30.0;
      final diamond = Path()
        ..moveTo(center.dx, center.dy - height / 2)
        ..lineTo(center.dx + width / 2, center.dy)
        ..lineTo(center.dx, center.dy + height / 2)
        ..lineTo(center.dx - width / 2, center.dy)
        ..close();
      canvas.drawPath(diamond, top);
      canvas.drawPath(diamond, edge);
      final front = Path()
        ..moveTo(center.dx - width / 2, center.dy)
        ..lineTo(center.dx, center.dy + height / 2)
        ..lineTo(center.dx, center.dy + height / 2 + 22)
        ..lineTo(center.dx - width / 2, center.dy + 22)
        ..close();
      canvas.drawPath(front, side);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
