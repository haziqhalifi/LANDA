import 'package:flutter/material.dart';
import 'package:disaster_resilience_ai/ui/auth_page.dart';
import 'package:disaster_resilience_ai/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final isDarkMode = await AppThemeController.loadInitialDarkMode();
  runApp(DisasterResilienceApp(initialDarkMode: isDarkMode));
}

class DisasterResilienceApp extends StatefulWidget {
  const DisasterResilienceApp({super.key, required this.initialDarkMode});

  final bool initialDarkMode;

  @override
  State<DisasterResilienceApp> createState() => _DisasterResilienceAppState();
}

class _DisasterResilienceAppState extends State<DisasterResilienceApp> {
  late final AppThemeController _themeController = AppThemeController(
    isDarkMode: widget.initialDarkMode,
  );

  @override
  void dispose() {
    _themeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppThemeScope(
      controller: _themeController,
      child: AnimatedBuilder(
        animation: _themeController,
        builder: (context, _) {
          return MaterialApp(
            title: 'Disaster Resilience AI',
            debugShowCheckedModeBanner: false,
            theme: AppThemes.lightTheme(),
            darkTheme: AppThemes.darkTheme(),
            themeMode: _themeController.themeMode,
            home: const AuthPage(),
          );
        },
      ),
    );
  }
}
