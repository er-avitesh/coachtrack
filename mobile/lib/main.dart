// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme.dart';
import 'core/router.dart';
import 'core/constants.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final auth = AuthProvider();
  await auth.initialize();
  runApp(CoachTrackApp(auth: auth));
}

class CoachTrackApp extends StatelessWidget {
  final AuthProvider auth;
  const CoachTrackApp({super.key, required this.auth});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: auth),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const _AppView(),
    );
  }
}

class _AppView extends StatelessWidget {
  const _AppView();

  @override
  Widget build(BuildContext context) {
    final auth   = context.watch<AuthProvider>();
    final theme  = context.watch<ThemeProvider>();
    final router = buildRouter(auth);
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        children: [
          MaterialApp.router(
            title: 'CoachTrack',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: theme.isDark ? ThemeMode.dark : ThemeMode.light,
            routerConfig: router,
          ),
          Positioned(
            bottom: 6,
            right: 10,
            child: Text(
              'v${AppConstants.version}',
              style: const TextStyle(fontSize: 10, color: Color(0x44000000)),
            ),
          ),
        ],
      ),
    );
  }
}
