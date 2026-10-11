import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import 'pressable.dart';

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final FaIconData? icon;
  final bool loading;

  @override
  Widget build(BuildContext context) => Pressable(
    semanticLabel: label,
    onTap: onPressed == null || loading
        ? null
        : () {
            HapticFeedback.lightImpact();
            onPressed!();
          },
    child: ClipPath(
      clipper: const CutCornerClipper(cut: 10),
      child: AnimatedContainer(
        duration: AppMotion.fast,
        height: 48,
        decoration: BoxDecoration(
          color: onPressed == null ? AppColors.surfaceInteractive : null,
          gradient: onPressed == null
              ? null
              : const LinearGradient(
                  colors: [AppColors.primary, AppColors.secondaryAccent],
                ),
        ),
        alignment: Alignment.center,
        child: loading
            ? const SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.background,
                ),
              )
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[
                      AppIcon(icon!, size: 17, color: AppColors.background),
                      const SizedBox(width: AppSpacing.xs),
                    ],
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.title.copyWith(
                          color: onPressed == null
                              ? AppColors.textMuted
                              : AppColors.background,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    ),
  );
}

class CutCornerClipper extends CustomClipper<Path> {
  const CutCornerClipper({this.cut = 10});

  final double cut;

  @override
  Path getClip(Size size) => Path()
    ..moveTo(0, 0)
    ..lineTo(size.width - cut, 0)
    ..lineTo(size.width, cut)
    ..lineTo(size.width, size.height)
    ..lineTo(cut, size.height)
    ..lineTo(0, size.height - cut)
    ..close();

  @override
  bool shouldReclip(covariant CutCornerClipper oldClipper) =>
      oldClipper.cut != cut;
}

class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final FaIconData? icon;

  @override
  Widget build(BuildContext context) => Pressable(
    semanticLabel: label,
    onTap: onPressed,
    child: Container(
      constraints: const BoxConstraints(minHeight: 48),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.divider),
      ),
      alignment: Alignment.center,
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            AppIcon(icon!, size: 17, color: AppColors.textSecondary),
            const SizedBox(width: AppSpacing.xs),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AppTypography.label.copyWith(color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    ),
  );
}

class AppIconButton extends StatelessWidget {
  const AppIconButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.color,
  });

  final FaIconData icon;
  final String label;
  final VoidCallback? onPressed;
  final Color? color;

  @override
  Widget build(BuildContext context) => Pressable(
    semanticLabel: label,
    onTap: onPressed,
    child: Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      alignment: Alignment.center,
      child: AppIcon(icon, size: 18, color: color ?? AppColors.textSecondary),
    ),
  );
}
