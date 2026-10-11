import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';

enum ByteMood {
  idle,
  thinking,
  moving,
  charging,
  success,
  error,
  explaining,
  trophy,
  offline,
}

class ByteAvatar extends StatelessWidget {
  const ByteAvatar({
    super.key,
    this.size = 92,
    this.level = 1,
    this.mood = ByteMood.idle,
    this.showEffects = true,
  });

  final double size;
  final int level;
  final ByteMood mood;
  final bool showEffects;

  String get _asset => 'assets/mascot/byte-${mood.name}.png';

  @override
  Widget build(BuildContext context) => Semantics(
    image: true,
    label: 'Byte, уровень $level, состояние ${_moodLabel(mood)}',
    child: TweenAnimationBuilder<double>(
      key: ValueKey(mood),
      duration: mood == ByteMood.success ? AppMotion.reward : AppMotion.page,
      tween: Tween(begin: 0, end: 1),
      curve: AppMotion.expressive,
      builder: (context, progress, child) {
        final transform = _poseTransform(mood, progress);
        return SizedBox.square(
          dimension: size,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              if (showEffects)
                Positioned.fill(
                  child: ExcludeSemantics(
                    child: CustomPaint(
                      painter: _ByteEffectPainter(mood: mood, t: progress),
                    ),
                  ),
                ),
              Transform.translate(
                offset: transform.offset * size,
                child: Transform.rotate(
                  angle: transform.rotation,
                  child: Transform.scale(
                    scale: transform.scale,
                    child: Opacity(opacity: progress.clamp(0, 1), child: child),
                  ),
                ),
              ),
              if (level >= 4 && mood == ByteMood.idle)
                Positioned(
                  right: size * .13,
                  bottom: size * .17,
                  child: _LevelCore(size: size * .16),
                ),
            ],
          ),
        );
      },
      child: ExcludeSemantics(
        child: Image.asset(
          _asset,
          width: size,
          height: size,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
          gaplessPlayback: true,
        ),
      ),
    ),
  );
}

String _moodLabel(ByteMood mood) => switch (mood) {
  ByteMood.idle => 'готов к миссии',
  ByteMood.thinking => 'думает',
  ByteMood.moving => 'движется',
  ByteMood.charging => 'заряжает систему',
  ByteMood.success => 'радуется успеху',
  ByteMood.error => 'ошибся и просит помочь',
  ByteMood.explaining => 'объясняет',
  ByteMood.trophy => 'держит награду',
  ByteMood.offline => 'отдыхает офлайн',
};

({Offset offset, double rotation, double scale}) _poseTransform(
  ByteMood mood,
  double t,
) {
  final reveal = Curves.easeOutBack.transform(t);
  return switch (mood) {
    ByteMood.success => (
      offset: Offset(0, -.10 * math.sin(t * math.pi)),
      rotation: 0,
      scale: .72 + .28 * reveal,
    ),
    ByteMood.error => (
      offset: Offset(.025 * math.sin(t * math.pi * 6) * (1 - t), 0),
      rotation: -.035 * (1 - t),
      scale: .92 + .08 * reveal,
    ),
    ByteMood.moving => (
      offset: Offset(-.14 * (1 - t), 0),
      rotation: -.05 * (1 - t),
      scale: .88 + .12 * reveal,
    ),
    ByteMood.charging => (
      offset: Offset.zero,
      rotation: 0,
      scale: .88 + .12 * reveal,
    ),
    ByteMood.thinking => (
      offset: Offset(0, -.025 * math.sin(t * math.pi)),
      rotation: .025 * (1 - t),
      scale: .90 + .10 * reveal,
    ),
    _ => (
      offset: Offset(0, .05 * (1 - t)),
      rotation: 0,
      scale: .88 + .12 * reveal,
    ),
  };
}

class _LevelCore extends StatelessWidget {
  const _LevelCore({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: AppColors.primary,
      boxShadow: [
        BoxShadow(
          color: AppColors.primary.withValues(alpha: .6),
          blurRadius: size,
        ),
      ],
    ),
  );
}

class _ByteEffectPainter extends CustomPainter {
  const _ByteEffectPainter({required this.mood, required this.t});

  final ByteMood mood;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    if (mood == ByteMood.charging || mood == ByteMood.success) {
      final pulse = Paint()
        ..color = AppColors.primary.withValues(alpha: .18 * t)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawCircle(center, size.width * (.27 + .18 * t), pulse);
    }

    final specs = switch (mood) {
      ByteMood.success || ByteMood.trophy => const [
        (.12, .16, AppColors.success, 5.0),
        (.25, .05, AppColors.primary, 4.0),
        (.79, .09, AppColors.warning, 5.0),
        (.91, .28, AppColors.success, 4.0),
        (.09, .48, AppColors.warning, 3.0),
        (.85, .58, AppColors.primary, 4.0),
      ],
      ByteMood.charging => const [
        (.08, .50, AppColors.primary, 3.0),
        (.22, .20, AppColors.secondaryAccent, 3.0),
        (.80, .22, AppColors.primary, 3.0),
        (.93, .52, AppColors.secondaryAccent, 3.0),
      ],
      ByteMood.error => const [
        (.15, .28, AppColors.error, 4.0),
        (.85, .31, AppColors.error, 3.0),
      ],
      ByteMood.thinking => const [
        (.82, .14, AppColors.primary, 4.0),
        (.91, .06, AppColors.primary, 2.5),
      ],
      ByteMood.moving => const [
        (.08, .42, AppColors.primary, 3.0),
        (.02, .54, AppColors.primary, 2.0),
      ],
      _ => const <(double, double, Color, double)>[],
    };

    for (var i = 0; i < specs.length; i++) {
      final (x, y, color, radius) = specs[i];
      final drift = (1 - t) * size.height * .08 * (i.isEven ? 1 : -1);
      final paint = Paint()..color = color.withValues(alpha: .85 * t);
      final point = Offset(size.width * x, size.height * y + drift);
      if (mood == ByteMood.success || mood == ByteMood.trophy) {
        canvas.save();
        canvas.translate(point.dx, point.dy);
        canvas.rotate(t * math.pi * (i.isEven ? 1 : -1));
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset.zero,
            width: radius * 1.7,
            height: radius,
          ),
          paint,
        );
        canvas.restore();
      } else {
        canvas.drawCircle(point, radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ByteEffectPainter oldDelegate) =>
      oldDelegate.mood != mood || oldDelegate.t != t;
}
