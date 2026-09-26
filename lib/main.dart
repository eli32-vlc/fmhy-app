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
        theme: ThemeData(
          colorSchemeSeed: Colors.indigo,
          useMaterial3: true,
        ),
        home: const MainScreen(),
      ),
    );
  }
}
