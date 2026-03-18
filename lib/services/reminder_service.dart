import '../models/checklist_template.dart';

abstract class ReminderService {
  Future<void> init();
  Future<bool> requestPermissions();
  Future<void> syncAllTemplateReminders(List<ChecklistTemplate> templates);
  Future<void> syncTemplateReminder(ChecklistTemplate template);
  Future<void> cancelTemplateReminder(String templateId);
}

class NoOpReminderService implements ReminderService {
  const NoOpReminderService();

  @override
  Future<void> init() async {}

  @override
  Future<bool> requestPermissions() async => true;

  @override
  Future<void> syncAllTemplateReminders(
      List<ChecklistTemplate> templates) async {}

  @override
  Future<void> syncTemplateReminder(ChecklistTemplate template) async {}

  @override
  Future<void> cancelTemplateReminder(String templateId) async {}
}
