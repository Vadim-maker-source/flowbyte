import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class AppTypography {
  static const _family = 'Inter';

  static const display = TextStyle(
    fontFamily: _family,
    fontSize: 26,
    height: 32 / 26,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );
  static const h1 = TextStyle(
    fontFamily: _family,
    fontSize: 22,
    height: 28 / 22,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );
  static const h2 = TextStyle(
    fontFamily: _family,
    fontSize: 19,
    height: 24 / 19,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  static const title = TextStyle(
    fontFamily: _family,
    fontSize: 15,
    height: 20 / 15,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  static const body = TextStyle(
    fontFamily: _family,
    fontSize: 15,
    height: 21 / 15,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );
  static const bodySmall = TextStyle(
    fontFamily: _family,
    fontSize: 13,
    height: 18 / 13,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );
  static const label = TextStyle(
    fontFamily: _family,
    fontSize: 12,
    height: 16 / 12,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
  );
  static const caption = TextStyle(
    fontFamily: _family,
    fontSize: 11,
    height: 15 / 11,
    fontWeight: FontWeight.w500,
    color: AppColors.textMuted,
  );
  static const code = TextStyle(
    fontFamily: 'monospace',
    fontSize: 14,
    height: 21 / 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );
}
