import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/shared_providers.dart';

/// Locale provider that reads from settings
final localeProvider = FutureProvider<Locale>((ref) async {
  try {
    final hiveService = ref.watch(initializedHiveServiceProvider);
    final settings = await hiveService.getSettings();
    
    // Map language code to Locale
    final langCode = settings.languageCode.isNotEmpty ? settings.languageCode : 'uz';
    switch (langCode) {
      case 'uz':
        return const Locale('uz', 'UZ');
      case 'ru':
        return const Locale('ru', 'RU');
      case 'en':
        return const Locale('en', 'US');
      default:
        return const Locale('uz', 'UZ'); // Default to Uzbek
    }
  } catch (e) {
    print('❌ Error loading locale: $e');
    return const Locale('uz', 'UZ'); // Fallback to Uzbek
  }
});

/// Current locale state provider (for instant updates)
final currentLocaleProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  return LocaleNotifier(ref);
});

class LocaleNotifier extends StateNotifier<Locale> {
  final Ref _ref;
  
  LocaleNotifier(this._ref) : super(const Locale('uz', 'UZ')) {
    // Load locale in background - use Future.microtask to avoid blocking
    Future.microtask(() => _loadLocale());
  }
  
  Future<void> _loadLocale() async {
    try {
      final hiveService = _ref.read(initializedHiveServiceProvider);
      final settings = await hiveService.getSettings();
      final langCode = settings.languageCode.isNotEmpty ? settings.languageCode : 'uz';
      state = _getLocaleFromCode(langCode);
    } catch (e) {
      print('❌ Error loading locale in LocaleNotifier: $e');
      state = const Locale('uz', 'UZ'); // Fallback
    }
  }
  
  Future<void> setLocale(String languageCode) async {
    final locale = _getLocaleFromCode(languageCode);
    state = locale;
    
    // Save to settings
    final hiveService = _ref.read(initializedHiveServiceProvider);
    final settings = await hiveService.getSettings();
    final updatedSettings = settings.copyWith(languageCode: languageCode);
    await hiveService.saveSettings(updatedSettings);
  }
  
  Locale _getLocaleFromCode(String code) {
    switch (code) {
      case 'uz':
        return const Locale('uz', 'UZ');
      case 'ru':
        return const Locale('ru', 'RU');
      case 'en':
        return const Locale('en', 'US');
      default:
        return const Locale('uz', 'UZ');
    }
  }
}

