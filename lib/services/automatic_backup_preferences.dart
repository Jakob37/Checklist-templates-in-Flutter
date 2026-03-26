import 'package:shared_preferences/shared_preferences.dart';

class ChecklistBackupPreferences {
  const ChecklistBackupPreferences();

  static const String _automaticBackupsEnabledKey =
      'checklist_templates.automatic_json_backups_enabled';

  Future<bool> loadAutomaticBackupsEnabled() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_automaticBackupsEnabledKey) ?? false;
  }

  Future<void> saveAutomaticBackupsEnabled(bool enabled) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_automaticBackupsEnabledKey, enabled);
  }
}
