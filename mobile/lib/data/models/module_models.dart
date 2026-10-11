enum ExerciseType { prediction, fixLogic, bugHunt, reorder, finalMission }

enum TraceAction {
  checkCondition,
  move,
  turn,
  charge,
  wait,
  sealLeak,
  fanOn,
  openTerminal,
  grantAccess,
  lock,
  launch,
  alarm,
  shutdown,
  releaseAir,
  blink,
  scan,
  skip,
  stop,
  loopStart,
  loopIteration,
  loopEnd,
}

class TraceStep {
  const TraceStep({
    required this.action,
    required this.activeLine,
    required this.label,
    this.iteration,
    this.total,
    this.position,
  });

  factory TraceStep.fromJson(Map<String, dynamic> json) => TraceStep(
    action: TraceAction.values.byName(json['action'] as String),
    activeLine: json['activeLine'] as int,
    label: json['label'] as String,
    iteration: json['iteration'] as int?,
    total: json['total'] as int?,
    position: json['position'] as int?,
  );

  final TraceAction action;
  final int activeLine;
  final String label;
  final int? iteration;
  final int? total;
  final int? position;
}

class ExerciseModel {
  const ExerciseModel({
    required this.id,
    required this.lessonId,
    required this.order,
    required this.title,
    required this.type,
    required this.prompt,
    this.missionBrief = 'Помоги Byte восстановить систему станции.',
    this.systemLabel = 'Система станции',
    this.successMessage = 'Система отвечает. Маршрут можно продолжать.',
    required this.code,
    required this.resolvedCode,
    required this.options,
    required this.correctAnswer,
    required this.hints,
    required this.explanation,
    required this.xpReward,
    required this.trace,
  });

  factory ExerciseModel.fromJson(Map<String, dynamic> json) => ExerciseModel(
    id: json['id'] as String,
    lessonId: json['lessonId'] as String,
    order: json['order'] as int? ?? 1,
    title: json['title'] as String? ?? json['prompt'] as String,
    type: ExerciseType.values.byName(json['type'] as String),
    prompt: json['prompt'] as String,
    missionBrief:
        json['missionBrief'] as String? ??
        'Помоги Byte восстановить систему станции.',
    systemLabel: json['systemLabel'] as String? ?? 'Система станции',
    successMessage:
        json['successMessage'] as String? ??
        'Система отвечает. Маршрут можно продолжать.',
    code: List<String>.from(json['code'] as List),
    resolvedCode: List<String>.from(
      json['resolvedCode'] as List? ?? json['code'] as List,
    ),
    options: List<String>.from(json['options'] as List),
    correctAnswer: List<String>.from(json['correctAnswer'] as List),
    hints: List<String>.from(json['hints'] as List),
    explanation: json['explanation'] as String,
    xpReward: json['xpReward'] as int,
    trace: (json['simulation'] as List)
        .map((value) => TraceStep.fromJson(value as Map<String, dynamic>))
        .toList(),
  );

  final String id;
  final String lessonId;
  final int order;
  final String title;
  final ExerciseType type;
  final String prompt;
  final String missionBrief;
  final String systemLabel;
  final String successMessage;
  final List<String> code;
  final List<String> resolvedCode;
  final List<String> options;
  final List<String> correctAnswer;
  final List<String> hints;
  final String explanation;
  final int xpReward;
  final List<TraceStep> trace;
}

class LessonModel {
  const LessonModel({
    required this.id,
    required this.order,
    required this.title,
    required this.eyebrow,
    this.moduleId = 'conditions',
    this.moduleLessonOrder = 1,
    this.location = 'Станция Helios',
    this.missionBrief = 'Разбери принцип и примени его в миссии.',
    this.whyItMatters = 'Этот приём помогает программе принимать решения.',
    this.whereUsed = const ['игры', 'приложения', 'роботы'],
    this.practiceGoal = 'Объяснить ход программы и применить конструкцию.',
    this.ruleOfThumb =
        'Сначала прочитай код по строкам, затем проверь условие.',
    this.deepDive = const [],
    this.selfCheckQuestion = 'Какая строка выполнится следующей?',
    this.selfCheckAnswer = 'Ответ зависит от результата условия.',
    required this.concept,
    required this.analogy,
    required this.steps,
    required this.commonMistake,
    required this.explanation,
    required this.code,
    required this.exercises,
  });

  factory LessonModel.fromJson(Map<String, dynamic> json) => LessonModel(
    id: json['id'] as String,
    order: json['order'] as int,
    title: json['title'] as String,
    eyebrow: json['eyebrow'] as String,
    moduleId: json['moduleId'] as String? ?? 'conditions',
    moduleLessonOrder:
        json['moduleLessonOrder'] as int? ?? json['order'] as int,
    location: json['location'] as String? ?? 'Станция Helios',
    missionBrief: json['missionBrief'] as String? ?? json['concept'] as String,
    whyItMatters:
        json['whyItMatters'] as String? ??
        'Этот приём помогает программе принимать решения.',
    whereUsed: List<String>.from(
      json['whereUsed'] as List? ?? const ['игры', 'приложения', 'роботы'],
    ),
    practiceGoal:
        json['practiceGoal'] as String? ??
        'Объяснить ход программы и применить конструкцию.',
    ruleOfThumb:
        json['ruleOfThumb'] as String? ??
        'Сначала прочитай код по строкам, затем проверь условие.',
    deepDive: List<String>.from(json['deepDive'] as List? ?? const []),
    selfCheckQuestion:
        json['selfCheckQuestion'] as String? ??
        'Какая строка выполнится следующей?',
    selfCheckAnswer:
        json['selfCheckAnswer'] as String? ??
        'Ответ зависит от результата условия.',
    concept: json['concept'] as String,
    analogy: json['analogy'] as String? ?? json['concept'] as String,
    steps: List<String>.from(json['steps'] as List? ?? const []),
    commonMistake:
        json['commonMistake'] as String? ?? json['explanation'] as String,
    explanation: json['explanation'] as String,
    code: List<String>.from(json['code'] as List),
    exercises: json['exercises'] != null
        ? (json['exercises'] as List)
              .map(
                (value) =>
                    ExerciseModel.fromJson(value as Map<String, dynamic>),
              )
              .toList()
        : [ExerciseModel.fromJson(json['exercise'] as Map<String, dynamic>)],
  );

  final String id;
  final int order;
  final String title;
  final String eyebrow;
  final String moduleId;
  final int moduleLessonOrder;
  final String location;
  final String missionBrief;
  final String whyItMatters;
  final List<String> whereUsed;
  final String practiceGoal;
  final String ruleOfThumb;
  final List<String> deepDive;
  final String selfCheckQuestion;
  final String selfCheckAnswer;
  final String concept;
  final String analogy;
  final List<String> steps;
  final String commonMistake;
  final String explanation;
  final List<String> code;
  final List<ExerciseModel> exercises;

  ExerciseModel get exercise => exercises.first;
}

class CourseModuleModel {
  const CourseModuleModel({
    required this.id,
    required this.order,
    required this.title,
    required this.description,
    required this.certificateTitle,
    required this.lessonIds,
  });

  factory CourseModuleModel.fromJson(Map<String, dynamic> json) =>
      CourseModuleModel(
        id: json['id'] as String,
        order: json['order'] as int,
        title: json['title'] as String,
        description: json['description'] as String,
        certificateTitle:
            json['certificateTitle'] as String? ?? json['title'] as String,
        lessonIds: List<String>.from(json['lessonIds'] as List),
      );

  final String id;
  final int order;
  final String title;
  final String description;
  final String certificateTitle;
  final List<String> lessonIds;
}

class ModuleModel {
  const ModuleModel({
    required this.id,
    required this.title,
    required this.description,
    required this.modules,
    required this.lessons,
    required this.finalMission,
  });

  factory ModuleModel.fromJson(Map<String, dynamic> json) => ModuleModel(
    id: json['id'] as String,
    title: json['title'] as String,
    description: json['description'] as String,
    modules: (json['modules'] as List? ?? const [])
        .map(
          (value) => CourseModuleModel.fromJson(value as Map<String, dynamic>),
        )
        .toList(),
    lessons: (json['lessons'] as List)
        .map((value) => LessonModel.fromJson(value as Map<String, dynamic>))
        .toList(),
    finalMission: ExerciseModel.fromJson(
      json['finalMission'] as Map<String, dynamic>,
    ),
  );

  final String id;
  final String title;
  final String description;
  final List<CourseModuleModel> modules;
  final List<LessonModel> lessons;
  final ExerciseModel finalMission;

  LessonModel lessonById(String id) =>
      lessons.firstWhere((lesson) => lesson.id == id);
  List<LessonModel> lessonsForModule(String moduleId) =>
      lessons.where((lesson) => lesson.moduleId == moduleId).toList()
        ..sort((a, b) => a.moduleLessonOrder.compareTo(b.moduleLessonOrder));

  CourseModuleModel moduleById(String id) =>
      modules.firstWhere((module) => module.id == id);
  ExerciseModel exerciseById(String id) => id == finalMission.id
      ? finalMission
      : lessons
            .expand((lesson) => lesson.exercises)
            .firstWhere((exercise) => exercise.id == id);

  LessonModel lessonForExercise(String exerciseId) => lessons.firstWhere(
    (lesson) => lesson.exercises.any((exercise) => exercise.id == exerciseId),
  );

  ExerciseModel? nextExercise(String exerciseId) {
    final lesson = lessonForExercise(exerciseId);
    final index = lesson.exercises.indexWhere(
      (exercise) => exercise.id == exerciseId,
    );
    return index >= 0 && index < lesson.exercises.length - 1
        ? lesson.exercises[index + 1]
        : null;
  }
}
