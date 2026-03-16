// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme.dart';
import 'core/router.dart';
import 'providers/auth_provider.dart';

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
    return ChangeNotifierProvider.value(
      value: auth,
      child: Builder(
        builder: (context) {
          final router = buildRouter(
            context.watch<AuthProvider>(),
          );
          return MaterialApp.router(
            title: 'CoachTrack',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            routerConfig: router,
          );
        },
      ),
    );
  }
}
