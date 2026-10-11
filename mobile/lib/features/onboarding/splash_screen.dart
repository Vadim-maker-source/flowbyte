import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_typography.dart';
import '../progress/progress_controller.dart';
import '../../shared/widgets/byte_avatar.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _schedule();
  }

  void _schedule() {
    _timer = Timer(AppMotion.splash, () {
      if (!mounted) return;
      final progress = ref.read(progressProvider);
      if (!progress.hydrated) {
        _schedule();
      } else {
        context.go(progress.onboardingComplete ? '/home' : '/welcome');
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const Scaffold(
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ByteAvatar(size: 84),
          SizedBox(height: 16),
          Text('FLOWBYTE', style: AppTypography.h1),
          SizedBox(height: 8),
          Text(
            'Код становится движением',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    ),
  );
}
