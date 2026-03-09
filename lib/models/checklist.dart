import 'checklist_template.dart';

// Matches TS enum: checked=0, unchecked=1, removed=2
enum CheckboxStatus { checked, unchecked, removed }

class Checkbox {
  final String id;
  final String label;
  final CheckboxStatus checked;

  Checkbox({required this.id, required this.label, required this.checked});

  Checkbox copyWith({CheckboxStatus? checked}) =>
      Checkbox(id: id, label: label, checked: checked ?? this.checked);

  factory Checkbox.fromJson(Map<String, dynamic> json) => Checkbox(
        id: json['id'] as String,
        label: json['label'] as String,
        checked: CheckboxStatus.values[json['checked'] as int],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'checked': checked.index,
      };
}

class Checklist {
  final String id;
  final ChecklistTemplate template;
  final List<Checkbox> checkboxes;
  final int timecreated;

  Checklist({
    required this.id,
    required this.template,
    required this.checkboxes,
    required this.timecreated,
  });

  Checklist copyWith({List<Checkbox>? checkboxes}) => Checklist(
        id: id,
        template: template,
        checkboxes: checkboxes ?? this.checkboxes,
        timecreated: timecreated,
      );

  factory Checklist.fromJson(Map<String, dynamic> json) => Checklist(
        id: json['id'] as String,
        template: ChecklistTemplate.fromJson(
            json['template'] as Map<String, dynamic>),
        checkboxes: (json['checkboxes'] as List<dynamic>)
            .map((c) => Checkbox.fromJson(c as Map<String, dynamic>))
            .toList(),
        timecreated: json['timecreated'] as int,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'template': template.toJson(),
        'checkboxes': checkboxes.map((c) => c.toJson()).toList(),
        'timecreated': timecreated,
      };
}
