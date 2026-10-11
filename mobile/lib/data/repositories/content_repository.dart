import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/module_models.dart';

class ContentRepository {
  const ContentRepository();

  Future<ModuleModel> loadModule() async {
    final raw = await rootBundle.loadString('assets/content/module.json');
    return ModuleModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }
}

final contentRepositoryProvider = Provider<ContentRepository>(
  (ref) => const ContentRepository(),
);
final moduleProvider = FutureProvider<ModuleModel>(
  (ref) => ref.read(contentRepositoryProvider).loadModule(),
);
