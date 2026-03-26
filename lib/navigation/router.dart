import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../screens/templates_screen.dart';
import '../screens/make_template_screen.dart';
import '../screens/checklists_screen.dart';
import '../screens/settings_screen.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_sizes.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/templates',
  routes: [
    GoRoute(
      path: '/settings',
      builder: (context, state) => const _SettingsPage(),
    ),
    ShellRoute(
      builder: (context, state, child) => MainShell(child: child),
      routes: [
        GoRoute(
          path: '/templates',
          builder: (context, state) => const TemplatesScreen(),
          routes: [
            GoRoute(
              path: 'edit',
              builder: (context, state) {
                final templateId = state.uri.queryParameters['templateId'];
                final isNew = state.uri.queryParameters['isNew'] == 'true';
                final syncActiveChecklists =
                    state.uri.queryParameters['syncActiveChecklists'] == 'true';
                return MakeTemplateScreen(
                  templateId: templateId,
                  isNew: isNew,
                  syncActiveChecklists: syncActiveChecklists,
                );
              },
            ),
          ],
        ),
        GoRoute(
          path: '/checklists',
          builder: (context, state) => const ChecklistsScreen(),
        ),
      ],
    ),
  ],
);

class MainShell extends StatelessWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  int _locationToIndex(String location) {
    if (location.startsWith('/checklists')) return 1;
    return 0;
  }

  String _titleForLocation(String location) {
    if (location.startsWith('/checklists')) return 'Actions';
    return 'Templates';
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final index = _locationToIndex(location);
    final showBottomNav = !location.startsWith('/templates/edit');

    if (!showBottomNav) {
      return Scaffold(body: SafeArea(child: child));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_titleForLocation(location)),
        actions: <Widget>[
          IconButton(
            tooltip: 'Settings',
            onPressed: () => context.push('/settings'),
            icon: const FaIcon(
              FontAwesomeIcons.gear,
              size: AppSizes.iconMedium,
            ),
          ),
        ],
      ),
      body: SafeArea(child: child),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) {
          switch (i) {
            case 0:
              context.go('/templates');
              break;
            case 1:
              context.go('/checklists');
              break;
          }
        },
        destinations: const [
          NavigationDestination(
            icon: FaIcon(FontAwesomeIcons.list, size: AppSizes.iconMedium),
            label: 'Templates',
          ),
          NavigationDestination(
            icon: _ChecklistNavIcon(),
            label: 'Actions',
          ),
        ],
      ),
    );
  }
}

class _SettingsPage extends StatelessWidget {
  const _SettingsPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: const SafeArea(child: SettingsScreen()),
    );
  }
}

class _ChecklistNavIcon extends StatelessWidget {
  const _ChecklistNavIcon();

  @override
  Widget build(BuildContext context) {
    final checklistCount = context.watch<AppState>().checklists.length;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        const FaIcon(
          FontAwesomeIcons.squareCheck,
          size: AppSizes.iconMedium,
        ),
        if (checklistCount > 0)
          Positioned(
            top: -8,
            right: -12,
            child: Container(
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              decoration: const BoxDecoration(
                color: AppColors.highlight2,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                '$checklistCount',
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
