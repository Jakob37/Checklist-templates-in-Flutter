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

  TaskStack({
    required this.id,
    required this.label,
    required this.tasks,
    this.isOptional = false,
  });

  String get trimmedLabel => label.trim();
  bool get hasVisibleLabel =>
      trimmedLabel.isNotEmpty && trimmedLabel.toLowerCase() != 'default';

  TaskStack copyWith({String? label, List<Task>? tasks, bool? isOptional}) =>
      TaskStack(
        id: id,
        label: label ?? this.label,
        tasks: tasks ?? this.tasks,
        isOptional: isOptional ?? this.isOptional,
      );

  factory TaskStack.fromJson(Map<String, dynamic> json) => TaskStack(
        id: json['id'] as String,
        label: json['label'] as String,
        tasks: (json['tasks'] as List<dynamic>)
            .map((t) => Task.fromJson(t as Map<String, dynamic>))
            .toList(),
        isOptional: json['isOptional'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'tasks': tasks.map((t) => t.toJson()).toList(),
        'isOptional': isOptional,
      };
}

class ChecklistTemplate {
  final String id;
  final String label;
  final List<TaskStack> stacks;
  final bool favorite;

  ChecklistTemplate({
    required this.id,
    required this.label,
    required this.stacks,
    required this.favorite,
  });

  ChecklistTemplate copyWith({
    String? label,
    List<TaskStack>? stacks,
    bool? favorite,
  }) =>
      ChecklistTemplate(
        id: id,
        label: label ?? this.label,
        stacks: stacks ?? this.stacks,
        favorite: favorite ?? this.favorite,
      );

  factory ChecklistTemplate.fromJson(Map<String, dynamic> json) =>
      ChecklistTemplate(
        id: json['id'] as String,
        label: json['label'] as String,
        stacks: (json['stacks'] as List<dynamic>)
            .map((s) => TaskStack.fromJson(s as Map<String, dynamic>))
            .toList(),
        favorite: json['favorite'] as bool,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'stacks': stacks.map((s) => s.toJson()).toList(),
        'favorite': favorite,
      };

  int get taskCount =>
      stacks.fold(0, (count, stack) => count + stack.tasks.length);
}
