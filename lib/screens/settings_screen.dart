import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/export_bundle.dart';
import '../services/io_service.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_sizes.dart';
import '../widgets/blue_panel.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/screen_header.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const ScreenHeader(
          title: 'Settings',
          subtitle: 'Export, import, and manage your checklist data.',
          icon: Icon(
            Icons.settings_outlined,
            size: AppSizes.iconMedium,
            color: AppColors.light,
          ),
          trailing: _VersionBadge(version: 'v1.0.0'),
        ),
        BluePanel(
          margin:
              const EdgeInsets.fromLTRB(AppSizes.s, AppSizes.s, AppSizes.s, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Export data',
                style: TextStyle(
                  color: AppColors.light,
                  fontSize: AppSizes.textMinor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSizes.xs),
              const Text(
                'Save your templates and ongoing checklists as a JSON backup file.',
                style: TextStyle(
                    color: AppColors.light, fontSize: AppSizes.textSub),
              ),
              const SizedBox(height: AppSizes.s),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.highlight1),
                onPressed: () async {
                  final state = context.read<AppState>();
                  final bundle = ExportBundle(
                    date: DateTime.now().millisecondsSinceEpoch,
                    templates: state.templates.toList(),
                    checklists: state.checklists.toList(),
                  );
                  try {
                    await IoService.exportJson(bundle);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Export successful')),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Export failed: $e')),
                      );
                    }
                  }
                },
                child: const Text('Export data as JSON',
                    style: TextStyle(color: AppColors.white)),
              ),
            ],
          ),
        ),
        BluePanel(
          margin:
              const EdgeInsets.fromLTRB(AppSizes.s, AppSizes.s, AppSizes.s, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Import data',
                style: TextStyle(
                  color: AppColors.light,
                  fontSize: AppSizes.textMinor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSizes.xs),
              const Text(
                'Import templates from an exported JSON file. Existing data stays in place, and duplicates are skipped.',
                style: TextStyle(
                    color: AppColors.light, fontSize: AppSizes.textSub),
              ),
              const SizedBox(height: AppSizes.s),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.highlight1),
                onPressed: () async {
                  ExportBundle? result;
                  try {
                    result = await IoService.importJson();
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Import failed: $e')),
                      );
                    }
                    return;
                  }

                  if (result == null || !context.mounted) return;

                  final state = context.read<AppState>();
                  final newTemplates = result.templates
                      .where((t) => !state.getTemplateExists(t.id))
                      .toList();
                  final nbrExists =
                      result.templates.length - newTemplates.length;
                  final s = newTemplates.length != 1 ? 's' : '';
                  final alreadyExistsStr =
                      nbrExists > 0 ? ' ($nbrExists already exists)' : '';

                  if (newTemplates.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('No new templates found')),
                    );
                    return;
                  }

                  showConfirmDialog(
                    context: context,
                    title: 'Import JSON',
                    message:
                        'Import ${newTemplates.length} checklist template$s?$alreadyExistsStr',
                    onConfirm: () => state.saveNewTemplates(newTemplates),
                  );
                },
                child: const Text('Import data',
                    style: TextStyle(color: AppColors.white)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _VersionBadge extends StatelessWidget {
  final String version;

  const _VersionBadge({required this.version});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.s,
        vertical: AppSizes.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppSizes.borderRadius),
      ),
      child: Text(
        version,
        style: const TextStyle(
          color: AppColors.light,
          fontSize: AppSizes.textSub,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
