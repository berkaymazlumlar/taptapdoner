import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:taptapdoner/domain/economy/economy_config.dart';
import 'package:taptapdoner/domain/state/game_state.dart';
import 'package:taptapdoner/services/save/save_repository.dart';

class SharedPreferencesSaveRepository implements SaveRepository {
  SharedPreferencesSaveRepository({this.storageKey = 'taptapdoner.save'});

  final String storageKey;

  @override
  Future<GameState?> load(EconomyConfig config) async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(storageKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }
      return GameState.fromJson(decoded, config);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> save(GameState state) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(storageKey, jsonEncode(state.toJson()));
  }

  @override
  Future<void> clear() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(storageKey);
  }
}
