import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../features/progress/progress_state.dart';

class ProgressRepository {
  const ProgressRepository();

  static const _key = 'flowbyte.progress.v1';

  Future<ProgressState> load() async {
    final preferences = await SharedPreferences.getInstance();
    final encoded = preferences.getString(_key);
    if (encoded == null) {
      return ProgressState.initial(installationId: const Uuid().v4());
    }
    return ProgressState.fromJson(jsonDecode(encoded) as Map<String, dynamic>);
  }

  Future<void> save(ProgressState progress) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_key, jsonEncode(progress.toJson()));
  }

  Future<void> clear() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_key);
  }
}

final progressRepositoryProvider = Provider<ProgressRepository>(
  (ref) => const ProgressRepository(),
);
