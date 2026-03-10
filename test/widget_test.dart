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
    expect(state.completionCountForTemplate(template.id), 1);
    expect(state.historyEntries.single.templateLabel, 'Evening');
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
}
