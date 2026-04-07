import 'package:checklist_templates_flutter/models/checklist.dart';
import 'package:checklist_templates_flutter/models/checklist_template.dart';
import 'package:checklist_templates_flutter/state/app_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('saving a template can sync active checklists', () async {
    final state = AppState();
    final template = state.buildTemplate(
      templateId: 'template-1',
      templateName: 'Morning',
      isFavorite: false,
      taskLabels: ['Keys', 'Wallet'],
    );

    await state.saveTemplate(template);

    final checklist = state.instantiateTemplate(template);
    await state.saveChecklist(checklist);
    await state.toggleCheck(checklist.id, checklist.checkboxes.first.id);

    final updatedTemplate = ChecklistTemplate(
      id: template.id,
      label: template.label,
      favorite: template.favorite,
      stacks: [
        TaskStack(
          id: template.stacks.first.id,
          label: template.stacks.first.label,
          tasks: [
            template.stacks.first.tasks.first.copyWith(label: 'House keys'),
            Task(id: 'task-3', label: 'Phone'),
          ],
        ),
      ],
    );

    await state.saveTemplate(
      updatedTemplate,
      syncActiveChecklists: true,
    );

    final syncedChecklist = state.checklists.single;

    expect(
      syncedChecklist.checkboxes.map((box) => box.label).toList(),
      ['House keys', 'Phone'],
    );
    expect(
      syncedChecklist.checkboxes.map((box) => box.checked).toList(),
      [CheckboxStatus.checked, CheckboxStatus.unchecked],
    );
    expect(syncedChecklist.template.label, 'Morning');
  });

  test('completing a checklist stores template history', () async {
    final state = AppState();
    final template = state.buildTemplate(
      templateId: 'template-2',
      templateName: 'Evening',
      isFavorite: false,
      taskLabels: ['Doors', 'Lights'],
    );

    await state.saveTemplate(template);

    final checklist = state.instantiateTemplate(template);
    await state.saveChecklist(checklist);
    await state.toggleCheck(checklist.id, checklist.checkboxes.first.id);
    await state.toggleCheck(checklist.id, checklist.checkboxes.last.id);
    await state.completeChecklist(checklist.id);

    expect(state.checklists, isEmpty);
    expect(state.getTemplateById(template.id).usageCount, 1);
    expect(state.completionCountForTemplate(template.id), 1);
    expect(state.historyEntries.single.templateLabel, 'Evening');
  });

  test('saving a new checklist increments the template usage count', () async {
    final state = AppState();
    final template = state.buildTemplate(
      templateId: 'template-usage',
      templateName: 'Lunch',
      isFavorite: false,
      taskLabels: ['Food'],
    );

    await state.saveTemplate(template);

    final checklist = state.instantiateTemplate(template);
    await state.saveChecklist(checklist);

    expect(state.getTemplateById(template.id).usageCount, 1);
    expect(state.checklists.single.template.usageCount, 1);
  });

  test('templates are sorted by favorite, then usage count, then label',
      () async {
    final state = AppState();
    final templates = [
      ChecklistTemplate(
        id: 'template-b',
        label: 'Beta',
        favorite: false,
        usageCount: 2,
        stacks: const [],
      ),
      ChecklistTemplate(
        id: 'template-a',
        label: 'Alpha',
        favorite: false,
        usageCount: 2,
        stacks: const [],
      ),
      ChecklistTemplate(
        id: 'template-fav-low',
        label: 'Fav low',
        favorite: true,
        usageCount: 1,
        stacks: const [],
      ),
      ChecklistTemplate(
        id: 'template-fav-high',
        label: 'Fav high',
        favorite: true,
        usageCount: 3,
        stacks: const [],
      ),
    ];

    await state.saveNewTemplates(templates);

    expect(
      state.sortedTemplates.map((template) => template.id).toList(),
      ['template-fav-high', 'template-fav-low', 'template-a', 'template-b'],
    );
  });

  test('saving a grouped template syncs active checklist sections by task id',
      () async {
    final state = AppState();
    final template = ChecklistTemplate(
      id: 'template-3',
      label: 'Photo walk',
      favorite: false,
      stacks: [
        TaskStack(
          id: 'stack-main',
          label: '',
          tasks: [
            Task(id: 'task-wallet', label: 'Wallet'),
          ],
        ),
        TaskStack(
          id: 'stack-rain',
          label: 'Is it rainy?',
          tasks: [
            Task(id: 'task-raincover', label: 'Raincover'),
            Task(id: 'task-lenscloth', label: 'Lens cloth'),
          ],
        ),
      ],
    );

    await state.saveTemplate(template);

    final checklist = state.instantiateTemplate(template);
    await state.saveChecklist(checklist);
    await state.toggleCheck(checklist.id, checklist.checkboxes[1].id);

    final updatedTemplate = ChecklistTemplate(
      id: template.id,
      label: template.label,
      favorite: template.favorite,
      stacks: [
        template.stacks.first,
        TaskStack(
          id: 'stack-rain',
          label: 'Is it rainy?',
          tasks: [
            Task(id: 'task-raincover', label: 'Rain cover'),
            Task(id: 'task-camera-rain', label: 'Camera for rain photography'),
          ],
        ),
      ],
    );

    await state.saveTemplate(updatedTemplate, syncActiveChecklists: true);

    final syncedChecklist = state.checklists.single;

    expect(
      syncedChecklist.checkboxes.map((box) => box.label).toList(),
      ['Wallet', 'Rain cover', 'Camera for rain photography'],
    );
    expect(
      syncedChecklist.checkboxes.map((box) => box.checked).toList(),
      [
        CheckboxStatus.unchecked,
        CheckboxStatus.checked,
        CheckboxStatus.unchecked,
      ],
    );
    expect(
      syncedChecklist.checkboxes.map((box) => box.taskId).toList(),
      ['task-wallet', 'task-raincover', 'task-camera-rain'],
    );
  });

  test('resetting a checklist keeps task ids for grouped templates', () async {
    final state = AppState();
    final template = ChecklistTemplate(
      id: 'template-4',
      label: 'Trip prep',
      favorite: false,
      stacks: [
        TaskStack(
          id: 'stack-conditions',
          label: 'Is it rainy?',
          tasks: [
            Task(id: 'task-jacket', label: 'Rain jacket'),
            Task(id: 'task-cover', label: 'Rain cover'),
          ],
        ),
      ],
    );

    await state.saveTemplate(template);

    final checklist = state.instantiateTemplate(template);
    await state.saveChecklist(checklist);
    await state.toggleCheck(checklist.id, checklist.checkboxes.first.id);
    await state.resetChecklist(checklist.id);

    final resetChecklist = state.checklists.single;

    expect(
      resetChecklist.checkboxes.map((box) => box.taskId).toList(),
      ['task-jacket', 'task-cover'],
    );
    expect(
      resetChecklist.checkboxes.every(
        (box) => box.checked == CheckboxStatus.unchecked,
      ),
      isTrue,
    );
  });

  test('instantiating a template can exclude optional groups', () async {
    final state = AppState();
    final template = ChecklistTemplate(
      id: 'template-5',
      label: 'Trip prep',
      favorite: false,
      stacks: [
        TaskStack(
          id: 'stack-required',
          label: 'Always',
          tasks: [
            Task(id: 'task-wallet', label: 'Wallet'),
          ],
        ),
        TaskStack(
          id: 'stack-optional',
          label: 'Rainy weather',
          isOptional: true,
          tasks: [
            Task(id: 'task-jacket', label: 'Rain jacket'),
          ],
        ),
      ],
    );

    final checklist = state.instantiateTemplateWithSelectedOptionalGroups(
      template,
      selectedOptionalStackIds: const {},
    );

    expect(checklist.template.stacks.map((stack) => stack.id).toList(), [
      'stack-required',
    ]);
    expect(
      checklist.checkboxes.map((box) => box.taskId).toList(),
      ['task-wallet'],
    );
  });

  test('instantiating a template uses optional group defaults', () async {
    final state = AppState();
    final template = ChecklistTemplate(
      id: 'template-5b',
      label: 'Trip prep',
      favorite: false,
      stacks: [
        TaskStack(
          id: 'stack-required',
          label: 'Always',
          tasks: [
            Task(id: 'task-wallet', label: 'Wallet'),
          ],
        ),
        TaskStack(
          id: 'stack-default-on',
          label: 'Rainy weather',
          isOptional: true,
          optionalDefaultIncluded: true,
          tasks: [
            Task(id: 'task-jacket', label: 'Rain jacket'),
          ],
        ),
        TaskStack(
          id: 'stack-default-off',
          label: 'Gym stop',
          isOptional: true,
          optionalDefaultIncluded: false,
          tasks: [
            Task(id: 'task-shoes', label: 'Gym shoes'),
          ],
        ),
      ],
    );

    final checklist = state.instantiateTemplate(template);

    expect(checklist.template.stacks.map((stack) => stack.id).toList(), [
      'stack-required',
      'stack-default-on',
    ]);
    expect(
      checklist.checkboxes.map((box) => box.taskId).toList(),
      ['task-wallet', 'task-jacket'],
    );
  });

  test('syncing an active checklist keeps omitted optional groups omitted',
      () async {
    final state = AppState();
    final template = ChecklistTemplate(
      id: 'template-6',
      label: 'Trip prep',
      favorite: false,
      stacks: [
        TaskStack(
          id: 'stack-required',
          label: 'Always',
          tasks: [
            Task(id: 'task-wallet', label: 'Wallet'),
          ],
        ),
        TaskStack(
          id: 'stack-optional',
          label: 'Rainy weather',
          isOptional: true,
          tasks: [
            Task(id: 'task-jacket', label: 'Rain jacket'),
          ],
        ),
      ],
    );

    await state.saveTemplate(template);

    final checklist = state.instantiateTemplateWithSelectedOptionalGroups(
      template,
      selectedOptionalStackIds: const {},
    );
    await state.saveChecklist(checklist);

    final updatedTemplate = template.copyWith(
      stacks: [
        template.stacks.first.copyWith(
          tasks: [
            Task(id: 'task-wallet', label: 'House wallet'),
            Task(id: 'task-phone', label: 'Phone'),
          ],
        ),
        template.stacks.last.copyWith(
          tasks: [
            Task(id: 'task-jacket', label: 'Rain jacket'),
            Task(id: 'task-cover', label: 'Bag cover'),
          ],
        ),
      ],
    );

    await state.saveTemplate(updatedTemplate, syncActiveChecklists: true);

    final syncedChecklist = state.checklists.single;

    expect(syncedChecklist.template.stacks.map((stack) => stack.id).toList(), [
      'stack-required',
    ]);
    expect(
      syncedChecklist.checkboxes.map((box) => box.taskId).toList(),
      ['task-wallet', 'task-phone'],
    );
  });

  test('temporary checklist tasks can be added without changing the template',
      () async {
    final state = AppState();
    final template = state.buildTemplate(
      templateId: 'template-temp',
      templateName: 'Trip prep',
      isFavorite: false,
      taskLabels: ['Wallet'],
    );

    await state.saveTemplate(template);

    final checklist = state.instantiateTemplate(template);
    await state.saveChecklist(checklist);
    await state.addTemporaryCheckbox(
      checklist.id,
      label: 'Passport',
    );

    final updatedChecklist = state.checklists.single;

    expect(
      updatedChecklist.checkboxes.map((box) => box.label).toList(),
      ['Wallet', 'Passport'],
    );
    expect(
      updatedChecklist.checkboxes.map((box) => box.taskId).toList(),
      [template.stacks.first.tasks.first.id, null],
    );
    expect(state.getTemplateById(template.id).taskCount, 1);
  });

  test('temporary checklist tasks survive template sync and reset', () async {
    final state = AppState();
    final template = state.buildTemplate(
      templateId: 'template-temp-sync',
      templateName: 'Trip prep',
      isFavorite: false,
      taskLabels: ['Wallet'],
    );

    await state.saveTemplate(template);

    final checklist = state.instantiateTemplate(template);
    await state.saveChecklist(checklist);
    await state.addTemporaryCheckbox(
      checklist.id,
      label: 'Passport',
    );
    await state.toggleCheck(
        checklist.id, state.checklists.single.checkboxes[1].id);

    final updatedTemplate = ChecklistTemplate(
      id: template.id,
      label: template.label,
      favorite: template.favorite,
      stacks: [
        TaskStack(
          id: template.stacks.first.id,
          label: template.stacks.first.label,
          tasks: [
            Task(
              id: template.stacks.first.tasks.first.id,
              label: 'House wallet',
            ),
            Task(id: 'task-phone', label: 'Phone'),
          ],
        ),
      ],
    );

    await state.saveTemplate(updatedTemplate, syncActiveChecklists: true);

    var syncedChecklist = state.checklists.single;
    expect(
      syncedChecklist.checkboxes.map((box) => box.label).toList(),
      ['House wallet', 'Phone', 'Passport'],
    );
    expect(
      syncedChecklist.checkboxes.map((box) => box.taskId).toList(),
      [template.stacks.first.tasks.first.id, 'task-phone', null],
    );
    expect(
      syncedChecklist.checkboxes.last.checked,
      CheckboxStatus.checked,
    );

    await state.resetChecklist(syncedChecklist.id);
    syncedChecklist = state.checklists.single;
    expect(
      syncedChecklist.checkboxes.map((box) => box.label).toList(),
      ['House wallet', 'Phone', 'Passport'],
    );
    expect(
      syncedChecklist.checkboxes.every(
        (box) => box.checked == CheckboxStatus.unchecked,
      ),
      isTrue,
    );
  });

  test('scheduled templates auto-instantiate once per day after the set time',
      () async {
    var now = DateTime(2026, 3, 18, 9, 30);
    final state = AppState(now: () => now);
    final template = ChecklistTemplate(
      id: 'template-7',
      label: 'Morning',
      favorite: false,
      stacks: [
        TaskStack(
          id: 'stack-main',
          label: '',
          tasks: [
            Task(id: 'task-keys', label: 'Keys'),
          ],
        ),
      ],
      dailySchedule: DailyTemplateSchedule(
        hour: 9,
        minute: 0,
      ),
    );

    await state.saveTemplate(template);

    expect(await state.reconcileScheduledTemplates(), 1);
    expect(await state.reconcileScheduledTemplates(), 0);
    expect(state.checklists, hasLength(1));
    expect(
      state.getTemplateById(template.id).dailySchedule?.lastInstantiatedOn,
      '2026-03-18',
    );

    now = DateTime(2026, 3, 19, 9, 1);

    expect(await state.reconcileScheduledTemplates(), 1);
    expect(state.checklists, hasLength(2));
  });

  test('scheduled templates honor saved optional group selection', () async {
    final state = AppState(now: () => DateTime(2026, 3, 18, 9, 30));
    final template = ChecklistTemplate(
      id: 'template-8',
      label: 'Trip prep',
      favorite: false,
      stacks: [
        TaskStack(
          id: 'stack-required',
          label: 'Always',
          tasks: [
            Task(id: 'task-wallet', label: 'Wallet'),
          ],
        ),
        TaskStack(
          id: 'stack-rain',
          label: 'Rainy weather',
          isOptional: true,
          tasks: [
            Task(id: 'task-jacket', label: 'Rain jacket'),
          ],
        ),
      ],
      dailySchedule: DailyTemplateSchedule(
        hour: 9,
        minute: 0,
        selectedOptionalStackIds: const [],
      ),
    );

    await state.saveTemplate(template);
    await state.reconcileScheduledTemplates();

    final checklist = state.checklists.single;

    expect(checklist.template.stacks.map((stack) => stack.id).toList(), [
      'stack-required',
    ]);
    expect(
      checklist.checkboxes.map((box) => box.taskId).toList(),
      ['task-wallet'],
    );
  });
}
