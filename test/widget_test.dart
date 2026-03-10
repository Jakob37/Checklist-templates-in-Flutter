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
}
