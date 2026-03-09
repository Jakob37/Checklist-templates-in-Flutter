import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import '../screens/templates_screen.dart';
import '../screens/make_template_screen.dart';
import '../screens/checklists_screen.dart';
import '../screens/settings_screen.dart';
import '../theme/app_sizes.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/templates',
  routes: [
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
                return MakeTemplateScreen(
                    templateId: templateId, isNew: isNew);
              },
            ),
          ],
        ),
        GoRoute(
          path: '/checklists',
          builder: (context, state) => const ChecklistsScreen(),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsScreen(),
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
    if (location.startsWith('/settings')) return 2;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final index = _locationToIndex(location);

    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: index,
        onTap: (i) {
          switch (i) {
            case 0:
              context.go('/templates');
              break;
            case 1:
              context.go('/checklists');
              break;
            case 2:
              context.go('/settings');
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: FaIcon(FontAwesomeIcons.list, size: AppSizes.iconMedium),
            label: 'Templates',
          ),
          BottomNavigationBarItem(
            icon: FaIcon(FontAwesomeIcons.squareCheck,
                size: AppSizes.iconMedium),
            label: 'Checklists',
          ),
          BottomNavigationBarItem(
            icon: FaIcon(FontAwesomeIcons.gear, size: AppSizes.iconMedium),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
