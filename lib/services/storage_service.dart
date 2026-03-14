// storage_service.dart v6 - routines, settings, todos, daySession
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/routine.dart';
import '../models/app_settings.dart';

class StorageService {
  static const _rKey = 'routines_v6';
  static const _sKey = 'app_settings_v6';
  static const _todoPrefix = 'todos_v6_';

  Future<List<Routine>> getRoutines() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_rKey);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list.map((e) => Routine.fromJson(Map<String, dynamic>.from(e))).toList();
    } catch (_) { return []; }
  }

  Future<void> addRoutine(Routine r) async {
    final list = await getRoutines();
    list.add(r);
    await _saveRoutines(list);
  }

  Future<void> updateRoutine(Routine r) async {
    final list = await getRoutines();
    final i = list.indexWhere((e) => e.id == r.id);
    if (i != -1) { list[i] = r; await _saveRoutines(list); }
  }

  Future<void> deleteRoutine(String id) async {
    final list = await getRoutines();
    list.removeWhere((e) => e.id == id);
    await _saveRoutines(list);
  }

  Future<void> replaceAllRoutines(List<Routine> routines) async {
    await _saveRoutines(routines);
  }

  Future<void> _saveRoutines(List<Routine> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_rKey, jsonEncode(list.map((e) => e.toJson()).toList()));
  }

  Future<AppSettings> getSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_sKey);
    if (raw == null) return AppSettings();
    try { return AppSettings.fromJson(jsonDecode(raw)); } catch (_) { return AppSettings(); }
  }

  Future<void> saveSettings(AppSettings s) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sKey, jsonEncode(s.toJson()));
  }

  Future<List<TodoItem>> getTodos(String dateKey) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_todoPrefix$dateKey');
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list.map((e) => TodoItem.fromJson(Map<String, dynamic>.from(e))).toList();
    } catch (_) { return []; }
  }

  Future<void> saveTodos(String dateKey, List<TodoItem> todos) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_todoPrefix$dateKey', jsonEncode(todos.map((e) => e.toJson()).toList()));
  }

  static const _daySessionPrefix = 'day_session_v6_';

  Future<Map<String, dynamic>?> getDaySession(String dateKey) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_daySessionPrefix$dateKey');
    if (raw == null) return null;
    try { return jsonDecode(raw) as Map<String, dynamic>; } catch (_) { return null; }
  }

  Future<void> saveDaySession(String dateKey, Map<String, dynamic> session) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_daySessionPrefix$dateKey', jsonEncode(session));
  }

  Future<void> clearAllUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().toList();
    for (final key in keys) {
      if (key.startsWith(_todoPrefix) || key.startsWith(_daySessionPrefix) || key == _rKey) {
        await prefs.remove(key);
      }
    }
  }

  Future<bool> getTipShown(String tipKey) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('tip_$tipKey') ?? false;
  }

  Future<void> setTipShown(String tipKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tip_$tipKey', true);
  }
}
