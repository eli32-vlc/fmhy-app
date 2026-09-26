import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/main_screen.dart';
import 'services/fm_data_service.dart';
import 'services/fm_favorites_service.dart';
import 'services/fm_history_service.dart';

void main() {
  runApp(const FMApp());
}

class FMApp extends StatelessWidget {
  const FMApp({super.key});

  static const _seed = Color(0xFF4F46E5);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => FMDataService()),
        ChangeNotifierProvider(create: (_) => FMFavoritesService()),
        ChangeNotifierProvider(create: (_) => FMHistoryService()),
      ],
      child: MaterialApp(
        title: 'FMHY X',
        debugShowCheckedModeBanner: false,
        themeMode: ThemeMode.system,
        theme: _theme(Brightness.light),
        darkTheme: _theme(Brightness.dark),
        home: const MainScreen(),
      ),
    );
  }

  static ThemeData _theme(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: brightness,
    );
    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 2,
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        space: 1,
        thickness: 1,
      ),
      searchBarTheme: SearchBarThemeData(
        backgroundColor: WidgetStatePropertyAll(scheme.surfaceContainerHigh),
        elevation: const WidgetStatePropertyAll(0),
        side: WidgetStatePropertyAll(
          BorderSide(color: scheme.outlineVariant),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: TextStyle(color: scheme.onInverseSurface),
      ),
      dialogTheme: DialogThemeData(backgroundColor: scheme.surfaceContainerHigh),
      cardTheme: CardThemeData(
        color: scheme.surfaceContainerHigh,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
