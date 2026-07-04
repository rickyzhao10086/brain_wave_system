import 'package:flutter/material.dart';

import '../screens/analysis.dart';
import '../screens/home.dart';
import '../screens/model.dart';
import '../screens/profile.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;

  static const _screens = [
    HomeScreen(),
    AnalysisScreen(),
    ModelScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: NavigationBar(
        height: 66,
        backgroundColor: const Color(0xff090a13),
        indicatorColor: const Color(0xff1c2440),
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.sensors_rounded, size: 20),
            label: 'Device',
          ),
          NavigationDestination(
            icon: Icon(Icons.analytics_rounded, size: 20),
            label: 'Signals',
          ),
          NavigationDestination(
            icon: Icon(Icons.memory_rounded, size: 20),
            label: 'Model',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_rounded, size: 20),
            label: 'Setup',
          ),
        ],
      ),
    );
  }
}
