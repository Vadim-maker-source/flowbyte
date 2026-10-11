class ProgressState {
  const ProgressState({
    required this.installationId,
    required this.onboardingComplete,
    required this.completedLessons,
    required this.completedExercises,
    required this.xp,
    required this.attempts,
    required this.usedHints,
    required this.finalComplete,
    required this.backendOffline,
    required this.hydrated,
  });

  factory ProgressState.initial({String installationId = ''}) => ProgressState(
    installationId: installationId,
    onboardingComplete: false,
    completedLessons: const <String>{},
    completedExercises: const <String>{},
    xp: 0,
    attempts: const <String, int>{},
    usedHints: const <String, int>{},
    finalComplete: false,
    backendOffline: false,
    hydrated: false,
  );

  factory ProgressState.fromJson(Map<String, dynamic> json) => ProgressState(
    installationId: json['installationId'] as String? ?? '',
    onboardingComplete: json['onboardingComplete'] as bool? ?? false,
    completedLessons: Set<String>.from(
      json['completedLessons'] as List? ?? const [],
    ),
    completedExercises: Set<String>.from(
      json['completedExercises'] as List? ?? const [],
    ),
    xp: json['xp'] as int? ?? 0,
    attempts: Map<String, int>.from(json['attempts'] as Map? ?? const {}),
    usedHints: Map<String, int>.from(json['usedHints'] as Map? ?? const {}),
    finalComplete: json['finalComplete'] as bool? ?? false,
    backendOffline: json['backendOffline'] as bool? ?? false,
    hydrated: true,
  );

  final String installationId;
  final bool onboardingComplete;
  final Set<String> completedLessons;
  final Set<String> completedExercises;
  final int xp;
  final Map<String, int> attempts;
  final Map<String, int> usedHints;
  final bool finalComplete;
  final bool backendOffline;
  final bool hydrated;

  int get byteLevel => levelForXp(xp);
  int get xpIntoLevel => xp % 100;
  double get levelProgress => xpIntoLevel / 100;
  int get nextLessonNumber => (completedLessons.length + 1).clamp(1, 8);
  int get totalAttempts => attempts.values.fold(0, (sum, value) => sum + value);
  int get totalHints => usedHints.values.fold(0, (sum, value) => sum + value);

  static int levelForXp(int xp) => (xp ~/ 100 + 1).clamp(1, 10);

  bool lessonUnlocked(int order) =>
      order <= completedLessons.length + 1 ||
      completedLessons.contains('lesson-$order');

  bool moduleCompleted(List<String> lessonIds, {bool requiresFinal = false}) =>
      lessonIds.every(completedLessons.contains) &&
      (!requiresFinal || finalComplete);

  ProgressState copyWith({
    String? installationId,
    bool? onboardingComplete,
    Set<String>? completedLessons,
    Set<String>? completedExercises,
    int? xp,
    Map<String, int>? attempts,
    Map<String, int>? usedHints,
    bool? finalComplete,
    bool? backendOffline,
    bool? hydrated,
  }) => ProgressState(
    installationId: installationId ?? this.installationId,
    onboardingComplete: onboardingComplete ?? this.onboardingComplete,
    completedLessons: completedLessons ?? this.completedLessons,
    completedExercises: completedExercises ?? this.completedExercises,
    xp: xp ?? this.xp,
    attempts: attempts ?? this.attempts,
    usedHints: usedHints ?? this.usedHints,
    finalComplete: finalComplete ?? this.finalComplete,
    backendOffline: backendOffline ?? this.backendOffline,
    hydrated: hydrated ?? this.hydrated,
  );

  Map<String, dynamic> toJson() => {
    'installationId': installationId,
    'onboardingComplete': onboardingComplete,
    'completedLessons': completedLessons.toList(),
    'completedExercises': completedExercises.toList(),
    'xp': xp,
    'attempts': attempts,
    'usedHints': usedHints,
    'finalComplete': finalComplete,
    'backendOffline': backendOffline,
  };
}
