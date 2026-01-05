import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:alclock/l10n/app_localizations.dart';

import 'core/constants/colors.dart';
import 'core/constants/sizes.dart';
import 'core/theme/app_theme.dart';
import 'core/providers/locale_provider.dart';
import 'core/providers/shared_providers.dart';
import 'services/alarm_navigation_service.dart';
import 'features/alarm/presentation/pages/alarm_page.dart';
import 'features/sleep/presentation/pages/statistics_page.dart';
import 'features/settings/presentation/pages/settings_page.dart';
import 'features/settings/presentation/providers/settings_provider.dart';

class App extends ConsumerStatefulWidget {
  const App({super.key});

  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App> {
  int _currentIndex = 0;

  /// Actual pages
  final List<Widget> _pages = const [
    AlarmPage(),
    StatisticsPage(),
    SettingsPage(),
  ];

  @override
  void initState() {
    super.initState();
    // Start automatic sleep tracker if auto mode is enabled
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeSleepTracker();
    });
  }

  Future<void> _initializeSleepTracker() async {
    try {
      final settingsAsync = ref.read(settingsProvider);
      settingsAsync.whenData((settings) async {
        if (settings.autoModeEnabled) {
          final tracker = ref.read(automaticSleepTrackerProvider);
          await tracker.start();
        }
      });
    } catch (e) {
      print('❌ Error initializing sleep tracker: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentLocale = ref.watch(currentLocaleProvider);

    // Watch settings to start/stop sleep tracker
    ref.listen<AsyncValue>(settingsProvider, (previous, next) {
      next.whenData((settings) async {
        final tracker = ref.read(automaticSleepTrackerProvider);
        if (settings.autoModeEnabled && !tracker.isTracking) {
          await tracker.start();
        } else if (!settings.autoModeEnabled && tracker.isTracking) {
          await tracker.stop();
        }
      });
    });

    return MaterialApp(
      title: 'AlClock',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      locale: currentLocale,
      navigatorKey: AlarmNavigationService
          .navigatorKey, // Global navigator key for notification navigation
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
      home: Builder(
        builder: (context) => Scaffold(
          body: IndexedStack(
            index: _currentIndex,
            children: _pages,
          ),
          bottomNavigationBar: _buildBottomNav(context),
        ),
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
                label: l10n?.alarm ?? 'Alarm',
              ),
              BottomNavigationBarItem(
                icon: _navIcon(Icons.bar_chart, 1),
                label: l10n?.statistics ?? 'Statistics',
              ),
              BottomNavigationBarItem(
                icon: _navIcon(Icons.settings, 2),
                label: l10n?.settings ?? 'Settings',
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
