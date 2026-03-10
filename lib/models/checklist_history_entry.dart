class ChecklistHistoryEntry {
  final String id;
  final String templateId;
  final String templateLabel;
  final int completedAt;

  ChecklistHistoryEntry({
    required this.id,
    required this.templateId,
    required this.templateLabel,
    required this.completedAt,
  });

  factory ChecklistHistoryEntry.fromJson(Map<String, dynamic> json) =>
      ChecklistHistoryEntry(
        id: json['id'] as String,
        templateId: json['templateId'] as String,
        templateLabel: json['templateLabel'] as String,
        completedAt: json['completedAt'] as int,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'templateId': templateId,
        'templateLabel': templateLabel,
        'completedAt': completedAt,
      };
}
