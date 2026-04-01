import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'navigation/router.dart';
import 'state/app_state.dart';
import 'theme/app_theme.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> with WidgetsBindingObserver {
  bool _isReconciling = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _reconcileSchedules();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _reconcileSchedules();
    }
  }

  Future<void> _reconcileSchedules() async {
    if (_isReconciling || !mounted) return;

    _isReconciling = true;
    try {
      await context.read<AppState>().reconcileScheduledTemplates();
    } finally {
      _isReconciling = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Checklist templates',
      theme: buildAppTheme(),
      routerConfig: appRouter,
    );
  }
}
