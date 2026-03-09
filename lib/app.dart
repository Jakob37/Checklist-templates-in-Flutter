import 'package:flutter/material.dart';
import 'navigation/router.dart';
import 'theme/app_theme.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Checklist Templates',
      theme: buildAppTheme(),
      routerConfig: appRouter,
    );
  }
}
