import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'services/local_notification_reminder_service.dart';
import 'state/app_state.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final appState = AppState(
    reminderService: LocalNotificationReminderService(),
  );
  await appState.init();
  await appState.reconcileScheduledTemplates();

  runApp(
    ChangeNotifierProvider.value(
      value: appState,
      child: const App(),
    ),
  );
}
