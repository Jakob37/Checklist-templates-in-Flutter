import 'checklist.dart';
import 'checklist_history_entry.dart';
import 'checklist_template.dart';

class ExportBundle {
  static const int currentSchemaVersion = 1;

  final int schemaVersion;
  final int date;
  final List<ChecklistTemplate> templates;
  final List<Checklist> checklists;
  final List<ChecklistHistoryEntry> historyEntries;

  ExportBundle({
    this.schemaVersion = currentSchemaVersion,
    required this.date,
    required this.templates,
    required this.checklists,
    this.historyEntries = const <ChecklistHistoryEntry>[],
  });

  factory ExportBundle.fromJson(Map<String, dynamic> json) => ExportBundle(
        schemaVersion: json['schemaVersion'] as int? ?? currentSchemaVersion,
        date: json['date'] as int,
        templates: ((json['templates'] as List<dynamic>?) ?? const <dynamic>[])
            .map((t) => ChecklistTemplate.fromJson(t as Map<String, dynamic>))
            .toList(),
        checklists:
            ((json['checklists'] as List<dynamic>?) ?? const <dynamic>[])
                .map((c) => Checklist.fromJson(c as Map<String, dynamic>))
                .toList(),
        historyEntries:
            ((json['historyEntries'] as List<dynamic>?) ?? const <dynamic>[])
                .map(
                  (entry) => ChecklistHistoryEntry.fromJson(
                    entry as Map<String, dynamic>,
                  ),
                )
                .toList(),
      );

  Map<String, dynamic> toJson() => {
        'schemaVersion': schemaVersion,
        'date': date,
        'templates': templates.map((t) => t.toJson()).toList(),
        'checklists': checklists.map((c) => c.toJson()).toList(),
        'historyEntries':
            historyEntries.map((entry) => entry.toJson()).toList(),
      };
}
