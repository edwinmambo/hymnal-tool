import 'package:flutter/material.dart';
import 'package:hymnal_tool/app_state.dart';
import 'package:hymnal_tool/data/app_database.dart';
import 'package:hymnal_tool/data/repositories.dart';
import 'package:hymnal_tool/screens/studio_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final database = AppDatabase();
  final state = HymnalAppState(
    songRepository: DriftSongRepository(database),
    setlistRepository: DriftSetlistRepository(database),
    themeRepository: DriftThemeRepository(database),
  );
  await state.initialize();
  runApp(HymnalToolApp(state: state));
}

class HymnalToolApp extends StatelessWidget {
  const HymnalToolApp({super.key, required this.state});

  final HymnalAppState state;

  @override
  Widget build(BuildContext context) => HymnalScope(
    notifier: state,
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Hymnal Tool',
      theme: buildAppTheme(),
      home: const StudioScreen(),
    ),
  );
}

class HymnalScope extends InheritedNotifier<HymnalAppState> {
  const HymnalScope({super.key, required super.notifier, required super.child});

  static HymnalAppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<HymnalScope>();
    assert(scope != null, 'No HymnalScope found in context');
    return scope!.notifier!;
  }
}

ThemeData buildAppTheme() {
  const seed = Color(0xff8c5545);
  final colors = ColorScheme.fromSeed(
    seedColor: seed,
    brightness: Brightness.light,
    surface: const Color(0xfffffaf4),
  );
  return ThemeData(
    colorScheme: colors,
    scaffoldBackgroundColor: const Color(0xfff7f1e9),
    useMaterial3: true,
    fontFamily: 'Georgia',
    fontFamilyFallback: const ['Noto Serif', 'Roboto'],
    textTheme: const TextTheme(
      displaySmall: TextStyle(fontWeight: FontWeight.w700, height: 1.05),
      headlineMedium: TextStyle(fontWeight: FontWeight.w700, height: 1.15),
      headlineSmall: TextStyle(fontWeight: FontWeight.w700),
      titleLarge: TextStyle(fontWeight: FontWeight.w700),
      titleMedium: TextStyle(fontWeight: FontWeight.w700),
      bodyLarge: TextStyle(height: 1.5),
      bodyMedium: TextStyle(height: 1.45),
    ),
    cardTheme: const CardThemeData(
      elevation: 0,
      color: Color(0xfffffdf9),
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(22)),
        side: BorderSide(color: Color(0x14000000)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colors.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0x16000000)),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      side: const BorderSide(color: Color(0x18000000)),
    ),
  );
}
