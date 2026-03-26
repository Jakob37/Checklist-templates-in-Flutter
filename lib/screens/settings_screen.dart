import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app_version.dart';
import '../models/export_bundle.dart';
import '../services/automatic_backup_service.dart';
import '../services/io_service.dart';
import '../state/app_state.dart';
import '../supabase_bootstrap.dart';
import '../theme/app_colors.dart';
import '../theme/app_sizes.dart';
import '../widgets/blue_panel.dart';
import '../widgets/screen_header.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Future<void> _openChangelog() async {
    final bool didLaunch = await launchUrl(
      Uri.parse(kAppChangelogUrl),
      mode: LaunchMode.externalApplication,
    );
    if (!didLaunch && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open changelog.')),
      );
    }
  }

  Future<void> _exportJson(AppState state) async {
    try {
      await IoService.exportJson(state.createExportBundle());
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Export successful')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: $error')),
      );
    }
  }

  Future<void> _importJson(AppState state) async {
    ExportBundle? result;
    try {
      result = await IoService.importJson();
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Import failed: $error')));
      return;
    }

    if (result == null || !mounted) {
      return;
    }

    final bool shouldImport = await _confirmAction(
      title: 'Import JSON',
      message:
          'Replace the current templates, actions, and history with this JSON file?',
      confirmLabel: 'Import',
    );
    if (!mounted || !shouldImport) {
      return;
    }

    await state.replaceWithImportBundle(result);
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('JSON imported successfully.')),
    );
  }

  Future<void> _toggleAutomaticBackups(AppState state, bool enabled) async {
    await state.setAutomaticBackupsEnabled(enabled);
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          enabled
              ? 'Automatic backups enabled. A fresh local snapshot was saved.'
              : 'Automatic backups disabled.',
        ),
      ),
    );
  }

  Future<void> _restoreAutomaticBackup(AppState state) async {
    final List<ChecklistBackupEntry> backups =
        await state.listAutomaticBackups();
    if (!mounted) {
      return;
    }

    if (backups.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('No automatic backups are available yet.')),
      );
      return;
    }

    final ChecklistBackupEntry? selectedBackup =
        await showModalBottomSheet<ChecklistBackupEntry>(
      context: context,
      builder: (BuildContext bottomSheetContext) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: <Widget>[
              const ListTile(
                title: Text(
                  'Restore Automatic Backup',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text('Choose a recent local JSON snapshot'),
              ),
              const Divider(height: 1),
              for (final ChecklistBackupEntry backup in backups)
                ListTile(
                  leading: const Icon(Icons.history_outlined),
                  title: Text(
                    _backupTimeLabel(bottomSheetContext, backup.savedAt),
                  ),
                  subtitle: Text(backup.fileName),
                  onTap: () => Navigator.of(bottomSheetContext).pop(backup),
                ),
            ],
          ),
        );
      },
    );

    if (!mounted || selectedBackup == null) {
      return;
    }

    final bool shouldRestore = await _confirmAction(
      title: 'Restore backup',
      message:
          'Restore "${selectedBackup.fileName}"? This replaces the current local data.',
      confirmLabel: 'Restore',
    );
    if (!mounted || !shouldRestore) {
      return;
    }

    await state.restoreAutomaticBackup(selectedBackup.id);
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Automatic backup restored. Current data was replaced.'),
      ),
    );
  }

  Future<bool> _confirmAction({
    required String title,
    required String message,
    required String confirmLabel,
  }) async {
    final bool? shouldProceed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.secondary,
          title: Text(title, style: const TextStyle(color: AppColors.light)),
          content: Text(
            message,
            style: const TextStyle(color: AppColors.light),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text(
                'Cancel',
                style: TextStyle(color: AppColors.faint),
              ),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(confirmLabel),
            ),
          ],
        );
      },
    );
    return shouldProceed ?? false;
  }

  String _backupTimeLabel(BuildContext context, DateTime savedAt) {
    final MaterialLocalizations localizations = MaterialLocalizations.of(
      context,
    );
    return '${localizations.formatFullDate(savedAt)} at '
        '${localizations.formatTimeOfDay(TimeOfDay.fromDateTime(savedAt))}';
  }

  @override
  Widget build(BuildContext context) {
    final AppState state = context.watch<AppState>();

    return ListView(
      children: <Widget>[
        ScreenHeader(
          title: 'Settings',
          icon: const Icon(
            Icons.settings_outlined,
            size: AppSizes.iconMedium,
            color: AppColors.light,
          ),
          trailing: _VersionBadge(
            version: kAppVersionLabel,
            onTap: _openChangelog,
          ),
        ),
        BluePanel(
          margin: const EdgeInsets.fromLTRB(
            AppSizes.s,
            AppSizes.s,
            AppSizes.s,
            0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                'Data backup',
                style: TextStyle(
                  color: AppColors.light,
                  fontSize: AppSizes.textMinor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSizes.s),
              ElevatedButton(
                key: const ValueKey<String>('export_json_button'),
                onPressed: () => _exportJson(state),
                child: const Text(
                  'Export JSON',
                  style: TextStyle(color: AppColors.white),
                ),
              ),
              const SizedBox(height: AppSizes.s),
              ElevatedButton(
                key: const ValueKey<String>('import_json_button'),
                onPressed: () => _importJson(state),
                child: const Text(
                  'Import JSON',
                  style: TextStyle(color: AppColors.white),
                ),
              ),
              const SizedBox(height: AppSizes.s),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Automatic JSON backups',
                  style: TextStyle(color: AppColors.light),
                ),
                subtitle: const Text(
                  'Keep up to 20 recent local snapshots and update them automatically.',
                  style: TextStyle(color: AppColors.faint),
                ),
                value: state.automaticBackupsEnabled,
                onChanged: (bool enabled) =>
                    _toggleAutomaticBackups(state, enabled),
              ),
              const SizedBox(height: AppSizes.s),
              ElevatedButton(
                onPressed: () => _restoreAutomaticBackup(state),
                child: const Text(
                  'Restore automatic backup',
                  style: TextStyle(color: AppColors.white),
                ),
              ),
            ],
          ),
        ),
        BluePanel(
          margin: const EdgeInsets.fromLTRB(
            AppSizes.s,
            AppSizes.s,
            AppSizes.s,
            AppSizes.s,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                'Cloud sync groundwork',
                style: TextStyle(
                  color: AppColors.light,
                  fontSize: AppSizes.textMinor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSizes.s),
              Text(
                SupabaseBootstrap.isConfigured
                    ? 'Supabase is configured for this build. Account and sync flows can be wired on top of this bootstrap next.'
                    : 'Supabase is not configured in this build yet. Launch with SUPABASE_URL and SUPABASE_ANON_KEY to enable the bootstrap later.',
                style: const TextStyle(color: AppColors.light),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _VersionBadge extends StatelessWidget {
  const _VersionBadge({required this.version, required this.onTap});

  final String version;
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Open changelog',
      child: InkWell(
        onTap: () {
          onTap();
        },
        borderRadius: BorderRadius.circular(AppSizes.borderRadius),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.s,
            vertical: AppSizes.xs,
          ),
          decoration: BoxDecoration(
            color: AppColors.primary,
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(AppSizes.borderRadius),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                version,
                style: const TextStyle(
                  color: AppColors.light,
                  fontSize: AppSizes.textSub,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.open_in_new,
                size: 14,
                color: AppColors.light,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
