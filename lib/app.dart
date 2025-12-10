import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:alclock/l10n/app_localizations.dart';

import 'core/constants/colors.dart';
import 'core/constants/sizes.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/gradient_background.dart';
import 'core/providers/locale_provider.dart';

class App extends ConsumerStatefulWidget {
  const App({super.key});

  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App> {
  int _currentIndex = 0;

  /// Temporary simple pages — works everywhere
  final List<Widget> _pages = const [
    Center(child: Text("ALARM PAGE", style: TextStyle(fontSize: 26))),
    Center(child: Text("STATISTICS PAGE", style: TextStyle(fontSize: 26))),
    Center(child: Text("SETTINGS PAGE", style: TextStyle(fontSize: 26))),
  ];

  @override
  Widget build(BuildContext context) {
    final currentLocale = ref.watch(currentLocaleProvider);

    return MaterialApp(
      title: 'AlClock',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      locale: currentLocale,
      supportedLocales: const [
        Locale('uz', 'UZ'),
        Locale('ru', 'RU'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: GradientBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: _pages[_currentIndex],
          bottomNavigationBar: _buildBottomNav(),
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return SafeArea(
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.glassCard,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppSizes.radiusLarge),
          ),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppSizes.radiusLarge),
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() => _currentIndex = index);
            },
            backgroundColor: Colors.transparent,
            selectedItemColor: AppColors.accent,
            unselectedItemColor: AppColors.textSecondary,
            elevation: 0,
            type: BottomNavigationBarType.fixed,
            iconSize: 24,
            selectedFontSize: 11,
            unselectedFontSize: 11,
            items: [
              BottomNavigationBarItem(
                icon: _navIcon(Icons.alarm, 0),
                label: AppLocalizations.of(context)?.alarm ?? 'Alarm',
              ),
              BottomNavigationBarItem(
                icon: _navIcon(Icons.bar_chart, 1),
                label: AppLocalizations.of(context)?.statistics ?? 'Statistics',
              ),
              BottomNavigationBarItem(
                icon: _navIcon(Icons.settings, 2),
                label: AppLocalizations.of(context)?.settings ?? 'Settings',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navIcon(IconData icon, int index) {
    final selected = _currentIndex == index;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color:
            selected ? AppColors.accent.withOpacity(0.2) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        boxShadow: selected
            ? [
                BoxShadow(
                  color: AppColors.accent.withOpacity(0.3),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Icon(
        icon,
        size: selected ? 24 : 22,
      ),
    );
  }
}
