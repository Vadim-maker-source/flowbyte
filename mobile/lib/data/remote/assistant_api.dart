import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AssistantApi {
  AssistantApi()
    : _dio = Dio(
        BaseOptions(
          baseUrl: const String.fromEnvironment(
            'FLOWBYTE_API_URL',
            defaultValue: 'http://10.0.2.2:2345/api/v1',
          ),
          connectTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 120),
        ),
      );

  final Dio _dio;

  Future<String> ask({
    required String installationId,
    required String message,
    required String lessonId,
    required String exerciseId,
    required int attempts,
    required int hintsUsed,
    required List<Map<String, String>> history,
    String? moduleTitle,
    String? lessonTitle,
    String? lessonSummary,
    String? exercisePrompt,
    List<String> currentCode = const [],
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/chat',
      data: {
        'installation_id': installationId,
        'lesson_id': lessonId,
        'exercise_id': exerciseId,
        'attempts': attempts,
        'hints_used': hintsUsed,
        'message': message,
        'history': history,
        'module_title': moduleTitle,
        'lesson_title': lessonTitle,
        'lesson_summary': lessonSummary,
        'exercise_prompt': exercisePrompt,
        'current_code': currentCode,
      },
    );
    return response.data?['reply'] as String? ??
        'Сравни условие с текущими значениями.';
  }
}

final assistantApiProvider = Provider<AssistantApi>((ref) => AssistantApi());
