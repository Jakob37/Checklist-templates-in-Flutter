import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../models/checklist.dart';
import '../models/checklist_history_entry.dart';
import '../models/checklist_template.dart';
import '../models/export_bundle.dart';
import '../models/id_gen.dart';
import '../services/automatic_backup_preferences.dart';
import '../services/automatic_backup_service.dart';
import '../services/reminder_service.dart';
import '../services/storage_service.dart';

class AppState extends ChangeNotifier {
  AppState({
    ReminderService? reminderService,
    DateTime Function()? now,
    ChecklistBackupService? backupService,
    ChecklistBackupPreferences? backupPreferences,
  })  : _reminderService = reminderService ?? const NoOpReminderService(),
        _now = now ?? DateTime.now,
        _backupService = backupService ?? const ChecklistBackupService(),
        _backupPreferences =
            backupPreferences ?? const ChecklistBackupPreferences();

  final ReminderService _reminderService;
  final DateTime Function() _now;
  final ChecklistBackupService _backupService;
  final ChecklistBackupPreferences _backupPreferences;

  List<ChecklistTemplate> _templates = <ChecklistTemplate>[];
  List<Checklist> _checklists = <Checklist>[];
  List<ChecklistHistoryEntry> _historyEntries = <ChecklistHistoryEntry>[];
  bool _automaticBackupsEnabled = false;

  List<ChecklistTemplate> get templates => List.unmodifiable(_templates);
  List<Checklist> get checklists => List.unmodifiable(_checklists);
  List<ChecklistHistoryEntry> get historyEntries =>
      List.unmodifiable(_historyEntries);
  bool get automaticBackupsEnabled => _automaticBackupsEnabled;

  List<ChecklistTemplate> get sortedTemplates {
    final List<ChecklistTemplate> sorted = <ChecklistTemplate>[..._templates];
    sorted.sort((ChecklistTemplate a, ChecklistTemplate b) {
      if (a.favorite != b.favorite) {
        return a.favorite ? -1 : 1;
      }
      final int usageCompare = b.usageCount.compareTo(a.usageCount);
      if (usageCompare != 0) {
        return usageCompare;
      }
      return a.label.compareTo(b.label);
    });
    return List.unmodifiable(sorted);
  }

  Future<void> init() async {
    await _reminderService.init();
    final ExportBundle snapshot = await StorageService.loadSnapshot();
    _templates = snapshot.templates;
    _checklists = snapshot.checklists;
    _historyEntries = snapshot.historyEntries;
    _automaticBackupsEnabled =
        await _backupPreferences.loadAutomaticBackupsEnabled();
    await _reminderService.syncAllTemplateReminders(_templates);
  }

  Future<void> saveTemplate(
    ChecklistTemplate template, {
    bool syncActiveChecklists = false,
  }) async {
    await saveNewTemplates(
      <ChecklistTemplate>[template],
      syncActiveChecklists: syncActiveChecklists,
    );
  }

  Future<void> saveNewTemplates(
    List<ChecklistTemplate> newTemplates, {
    bool syncActiveChecklists = false,
  }) async {
    final Map<String, ChecklistTemplate> existingById =
        <String, ChecklistTemplate>{
      for (final ChecklistTemplate template in _templates)
        template.id: template,
    };
    final List<ChecklistTemplate> normalizedTemplates = newTemplates.map((
      ChecklistTemplate template,
    ) {
      final ChecklistTemplate? existing = existingById[template.id];
      final ChecklistTemplate normalizedTemplate = _normalizeTemplateSchedule(
        template,
      );
      if (existing == null || normalizedTemplate.usageCount > 0) {
        return normalizedTemplate;
      }
      return normalizedTemplate.copyWith(usageCount: existing.usageCount);
    }).toList();

    final Set<String> newIds = <String>{
      for (final ChecklistTemplate template in normalizedTemplates) template.id,
    };
    final List<ChecklistTemplate> kept = _templates
        .where((ChecklistTemplate template) => !newIds.contains(template.id))
        .toList();
    kept.addAll(normalizedTemplates);
    _templates = kept;

    if (syncActiveChecklists) {
      for (final ChecklistTemplate template in normalizedTemplates) {
        _syncActiveChecklistsForTemplate(template);
      }
    }

    await _persistState();
    await _reminderService.syncAllTemplateReminders(_templates);
    notifyListeners();
  }

  Future<void> removeTemplate(String id) async {
    _templates = _templates
        .where((ChecklistTemplate template) => template.id != id)
        .toList();
    await _persistState();
    await _reminderService.cancelTemplateReminder(id);
    notifyListeners();
  }

  Future<void> saveChecklist(Checklist checklist) async {
    final bool isNewChecklist = !_checklists.any(
      (Checklist existing) => existing.id == checklist.id,
    );
    Checklist storedChecklist = checklist;

    if (isNewChecklist) {
      final int templateIndex = _templates.indexWhere(
        (ChecklistTemplate template) => template.id == checklist.template.id,
      );
      if (templateIndex >= 0) {
        final ChecklistTemplate updatedTemplate = _templates[templateIndex]
            .copyWith(usageCount: _templates[templateIndex].usageCount + 1);
        _templates = _templates.map((ChecklistTemplate template) {
          return template.id == updatedTemplate.id ? updatedTemplate : template;
        }).toList();
        storedChecklist = checklist.copyWith(
          template: checklist.template.copyWith(
            usageCount: updatedTemplate.usageCount,
          ),
        );
      }
    }

    final List<Checklist> without = _checklists
        .where((Checklist existing) => existing.id != checklist.id)
        .toList();
    _checklists = <Checklist>[...without, storedChecklist];
    await _persistState();
    notifyListeners();
  }

  Future<void> removeChecklist(String id) async {
    _checklists =
        _checklists.where((Checklist checklist) => checklist.id != id).toList();
    await _persistState();
    notifyListeners();
  }

  Future<void> completeChecklist(String checklistId) async {
    final Checklist checklist = _checklists.firstWhere(
      (Checklist item) => item.id == checklistId,
    );
    _historyEntries = <ChecklistHistoryEntry>[
      ..._historyEntries,
      ChecklistHistoryEntry(
        id: generateId('history'),
        templateId: checklist.template.id,
        templateLabel: checklist.template.label,
        completedAt: _now().millisecondsSinceEpoch,
      ),
    ];
    _checklists =
        _checklists.where((Checklist item) => item.id != checklistId).toList();
    await _persistState();
    notifyListeners();
  }

  Future<void> toggleCheck(String checklistId, String checkboxId) async {
    _checklists = _checklists.map((Checklist checklist) {
      if (checklist.id != checklistId) {
        return checklist;
      }
      final List<Checkbox> newBoxes = checklist.checkboxes.map((Checkbox box) {
        if (box.id != checkboxId) {
          return box;
        }
        final CheckboxStatus newStatus = box.checked == CheckboxStatus.checked
            ? CheckboxStatus.unchecked
            : CheckboxStatus.checked;
        return box.copyWith(checked: newStatus);
      }).toList();
      return checklist.copyWith(checkboxes: newBoxes);
    }).toList();
    await _persistState();
    notifyListeners();
  }

  Future<void> addTemporaryCheckbox(
    String checklistId, {
    required String label,
  }) async {
    final String trimmedLabel = label.trim();
    if (trimmedLabel.isEmpty) {
      return;
    }

    _checklists = _checklists.map((Checklist checklist) {
      if (checklist.id != checklistId) {
        return checklist;
      }
      return checklist.copyWith(
        checkboxes: <Checkbox>[
          ...checklist.checkboxes,
          Checkbox(
            id: generateId('checkbox'),
            label: trimmedLabel,
            checked: CheckboxStatus.unchecked,
          ),
        ],
      );
    }).toList();
    await _persistState();
    notifyListeners();
  }

  Future<void> resetChecklist(String checklistId) async {
    _checklists = _checklists.map((Checklist checklist) {
      if (checklist.id != checklistId) {
        return checklist;
      }
      final List<Checkbox> reset = checklist.checkboxes
          .map(
            (Checkbox checkbox) => Checkbox(
              id: checkbox.id,
              taskId: checkbox.taskId,
              label: checkbox.label,
              checked: CheckboxStatus.unchecked,
            ),
          )
          .toList();
      return checklist.copyWith(checkboxes: reset);
    }).toList();
    await _persistState();
    notifyListeners();
  }

  ChecklistTemplate getTemplateById(String id) =>
      _templates.firstWhere((ChecklistTemplate template) => template.id == id);

  bool getTemplateExists(String id) =>
      _templates.any((ChecklistTemplate template) => template.id == id);

  bool isChecklistDone(String checklistId) {
    final Checklist checklist = _checklists.firstWhere(
      (Checklist item) => item.id == checklistId,
    );
    return !checklist.checkboxes.any(
      (Checkbox checkbox) => checkbox.checked == CheckboxStatus.unchecked,
    );
  }

  int completionCountForTemplate(String templateId) => _historyEntries
      .where((ChecklistHistoryEntry entry) => entry.templateId == templateId)
      .length;

  Future<bool> requestReminderPermissions() async {
    return _reminderService.requestPermissions();
  }

  ExportBundle createExportBundle() {
    return ExportBundle(
      date: _now().millisecondsSinceEpoch,
      templates: _templates.toList(),
      checklists: _checklists.toList(),
      historyEntries: _historyEntries.toList(),
    );
  }

  Future<void> replaceWithImportBundle(ExportBundle bundle) async {
    _templates = bundle.templates.toList();
    _checklists = bundle.checklists.toList();
    _historyEntries = bundle.historyEntries.toList();
    await _persistState(forceAutomaticBackup: true);
    await _reminderService.syncAllTemplateReminders(_templates);
    notifyListeners();
  }

  Future<void> setAutomaticBackupsEnabled(bool enabled) async {
    _automaticBackupsEnabled = enabled;
    await _backupPreferences.saveAutomaticBackupsEnabled(enabled);
    if (enabled) {
      await saveAutomaticBackupNow();
    }
    notifyListeners();
  }

  Future<void> saveAutomaticBackupNow() async {
    await _backupService.saveAutomaticBackup(_exportBundleJson(), force: true);
  }

  Future<List<ChecklistBackupEntry>> listAutomaticBackups() {
    return _backupService.listBackups();
  }

  Future<void> restoreAutomaticBackup(String backupId) async {
    final String backupJson = await _backupService.readBackup(backupId);
    final ExportBundle bundle = ExportBundle.fromJson(
      Map<String, dynamic>.from(jsonDecode(backupJson) as Map),
    );
    await replaceWithImportBundle(bundle);
  }

  Future<int> reconcileScheduledTemplates() async {
    final DateTime now = _now();
    final String todayKey = _dateKey(now);
    final List<ChecklistTemplate> dueTemplates = _templates.where((
      ChecklistTemplate template,
    ) {
      final DailyTemplateSchedule? schedule = template.dailySchedule;
      return schedule != null &&
          _isScheduleDue(schedule, now) &&
          schedule.lastInstantiatedOn != todayKey;
    }).toList();

    int instantiatedCount = 0;
    for (final ChecklistTemplate template in dueTemplates) {
      final Set<String> selectedOptionalStackIds =
          _selectedOptionalStackIdsForSchedule(template);
      final Checklist checklist = instantiateTemplateWithSelectedOptionalGroups(
        template,
        selectedOptionalStackIds: selectedOptionalStackIds,
      );
      await saveChecklist(checklist);

      final ChecklistTemplate refreshedTemplate = getTemplateById(template.id);
      final DailyTemplateSchedule? refreshedSchedule =
          refreshedTemplate.dailySchedule;
      if (refreshedSchedule == null) {
        continue;
      }

      await saveTemplate(
        refreshedTemplate.copyWith(
          dailySchedule: refreshedSchedule.copyWith(
            lastInstantiatedOn: todayKey,
          ),
        ),
      );
      instantiatedCount += 1;
    }

    return instantiatedCount;
  }

  ChecklistTemplate buildTemplate({
    required String templateId,
    required String templateName,
    required bool isFavorite,
    required List<String> taskLabels,
  }) {
    final List<Task> tasks = taskLabels.asMap().entries.map((
      MapEntry<int, String> entry,
    ) {
      return Task(id: generateId('task-${entry.key}'), label: entry.value);
    }).toList();

    final TaskStack stack = TaskStack(
      id: generateId('stack-1'),
      label: '',
      tasks: tasks,
    );

    return ChecklistTemplate(
      id: templateId,
      label: templateName,
      stacks: <TaskStack>[stack],
      favorite: isFavorite,
    );
  }

  Checklist instantiateTemplate(ChecklistTemplate template) {
    return instantiateTemplateWithSelectedOptionalGroups(
      template,
      selectedOptionalStackIds: <String>{
        for (final TaskStack stack in template.stacks.where(
          (TaskStack stack) =>
              stack.isOptional && stack.optionalDefaultIncluded,
        ))
          stack.id,
      },
    );
  }

  Checklist instantiateTemplateWithSelectedOptionalGroups(
    ChecklistTemplate template, {
    required Set<String> selectedOptionalStackIds,
  }) {
    final List<TaskStack> includedStacks = template.stacks.where((
      TaskStack stack,
    ) {
      if (!stack.isOptional) {
        return true;
      }
      return selectedOptionalStackIds.contains(stack.id);
    }).toList();

    final ChecklistTemplate instantiatedTemplate = template.copyWith(
      stacks: includedStacks,
    );

    final List<Checkbox> checkboxes = includedStacks.expand((TaskStack stack) {
      return stack.tasks.map((Task task) {
        return Checkbox(
          id: generateId('checkbox'),
          taskId: task.id,
          label: task.label,
          checked: CheckboxStatus.unchecked,
        );
      });
    }).toList();

    return Checklist(
      id: generateId('checklist'),
      template: instantiatedTemplate,
      checkboxes: checkboxes,
      timecreated: _now().millisecondsSinceEpoch,
    );
  }

  ChecklistTemplate makeLeavingHomeTemplate() => buildTemplate(
        templateId: generateId('exampletemplate-1'),
        templateName: 'Leaving home (example)',
        isFavorite: false,
        taskLabels: <String>['Keys', 'Wallet', 'Phone', 'Laptop', 'Gloves'],
      );

  ChecklistTemplate makeBeforeSleepTemplate() => buildTemplate(
        templateId: generateId('exampletemplate-2'),
        templateName: 'Before sleep (example)',
        isFavorite: false,
        taskLabels: <String>[
          'Dim lights',
          'Brush teeth',
          "Pack tomorrow's things",
          'Put aside the phone',
        ],
      );

  ChecklistTemplate makeBeforeSocialTemplate() => buildTemplate(
        templateId: generateId('exampletemplate-3'),
        templateName: 'Before social (example)',
        isFavorite: false,
        taskLabels: <String>[
          'Be mindful for a moment',
          'Relax tensions',
          'Think about the person(s)',
          'Picture them',
          'Find three touching points',
          'Be present',
        ],
      );

  void _syncActiveChecklistsForTemplate(ChecklistTemplate template) {
    _checklists = _checklists.map((Checklist checklist) {
      if (checklist.template.id != template.id) {
        return checklist;
      }
      return _syncChecklistToTemplate(checklist, template);
    }).toList();
  }

  Checklist _syncChecklistToTemplate(
    Checklist checklist,
    ChecklistTemplate template,
  ) {
    final Set<String> activeStackIds = <String>{
      for (final TaskStack stack in checklist.template.stacks) stack.id,
    };
    final List<TaskStack> syncedStacks = template.stacks.where((
      TaskStack stack,
    ) {
      if (!stack.isOptional) {
        return true;
      }
      return activeStackIds.contains(stack.id);
    }).toList();
    final ChecklistTemplate syncedTemplate = template.copyWith(
      stacks: syncedStacks,
    );
    final Map<String, Checkbox> checkboxByTaskId = <String, Checkbox>{};
    final List<Checkbox> temporaryCheckboxes = <Checkbox>[];
    final Iterable<Task> previousTasks = checklist.template.stacks.expand(
      (TaskStack stack) => stack.tasks,
    );

    for (final MapEntry<int, Task> entry
        in previousTasks.toList().asMap().entries) {
      if (entry.key >= checklist.checkboxes.length) {
        break;
      }
      checkboxByTaskId[entry.value.id] = checklist.checkboxes[entry.key];
    }

    for (final Checkbox box in checklist.checkboxes) {
      if (box.taskId != null) {
        checkboxByTaskId[box.taskId!] = box;
      } else {
        temporaryCheckboxes.add(box);
      }
    }

    final List<Checkbox> syncedCheckboxes =
        syncedStacks.expand((TaskStack stack) => stack.tasks).map((Task task) {
      final Checkbox? existing = checkboxByTaskId[task.id];
      if (existing != null) {
        return existing.copyWith(taskId: task.id, label: task.label);
      }
      return Checkbox(
        id: generateId('checkbox'),
        taskId: task.id,
        label: task.label,
        checked: CheckboxStatus.unchecked,
      );
    }).toList();

    return checklist.copyWith(
      template: syncedTemplate,
      checkboxes: <Checkbox>[
        ...syncedCheckboxes,
        ...temporaryCheckboxes,
      ],
    );
  }

  ChecklistTemplate _normalizeTemplateSchedule(ChecklistTemplate template) {
    final DailyTemplateSchedule? schedule = template.dailySchedule;
    if (schedule == null) {
      return template;
    }

    final Set<String> optionalStackIds = template.stacks
        .where((TaskStack stack) => stack.isOptional)
        .map((TaskStack stack) => stack.id)
        .toSet();

    final List<String> normalizedSelectedOptionalStackIds = schedule
        .selectedOptionalStackIds
        .where(optionalStackIds.contains)
        .toList();

    return template.copyWith(
      dailySchedule: schedule.copyWith(
        selectedOptionalStackIds: normalizedSelectedOptionalStackIds,
      ),
    );
  }

  Set<String> _selectedOptionalStackIdsForSchedule(ChecklistTemplate template) {
    final DailyTemplateSchedule? schedule = template.dailySchedule;
    if (schedule == null) {
      return const <String>{};
    }

    final Set<String> optionalStackIds = template.stacks
        .where((TaskStack stack) => stack.isOptional)
        .map((TaskStack stack) => stack.id)
        .toSet();

    return schedule.selectedOptionalStackIds
        .where(optionalStackIds.contains)
        .toSet();
  }

  bool _isScheduleDue(DailyTemplateSchedule schedule, DateTime now) {
    final DateTime scheduledTime = DateTime(
      now.year,
      now.month,
      now.day,
      schedule.hour,
      schedule.minute,
    );
    return !scheduledTime.isAfter(now);
  }

  String _dateKey(DateTime date) {
    final String month = date.month.toString().padLeft(2, '0');
    final String day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  Future<void> _persistState({bool forceAutomaticBackup = false}) async {
    final ExportBundle snapshot = createExportBundle();
    await StorageService.saveSnapshot(snapshot);
    if (_automaticBackupsEnabled) {
      await _backupService.saveAutomaticBackup(
        _exportBundleJson(snapshot),
        force: forceAutomaticBackup,
      );
    }
  }

  String _exportBundleJson([ExportBundle? bundle]) {
    return jsonEncode((bundle ?? createExportBundle()).toJson());
  }
}
