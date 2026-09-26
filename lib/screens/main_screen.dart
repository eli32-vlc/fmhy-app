import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'browse_screen.dart';
import 'favorites_screen.dart';
import 'history_screen.dart';
import 'settings_screen.dart';
import '../services/fm_data_service.dart';
import '../services/fm_favorites_service.dart';
import '../services/fm_history_service.dart';

/// Root scaffold holding the four tabs, matching the Swift `MainTabView`.
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    final data = context.read<FMDataService>();
    context.read<FMFavoritesService>().load();
    context.read<FMHistoryService>().load();
    data.init();
  }

  @override
  Widget build(BuildContext context) {
    final screens = const [
      BrowseScreen(),
      HistoryScreen(),
      FavoritesScreen(),
      SettingsScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Browse',
          ),
          NavigationDestination(
            icon: Icon(Icons.history),
            label: 'Recent',
          ),
          NavigationDestination(
            icon: Icon(Icons.star_border),
            selectedIcon: Icon(Icons.star),
            label: 'Favorites',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
