import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_motion.dart';
import '../../data/models/module_models.dart';

class LiveTraceState {
  const LiveTraceState({
    this.running = false,
    this.complete = false,
    this.stepIndex = -1,
    this.totalSteps = 0,
    this.step,
  });

  final bool running;
  final bool complete;
  final int stepIndex;
  final int totalSteps;
  final TraceStep? step;
}

class LiveTraceController extends Notifier<LiveTraceState> {
  @override
  LiveTraceState build() => const LiveTraceState();

  Future<void> play(List<TraceStep> steps) async {
    state = LiveTraceState(running: true, totalSteps: steps.length);
    for (var index = 0; index < steps.length; index += 1) {
      if (!ref.mounted) {
        return;
      }
      state = LiveTraceState(
        running: true,
        stepIndex: index,
        totalSteps: steps.length,
        step: steps[index],
      );
      await Future<void>.delayed(AppMotion.traceStep);
    }
    if (ref.mounted) {
      state = LiveTraceState(
        complete: true,
        stepIndex: steps.length - 1,
        totalSteps: steps.length,
        step: steps.lastOrNull,
      );
    }
  }

  void reset() => state = const LiveTraceState();
}

final liveTraceProvider =
    NotifierProvider.autoDispose<LiveTraceController, LiveTraceState>(
      LiveTraceController.new,
    );
