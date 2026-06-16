import 'package:flutter/material.dart';
import 'package:jump_counter/screens/jump_counter_screen.dart';
import 'package:jump_counter/services/background_service.dart';

// Notificador global para alternar entre temas en tiempo real
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeBackgroundService();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, ThemeMode currentMode, __) {
        return MaterialApp(
          title: 'Contador de Saltos',
          themeMode: currentMode,
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF1A73E8),
              brightness: Brightness.light,
            ),
            scaffoldBackgroundColor: const Color(0xFFF8F9FA),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF1A73E8),
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            visualDensity: VisualDensity.adaptivePlatformDensity,
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF00E5FF),
              brightness: Brightness.dark,
            ),
            scaffoldBackgroundColor: const Color(0xFF121212),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF1C1C1E),
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            visualDensity: VisualDensity.adaptivePlatformDensity,
          ),
          home: const JumpCounterScreen(),
        );
      },
    );
  }
}
