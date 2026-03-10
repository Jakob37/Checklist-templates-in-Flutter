import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/checklist.dart';
import '../models/checklist_history_entry.dart';
import '../models/checklist_template.dart';

const _templatesKey = 'templates';
const _checklistsKey = 'checklists';
const _historyKey = 'checklist_history';

class StorageService {
  static Future<List<ChecklistTemplate>> loadTemplates() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_templatesKey);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => ChecklistTemplate.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<void> saveTemplates(List<ChecklistTemplate> templates) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _templatesKey, jsonEncode(templates.map((t) => t.toJson()).toList()));
  }

  static Future<List<Checklist>> loadChecklists() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_checklistsKey);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => Checklist.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<void> saveChecklists(List<Checklist> checklists) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _checklistsKey, jsonEncode(checklists.map((c) => c.toJson()).toList()));
  }

  static Future<List<ChecklistHistoryEntry>> loadHistoryEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_historyKey);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => ChecklistHistoryEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<void> saveHistoryEntries(
    List<ChecklistHistoryEntry> historyEntries,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _historyKey,
      jsonEncode(historyEntries.map((entry) => entry.toJson()).toList()),
    );
  }
}
