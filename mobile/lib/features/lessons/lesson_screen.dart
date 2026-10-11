import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../data/repositories/content_repository.dart';
import '../../shared/widgets/app_buttons.dart';
import '../../shared/widgets/byte_avatar.dart';
import '../../shared/widgets/code_block.dart';
import '../progress/progress_controller.dart';

class LessonScreen extends ConsumerWidget {
  const LessonScreen({super.key, required this.lessonId});
  final String lessonId;

  void _askByte(
    BuildContext context, {
    String? moduleId,
    required String topic,
  }) {
    final uri = Uri(
      path: '/assistant',
      queryParameters: {
        'lesson': lessonId,
        'module': ?moduleId,
        'topic': topic,
      },
    );
    context.push(uri.toString());
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final module = ref.watch(moduleProvider);
    final progress = ref.watch(progressProvider);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        leadingWidth: 60,
        leading: Padding(
          padding: const EdgeInsets.only(left: AppSpacing.xs),
          child: AppIconButton(
            icon: AppIcons.back,
            label: 'Назад',
            onPressed: context.pop,
          ),
        ),
        title: const Text('Теория Python', style: AppTypography.label),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.xs),
            child: AppIconButton(
              icon: AppIcons.question,
              label: 'Спросить Byte про этот урок',
              onPressed: () => _askByte(context, topic: 'урок целиком'),
            ),
          ),
        ],
      ),
      body: module.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        error: (error, stackTrace) =>
            const Center(child: Text('Урок временно недоступен.')),
        data: (content) {
          final lesson = content.lessonById(lessonId);
          final courseModule = content.moduleById(lesson.moduleId);
          final moduleLessons = content.lessonsForModule(lesson.moduleId);
          final pending = lesson.exercises.where(
            (exercise) => !progress.completedExercises.contains(exercise.id),
          );
          final nextExercise = pending.isEmpty
              ? lesson.exercises.first
              : pending.first;
          return SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screen,
                AppSpacing.xs,
                AppSpacing.screen,
                AppSpacing.md,
              ),
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.xs),
                    child: LinearProgressIndicator(
                      value: lesson.moduleLessonOrder / moduleLessons.length,
                      minHeight: 5,
                      color: AppColors.primary,
                      backgroundColor: AppColors.divider,
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.lg,
                      ),
                      children: [
                        Text(
                          'МОДУЛЬ ${courseModule.order} · УРОК ${lesson.moduleLessonOrder} ИЗ ${moduleLessons.length}',
                          style: AppTypography.label.copyWith(
                            color: AppColors.secondaryAccent,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(lesson.title, style: AppTypography.h1),
                        const SizedBox(height: AppSpacing.sm),
                        _AskByteStrip(
                          onTap: () => _askByte(
                            context,
                            moduleId: lesson.moduleId,
                            topic: 'урок «${lesson.title}»',
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _MissionBrief(copy: lesson.missionBrief),
                        const SizedBox(height: AppSpacing.md),
                        Text(lesson.concept, style: AppTypography.body),
                        const SizedBox(height: AppSpacing.md),
                        _TheoryCard(
                          title: 'ЗАЧЕМ ЭТО НУЖНО',
                          copy: lesson.whyItMatters,
                          icon: AppIcons.bolt,
                          onAsk: () => _askByte(
                            context,
                            moduleId: lesson.moduleId,
                            topic: 'зачем это нужно',
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _TheoryCard(
                          title: 'НА ПАЛЬЦАХ',
                          copy: lesson.analogy,
                          icon: AppIcons.lightbulb,
                          onAsk: () => _askByte(
                            context,
                            moduleId: lesson.moduleId,
                            topic: 'объяснение на пальцах',
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _ConceptStage(order: lesson.order),
                        const SizedBox(height: AppSpacing.lg),
                        CodeBlock(lines: lesson.code),
                        const SizedBox(height: AppSpacing.xs),
                        _AskCodeLink(
                          onTap: () => _askByte(
                            context,
                            moduleId: lesson.moduleId,
                            topic: 'код примера',
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        if (lesson.steps.isNotEmpty) ...[
                          _ExecutionSteps(
                            steps: lesson.steps,
                            onAsk: () => _askByte(
                              context,
                              moduleId: lesson.moduleId,
                              topic: 'порядок выполнения кода',
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                        ],
                        _TheoryCard(
                          title: 'ПРАВИЛО В ОДНУ СТРОКУ',
                          copy: lesson.ruleOfThumb,
                          icon: AppIcons.code,
                          onAsk: () => _askByte(
                            context,
                            moduleId: lesson.moduleId,
                            topic: 'правило в одну строку',
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        if (lesson.deepDive.isNotEmpty) ...[
                          _DeepDive(
                            items: lesson.deepDive,
                            onAsk: () => _askByte(
                              context,
                              moduleId: lesson.moduleId,
                              topic: 'подробный разбор',
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                        ],
                        _SelfCheckCard(
                          question: lesson.selfCheckQuestion,
                          answer: lesson.selfCheckAnswer,
                          onAsk: () => _askByte(
                            context,
                            moduleId: lesson.moduleId,
                            topic: 'вопрос для самопроверки',
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _TheoryCard(
                          title: 'НЕ ПЕРЕПУТАЙ',
                          copy: lesson.commonMistake,
                          icon: AppIcons.info,
                          onAsk: () => _askByte(
                            context,
                            moduleId: lesson.moduleId,
                            topic: 'типичная ошибка',
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _WhereUsed(
                          items: lesson.whereUsed,
                          onAsk: () => _askByte(
                            context,
                            moduleId: lesson.moduleId,
                            topic: 'где это применяется',
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _TheoryCard(
                          title: 'ЦЕЛЬ ПРАКТИКИ',
                          copy: lesson.practiceGoal,
                          icon: AppIcons.flag,
                          onAsk: () => _askByte(
                            context,
                            moduleId: lesson.moduleId,
                            topic: 'цель практики',
                          ),
                        ),
                      ],
                    ),
                  ),
                  PrimaryButton(
                    label: 'К практике · ${lesson.exercises.length} задания',
                    icon: AppIcons.play,
                    onPressed: () =>
                        context.push('/exercise/${nextExercise.id}'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _AskByteStrip extends StatelessWidget {
  const _AskByteStrip({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(AppRadius.md),
    child: Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: .09),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.primary.withValues(alpha: .45)),
      ),
      child: Row(
        children: [
          const AppIcon(AppIcons.question, size: 17, color: AppColors.primary),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              'Есть вопрос по уроку? Уточнить у Byte',
              style: AppTypography.label.copyWith(color: AppColors.textPrimary),
            ),
          ),
          const AppIcon(AppIcons.next, size: 13, color: AppColors.primary),
        ],
      ),
    ),
  );
}

class _AskCodeLink extends StatelessWidget {
  const _AskCodeLink({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerRight,
    child: TextButton.icon(
      onPressed: onTap,
      icon: const AppIcon(
        AppIcons.question,
        size: 14,
        color: AppColors.primary,
      ),
      label: const Text('Разобрать код с Byte'),
    ),
  );
}

class _QuestionButton extends StatelessWidget {
  const _QuestionButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => IconButton(
    onPressed: onTap,
    tooltip: 'Уточнить у Byte',
    visualDensity: VisualDensity.compact,
    constraints: const BoxConstraints.tightFor(width: 32, height: 32),
    padding: EdgeInsets.zero,
    icon: const AppIcon(AppIcons.question, size: 15, color: AppColors.primary),
  );
}

class _TheoryCard extends StatelessWidget {
  const _TheoryCard({
    required this.title,
    required this.copy,
    required this.icon,
    required this.onAsk,
  });
  final String title;
  final String copy;
  final FaIconData icon;
  final VoidCallback onAsk;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.md),
      border: Border.all(color: AppColors.divider),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppIcon(icon, size: 17, color: AppColors.primary),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.primary,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  _QuestionButton(onTap: onAsk),
                ],
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(copy, style: AppTypography.bodySmall),
            ],
          ),
        ),
      ],
    ),
  );
}

class _WhereUsed extends StatelessWidget {
  const _WhereUsed({required this.items, required this.onAsk});
  final List<String> items;
  final VoidCallback onAsk;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Expanded(
            child: Text(
              'ГДЕ ЭТО ВСТРЕЧАЕТСЯ',
              style: AppTypography.caption.copyWith(
                color: AppColors.textMuted,
                letterSpacing: 1,
              ),
            ),
          ),
          _QuestionButton(onTap: onAsk),
        ],
      ),
      const SizedBox(height: AppSpacing.xs),
      Wrap(
        spacing: AppSpacing.xs,
        runSpacing: AppSpacing.xs,
        children: [
          for (final item in items)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: AppColors.surfaceInteractive,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(color: AppColors.divider),
              ),
              child: Text(item, style: AppTypography.caption),
            ),
        ],
      ),
    ],
  );
}

class _DeepDive extends StatelessWidget {
  const _DeepDive({required this.items, required this.onAsk});

  final List<String> items;
  final VoidCallback onAsk;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.md),
      border: Border.all(color: AppColors.divider),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const AppIcon(AppIcons.book, size: 17, color: AppColors.primary),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'РАЗБЕРЁМ ГЛУБЖЕ',
                style: AppTypography.caption.copyWith(
                  color: AppColors.primary,
                  letterSpacing: 1,
                ),
              ),
            ),
            _QuestionButton(onTap: onAsk),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        for (var index = 0; index < items.length; index += 1)
          Padding(
            padding: EdgeInsets.only(
              bottom: index == items.length - 1 ? 0 : AppSpacing.xs,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '0${index + 1}',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.secondaryAccent,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(items[index], style: AppTypography.bodySmall),
                ),
              ],
            ),
          ),
      ],
    ),
  );
}

class _SelfCheckCard extends StatefulWidget {
  const _SelfCheckCard({
    required this.question,
    required this.answer,
    required this.onAsk,
  });

  final String question;
  final String answer;
  final VoidCallback onAsk;

  @override
  State<_SelfCheckCard> createState() => _SelfCheckCardState();
}

class _SelfCheckCardState extends State<_SelfCheckCard> {
  var _revealed = false;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: AppColors.surfaceInteractive,
      borderRadius: BorderRadius.circular(AppRadius.md),
      border: Border.all(color: AppColors.secondaryAccent),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'ПРОВЕРЬ СЕБЯ',
                style: AppTypography.caption.copyWith(
                  color: AppColors.secondaryAccent,
                  letterSpacing: 1,
                ),
              ),
            ),
            _QuestionButton(onTap: widget.onAsk),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(widget.question, style: AppTypography.title),
        const SizedBox(height: AppSpacing.sm),
        if (_revealed) ...[
          Text(widget.answer, style: AppTypography.bodySmall),
          const SizedBox(height: AppSpacing.sm),
        ],
        SecondaryButton(
          label: _revealed ? 'Скрыть ответ' : 'Показать ответ',
          onPressed: () => setState(() => _revealed = !_revealed),
        ),
      ],
    ),
  );
}

class _MissionBrief extends StatelessWidget {
  const _MissionBrief({required this.copy});
  final String copy;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(
      AppSpacing.sm,
      AppSpacing.xs,
      AppSpacing.md,
      AppSpacing.xs,
    ),
    decoration: BoxDecoration(
      color: AppColors.surfaceInteractive,
      borderRadius: BorderRadius.circular(AppRadius.md),
      border: Border.all(color: AppColors.primary.withValues(alpha: .55)),
    ),
    child: Row(
      children: [
        const ByteAvatar(size: 72, mood: ByteMood.explaining),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'БРИФИНГ МИССИИ',
                style: AppTypography.caption.copyWith(
                  color: AppColors.primary,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(copy, style: AppTypography.bodySmall),
            ],
          ),
        ),
      ],
    ),
  );
}

class _ExecutionSteps extends StatelessWidget {
  const _ExecutionSteps({required this.steps, required this.onAsk});
  final List<String> steps;
  final VoidCallback onAsk;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Expanded(
            child: Text(
              'КАК ЭТО РАБОТАЕТ',
              style: AppTypography.caption.copyWith(
                color: AppColors.textMuted,
                letterSpacing: 1,
              ),
            ),
          ),
          _QuestionButton(onTap: onAsk),
        ],
      ),
      const SizedBox(height: AppSpacing.xs),
      for (var index = 0; index < steps.length; index += 1)
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.surfaceInteractive,
                  border: Border.all(color: AppColors.primary),
                ),
                child: Text(
                  '${index + 1}',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(steps[index], style: AppTypography.bodySmall),
              ),
            ],
          ),
        ),
    ],
  );
}

class _ConceptStage extends StatelessWidget {
  const _ConceptStage({required this.order});
  final int order;

  @override
  Widget build(BuildContext context) => Container(
    height: 184,
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      border: Border.all(color: AppColors.divider),
    ),
    clipBehavior: Clip.antiAlias,
    child: Stack(
      children: [
        const Positioned.fill(
          child: CustomPaint(painter: _LessonGridPainter()),
        ),
        Positioned(
          left: AppSpacing.lg,
          bottom: AppSpacing.md,
          child: ByteAvatar(
            size: 76,
            mood: switch (order) {
              1 => ByteMood.explaining,
              2 => ByteMood.thinking,
              3 => ByteMood.moving,
              _ => ByteMood.charging,
            },
          ),
        ),
        Positioned(
          right: AppSpacing.lg,
          bottom: AppSpacing.xl,
          child: Container(
            width: 52,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.surfaceInteractive,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(color: AppColors.textMuted),
            ),
          ),
        ),
        Positioned(
          right: AppSpacing.sm,
          top: AppSpacing.sm,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 190),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: .55),
              ),
            ),
            child: Text(
              order == 3
                  ? '1 / 4 → один шаг'
                  : order == 2
                  ? '15 > 20 → false'
                  : order == 4
                  ? 'датчик → решение'
                  : 'вопрос → действие',
              style: AppTypography.caption.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class _LessonGridPainter extends CustomPainter {
  const _LessonGridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.divider.withValues(alpha: .7)
      ..strokeWidth = 1;
    const step = 32.0;
    for (var x = 0.0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    final route = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawPath(
      Path()
        ..moveTo(70, size.height - 30)
        ..lineTo(size.width - 52, size.height - 30),
      route,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
