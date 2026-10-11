import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

class CodeBlock extends StatelessWidget {
  const CodeBlock({
    super.key,
    required this.lines,
    this.activeLine = -1,
    this.selectedLine,
    this.onLineTap,
  });

  final List<String> lines;
  final int activeLine;
  final int? selectedLine;
  final ValueChanged<int>? onLineTap;

  TextSpan _highlight(String line) {
    final spans = <InlineSpan>[];
    final words = line.split(RegExp(r'(?=[\s():=><])|(?<=[\s():=><])'));
    for (final word in words) {
      Color color = AppColors.textPrimary;
      if (const {
        'if',
        'elif',
        'else',
        'for',
        'while',
        'in',
        'and',
        'or',
        'not',
        'break',
        'continue',
        'def',
        'return',
        'True',
        'False',
        'None',
      }.contains(word.trim())) {
        color = AppColors.codeKeyword;
      }
      if (RegExp(r'^\d+(\.\d+)?$').hasMatch(word.trim()) ||
          RegExp(r'''^['"].*['"]$''').hasMatch(word.trim())) {
        color = AppColors.codeValue;
      }
      if (word.contains('move') ||
          word.contains('turn') ||
          word.contains('charge') ||
          word.contains('wait') ||
          word.contains('range') ||
          word.contains('print') ||
          word.contains('len') ||
          word.contains('input')) {
        color = AppColors.codeFunction;
      }
      spans.add(
        TextSpan(
          text: word,
          style: AppTypography.code.copyWith(color: color),
        ),
      );
    }
    return TextSpan(children: spans);
  }

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.md),
      border: Border.all(color: AppColors.divider),
    ),
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var index = 0; index < lines.length; index += 1)
          InkWell(
            onTap: onLineTap == null ? null : () => onLineTap!(index + 1),
            child: AnimatedContainer(
              duration: AppMotion.state,
              width: double.infinity,
              constraints: BoxConstraints(
                minHeight: onLineTap == null ? 0 : 44,
              ),
              decoration: BoxDecoration(
                color: activeLine == index + 1
                    ? AppColors.primary.withValues(alpha: 0.18)
                    : selectedLine == index + 1
                    ? AppColors.surfaceInteractive
                    : Colors.transparent,
                border: Border(
                  left: BorderSide(
                    color: selectedLine == index + 1
                        ? AppColors.primary
                        : Colors.transparent,
                    width: 3,
                  ),
                ),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xxs,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 24,
                    child: Text('${index + 1}', style: AppTypography.caption),
                  ),
                  Expanded(child: Text.rich(_highlight(lines[index]))),
                ],
              ),
            ),
          ),
      ],
    ),
  );
}
