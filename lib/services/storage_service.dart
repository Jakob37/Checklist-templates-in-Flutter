import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/checklist.dart';
import '../models/checklist_history_entry.dart';
import '../models/checklist_template.dart';
import '../models/export_bundle.dart';

const _snapshotKey = 'checklist_templates.snapshot';
const _templatesKey = 'templates';
const _checklistsKey = 'checklists';
const _historyKey = 'checklist_history';

class StorageService {
  static Future<ExportBundle> loadSnapshot() async {
    final prefs = await SharedPreferences.getInstance();
    final snapshotRaw = prefs.getString(_snapshotKey);
    if (snapshotRaw != null) {
      final Map<String, dynamic> json = Map<String, dynamic>.from(
        jsonDecode(snapshotRaw) as Map,
      );
      return ExportBundle.fromJson(json);
    }

    final templates = await loadTemplates();
    final checklists = await loadChecklists();
    final historyEntries = await loadHistoryEntries();
    return ExportBundle(
      date: DateTime.now().millisecondsSinceEpoch,
      templates: templates,
      checklists: checklists,
      historyEntries: historyEntries,
    );
  }

  static Future<void> saveSnapshot(ExportBundle bundle) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_snapshotKey, jsonEncode(bundle.toJson()));
    await prefs.remove(_templatesKey);
    await prefs.remove(_checklistsKey);
    await prefs.remove(_historyKey);
  }

  static Future<List<ChecklistTemplate>> loadTemplates() async {
    final prefs = await SharedPreferences.getInstance();
    final snapshotRaw = prefs.getString(_snapshotKey);
    if (snapshotRaw != null) {
      return loadSnapshot().then((snapshot) => snapshot.templates);
    }
    final raw = prefs.getString(_templatesKey);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => ChecklistTemplate.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<void> saveTemplates(List<ChecklistTemplate> templates) async {
    final snapshot = await loadSnapshot();
    await saveSnapshot(
      ExportBundle(
        date: DateTime.now().millisecondsSinceEpoch,
        templates: templates,
        checklists: snapshot.checklists,
        historyEntries: snapshot.historyEntries,
      ),
    );
  }

  static Future<List<Checklist>> loadChecklists() async {
    final prefs = await SharedPreferences.getInstance();
    final snapshotRaw = prefs.getString(_snapshotKey);
    if (snapshotRaw != null) {
      return loadSnapshot().then((snapshot) => snapshot.checklists);
    }
    final raw = prefs.getString(_checklistsKey);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => Checklist.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<void> saveChecklists(List<Checklist> checklists) async {
    final snapshot = await loadSnapshot();
    await saveSnapshot(
      ExportBundle(
        date: DateTime.now().millisecondsSinceEpoch,
        templates: snapshot.templates,
        checklists: checklists,
        historyEntries: snapshot.historyEntries,
      ),
    );
  }

  static Future<List<ChecklistHistoryEntry>> loadHistoryEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final snapshotRaw = prefs.getString(_snapshotKey);
    if (snapshotRaw != null) {
      return loadSnapshot().then((snapshot) => snapshot.historyEntries);
    }
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
    final snapshot = await loadSnapshot();
    await saveSnapshot(
      ExportBundle(
        date: DateTime.now().millisecondsSinceEpoch,
        templates: snapshot.templates,
        checklists: snapshot.checklists,
        historyEntries: historyEntries,
      ),
    );
  }
}
