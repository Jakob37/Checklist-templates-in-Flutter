const Object _unset = Object();

class Task {
  final String id;
  final String label;

  Task({required this.id, required this.label});

  Task copyWith({String? label}) => Task(id: id, label: label ?? this.label);

  factory Task.fromJson(Map<String, dynamic> json) =>
      Task(id: json['id'] as String, label: json['label'] as String);

  Map<String, dynamic> toJson() => {'id': id, 'label': label};
}

class TaskStack {
  final String id;
  final String label;
  final List<Task> tasks;
  final bool isOptional;
  final bool optionalDefaultIncluded;

  TaskStack({
    required this.id,
    required this.label,
    required this.tasks,
    this.isOptional = false,
    this.optionalDefaultIncluded = false,
  });

  String get trimmedLabel => label.trim();
  bool get hasVisibleLabel =>
      trimmedLabel.isNotEmpty && trimmedLabel.toLowerCase() != 'default';

  TaskStack copyWith({
    String? label,
    List<Task>? tasks,
    bool? isOptional,
    bool? optionalDefaultIncluded,
  }) =>
      TaskStack(
        id: id,
        label: label ?? this.label,
        tasks: tasks ?? this.tasks,
        isOptional: isOptional ?? this.isOptional,
        optionalDefaultIncluded:
            optionalDefaultIncluded ?? this.optionalDefaultIncluded,
      );

  factory TaskStack.fromJson(Map<String, dynamic> json) => TaskStack(
        id: json['id'] as String,
        label: json['label'] as String,
        tasks: (json['tasks'] as List<dynamic>)
            .map((t) => Task.fromJson(t as Map<String, dynamic>))
            .toList(),
        isOptional: json['isOptional'] as bool? ?? false,
        optionalDefaultIncluded: json['optionalDefaultIncluded'] as bool? ??
            (json['isOptional'] as bool? ?? false),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'tasks': tasks.map((t) => t.toJson()).toList(),
        'isOptional': isOptional,
        'optionalDefaultIncluded': optionalDefaultIncluded,
      };
}

class ChecklistTemplate {
  final String id;
  final String label;
  final List<TaskStack> stacks;
  final bool favorite;
  final int usageCount;
  final DailyTemplateSchedule? dailySchedule;

  ChecklistTemplate({
    required this.id,
    required this.label,
    required this.stacks,
    required this.favorite,
    this.usageCount = 0,
    this.dailySchedule,
  });

  ChecklistTemplate copyWith({
    String? label,
    List<TaskStack>? stacks,
    bool? favorite,
    int? usageCount,
    Object? dailySchedule = _unset,
  }) =>
      ChecklistTemplate(
        id: id,
        label: label ?? this.label,
        stacks: stacks ?? this.stacks,
        favorite: favorite ?? this.favorite,
        usageCount: usageCount ?? this.usageCount,
        dailySchedule: identical(dailySchedule, _unset)
            ? this.dailySchedule
            : dailySchedule as DailyTemplateSchedule?,
      );

  factory ChecklistTemplate.fromJson(Map<String, dynamic> json) =>
      ChecklistTemplate(
        id: json['id'] as String,
        label: json['label'] as String,
        stacks: (json['stacks'] as List<dynamic>)
            .map((s) => TaskStack.fromJson(s as Map<String, dynamic>))
            .toList(),
        favorite: json['favorite'] as bool,
        usageCount: json['usageCount'] as int? ?? 0,
        dailySchedule: json['dailySchedule'] == null
            ? null
            : DailyTemplateSchedule.fromJson(
                json['dailySchedule'] as Map<String, dynamic>,
              ),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'stacks': stacks.map((s) => s.toJson()).toList(),
        'favorite': favorite,
        'usageCount': usageCount,
        'dailySchedule': dailySchedule?.toJson(),
      };

  int get taskCount =>
      stacks.fold(0, (count, stack) => count + stack.tasks.length);
}

class DailyTemplateSchedule {
  final int hour;
  final int minute;
  final List<String> selectedOptionalStackIds;
  final String? lastInstantiatedOn;

  DailyTemplateSchedule({
    required this.hour,
    required this.minute,
    List<String>? selectedOptionalStackIds,
    this.lastInstantiatedOn,
  }) : selectedOptionalStackIds = List.unmodifiable(
          selectedOptionalStackIds ?? const <String>[],
        );

  DailyTemplateSchedule copyWith({
    int? hour,
    int? minute,
    List<String>? selectedOptionalStackIds,
    Object? lastInstantiatedOn = _unset,
  }) =>
      DailyTemplateSchedule(
        hour: hour ?? this.hour,
        minute: minute ?? this.minute,
        selectedOptionalStackIds:
            selectedOptionalStackIds ?? this.selectedOptionalStackIds,
        lastInstantiatedOn: identical(lastInstantiatedOn, _unset)
            ? this.lastInstantiatedOn
            : lastInstantiatedOn as String?,
      );

  factory DailyTemplateSchedule.fromJson(Map<String, dynamic> json) =>
      DailyTemplateSchedule(
        hour: json['hour'] as int,
        minute: json['minute'] as int,
        selectedOptionalStackIds:
            (json['selectedOptionalStackIds'] as List<dynamic>? ?? const [])
                .map((id) => id as String)
                .toList(),
        lastInstantiatedOn: json['lastInstantiatedOn'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'hour': hour,
        'minute': minute,
        'selectedOptionalStackIds': selectedOptionalStackIds,
        'lastInstantiatedOn': lastInstantiatedOn,
      };
}
