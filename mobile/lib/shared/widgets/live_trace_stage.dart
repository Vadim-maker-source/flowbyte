import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/module_models.dart';
import '../../features/live_trace/live_trace_controller.dart';
import 'byte_avatar.dart';

class LiveTraceStage extends StatelessWidget {
  const LiveTraceStage({
    super.key,
    required this.trace,
    required this.plan,
    required this.systemLabel,
    this.level = 1,
    this.finalMission = false,
  });

  final LiveTraceState trace;
  final List<TraceStep> plan;
  final String systemLabel;
  final int level;
  final bool finalMission;

  @override
  Widget build(BuildContext context) {
    final action = trace.step?.action;
    final hasMovement = plan.any((step) => step.action == TraceAction.move);
    final initialPosition = plan.isEmpty ? 0 : (plan.first.position ?? 0);
    final rawPosition = trace.step?.position ?? initialPosition;
    final position = hasMovement ? rawPosition : 0;
    final hasTurn = plan.any((step) => step.action == TraceAction.turn);
    final mood = switch (action) {
      TraceAction.charge => ByteMood.charging,
      TraceAction.stop ||
      TraceAction.shutdown ||
      TraceAction.alarm => ByteMood.error,
      TraceAction.move || TraceAction.turn => ByteMood.moving,
      _ when trace.complete => ByteMood.success,
      _ when trace.running => ByteMood.thinking,
      _ => ByteMood.idle,
    };
    return Semantics(
      label: trace.step?.label ?? 'Сцена выполнения. Byte ожидает запуска.',
      liveRegion: trace.running,
      child: Container(
        height: finalMission ? 218 : 170,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.divider),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _GridPainter(
                  finalMission: finalMission,
                  showRoute: hasMovement,
                ),
              ),
            ),
            if (hasTurn || finalMission)
              const Positioned(left: 154, top: 76, child: _Obstacle()),
            if (hasMovement)
              Positioned(
                right: finalMission ? 58 : 20,
                bottom: finalMission ? 28 : 34,
                child: const _Destination(),
              )
            else
              Positioned(
                right: AppSpacing.md,
                bottom: 28,
                child: _SystemEffect(
                  action: action,
                  systemLabel: systemLabel,
                  active: trace.running || trace.complete,
                ),
              ),
            AnimatedPositioned(
              duration: AppMotion.traceStep,
              curve: AppMotion.standard,
              left: 18 + position.clamp(0, 4) * (finalMission ? 52 : 58),
              bottom: finalMission && position >= 2 ? 40 : 30,
              child: ByteAvatar(size: 58, level: level, mood: mood),
            ),
            Positioned(
              top: AppSpacing.sm,
              left: AppSpacing.sm,
              child: _StepBadge(trace: trace),
            ),
            if (trace.step != null)
              Positioned(
                top: AppSpacing.sm,
                right: AppSpacing.sm,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 190),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated.withValues(alpha: 0.96),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    border: Border.all(
                      color: _actionColor(action).withValues(alpha: 0.6),
                    ),
                  ),
                  child: Text(
                    trace.step!.label,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StepBadge extends StatelessWidget {
  const _StepBadge({required this.trace});
  final LiveTraceState trace;

  @override
  Widget build(BuildContext context) {
    final current = trace.stepIndex < 0 ? 0 : trace.stepIndex + 1;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: .82),
        borderRadius: BorderRadius.circular(AppRadius.xs),
        border: Border.all(color: AppColors.divider),
      ),
      child: Text(
        trace.totalSteps == 0
            ? 'ОЖИДАНИЕ'
            : 'ТАКТ $current / ${trace.totalSteps}',
        style: AppTypography.caption.copyWith(
          color: trace.running ? AppColors.primary : AppColors.textMuted,
          letterSpacing: .7,
        ),
      ),
    );
  }
}

class _SystemEffect extends StatelessWidget {
  const _SystemEffect({
    required this.action,
    required this.systemLabel,
    required this.active,
  });

  final TraceAction? action;
  final String systemLabel;
  final bool active;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: AppMotion.state,
    width: 112,
    padding: const EdgeInsets.all(AppSpacing.sm),
    decoration: BoxDecoration(
      color: active
          ? _actionColor(action).withValues(alpha: .13)
          : AppColors.surfaceInteractive,
      borderRadius: BorderRadius.circular(AppRadius.md),
      border: Border.all(
        color: active ? _actionColor(action) : AppColors.divider,
      ),
      boxShadow: active
          ? [
              BoxShadow(
                color: _actionColor(action).withValues(alpha: .14),
                blurRadius: 18,
              ),
            ]
          : null,
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppIcon(
          _actionIcon(action),
          size: 22,
          color: active ? _actionColor(action) : AppColors.textMuted,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          systemLabel,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: AppTypography.caption.copyWith(
            color: active ? AppColors.textPrimary : AppColors.textMuted,
          ),
        ),
      ],
    ),
  );
}

FaIconData _actionIcon(TraceAction? action) => switch (action) {
  TraceAction.charge => AppIcons.bolt,
  TraceAction.wait || TraceAction.stop => AppIcons.close,
  TraceAction.sealLeak ||
  TraceAction.releaseAir ||
  TraceAction.fanOn => AppIcons.rotate,
  TraceAction.openTerminal || TraceAction.grantAccess => AppIcons.check,
  TraceAction.lock => AppIcons.lock,
  TraceAction.launch => AppIcons.flag,
  TraceAction.alarm || TraceAction.shutdown => AppIcons.info,
  TraceAction.blink => AppIcons.lightbulb,
  TraceAction.scan => AppIcons.tasks,
  TraceAction.skip => AppIcons.next,
  TraceAction.turn => AppIcons.rotate,
  TraceAction.move => AppIcons.map,
  TraceAction.loopEnd => AppIcons.check,
  _ => AppIcons.code,
};

Color _actionColor(TraceAction? action) => switch (action) {
  TraceAction.alarm ||
  TraceAction.shutdown ||
  TraceAction.stop => AppColors.error,
  TraceAction.charge ||
  TraceAction.blink ||
  TraceAction.fanOn => AppColors.warning,
  TraceAction.openTerminal ||
  TraceAction.grantAccess ||
  TraceAction.launch ||
  TraceAction.sealLeak ||
  TraceAction.releaseAir ||
  TraceAction.loopEnd => AppColors.success,
  _ => AppColors.primary,
};

class _GridPainter extends CustomPainter {
  const _GridPainter({required this.finalMission, required this.showRoute});
  final bool finalMission;
  final bool showRoute;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.divider.withValues(alpha: 0.65)
      ..strokeWidth = 1;
    const step = 32.0;
    for (var x = 0.0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    if (showRoute) {
      final path = Paint()
        ..color = AppColors.primary.withValues(alpha: 0.55)
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke;
      canvas.drawPath(
        Path()
          ..moveTo(40, size.height - 34)
          ..lineTo(size.width * .44, size.height - 34)
          ..lineTo(
            size.width * .58,
            finalMission ? size.height - 76 : size.height - 34,
          )
          ..lineTo(
            size.width - 38,
            finalMission ? size.height - 76 : size.height - 34,
          ),
        path,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) =>
      oldDelegate.finalMission != finalMission ||
      oldDelegate.showRoute != showRoute;
}

class _Obstacle extends StatelessWidget {
  const _Obstacle();

  @override
  Widget build(BuildContext context) => Container(
    width: 42,
    height: 42,
    decoration: BoxDecoration(
      color: AppColors.textMuted,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      border: Border.all(color: AppColors.textSecondary),
    ),
  );
}

class _Destination extends StatelessWidget {
  const _Destination();

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Цель маршрута',
    child: Container(
      width: 38,
      height: 38,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.secondaryAccent.withValues(alpha: .18),
        border: Border.all(color: AppColors.secondaryAccent, width: 2),
      ),
      child: const AppIcon(
        AppIcons.flag,
        size: 16,
        color: AppColors.secondaryAccent,
      ),
    ),
  );
}
