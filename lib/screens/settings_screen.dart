import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app_version.dart';
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

  Future<void> _openChangelog(BuildContext context) async {
    final bool didLaunch = await launchUrl(
      Uri.parse(kAppChangelogUrl),
      mode: LaunchMode.externalApplication,
    );
    if (!didLaunch && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open changelog.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        ScreenHeader(
          title: 'Settings',
          icon: const Icon(
            Icons.settings_outlined,
            size: AppSizes.iconMedium,
            color: AppColors.light,
          ),
          trailing: _VersionBadge(
            version: kAppVersionLabel,
            onTap: () => _openChangelog(context),
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
            children: [
              const Text(
                'Export data',
                style: TextStyle(
                  color: AppColors.light,
                  fontSize: AppSizes.textMinor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSizes.s),
              ElevatedButton(
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
                child: const Text(
                  'Export JSON',
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
            0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Import data',
                style: TextStyle(
                  color: AppColors.light,
                  fontSize: AppSizes.textMinor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSizes.s),
              ElevatedButton(
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
                child: const Text(
                  'Import JSON',
                  style: TextStyle(color: AppColors.white),
                ),
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
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Open changelog',
      child: InkWell(
        onTap: onTap,
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
