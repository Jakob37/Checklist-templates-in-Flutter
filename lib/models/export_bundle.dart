import 'checklist.dart';
import 'checklist_template.dart';

class ExportBundle {
  final int date;
  final List<ChecklistTemplate> templates;
  final List<Checklist> checklists;

  ExportBundle({
    required this.date,
    required this.templates,
    required this.checklists,
  });

  factory ExportBundle.fromJson(Map<String, dynamic> json) => ExportBundle(
        date: json['date'] as int,
        templates: (json['templates'] as List<dynamic>)
            .map((t) => ChecklistTemplate.fromJson(t as Map<String, dynamic>))
            .toList(),
        checklists: (json['checklists'] as List<dynamic>)
            .map((c) => Checklist.fromJson(c as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'date': date,
        'templates': templates.map((t) => t.toJson()).toList(),
        'checklists': checklists.map((c) => c.toJson()).toList(),
      };
}
