import 'package:alclock/core/widgets/glass_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:alclock/l10n/app_localizations.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/constants/sizes.dart';
import '../../../../core/models/settings_model.dart';
import '../../../../core/models/alarm_sound_model.dart';
import '../../../../core/widgets/gradient_background.dart';
import '../../../alarm/presentation/pages/sound_selection_page.dart';
import '../providers/settings_provider.dart';
import '../widgets/settings_section.dart';
import '../widgets/settings_tile.dart';
import '../../../../core/providers/shared_providers.dart';
import '../../../../core/providers/locale_provider.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  final TextEditingController _nameController = TextEditingController();
  final List<int> _snoozeOptions = [5, 10, 15];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _updateSettings(SettingsModel settings) async {
    try {
      debugPrint('💾 Updating settings...');
      final repository = ref.read(settingsRepositoryProvider);
      await repository.saveSettings(settings);
      debugPrint('✅ Settings saved to Hive successfully');
      if (mounted) {
        ref.invalidate(settingsProvider);
      }
    } catch (e) {
      debugPrint('❌ Error updating settings: $e');
    }
  }

  Future<void> _updateAlarmVolumes(double volume) async {
    try {
      debugPrint('🔊 Updating alarm volumes to: ${(volume * 100).toInt()}%');
      // Note: Actual volume control will be handled by native alarm player
      // This is a placeholder for future implementation
      // The volume setting is saved and will be used when alarms ring
      debugPrint('   → Volume setting saved. Will be applied to next alarm ring.');
    } catch (e) {
      debugPrint('❌ Error updating alarm volumes: $e');
    }
  }

  String _getGreeting(String name, BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return '${l10n?.goodMorning ?? 'Good morning'}, $name';
    } else if (hour < 18) {
      return '${l10n?.goodAfternoon ?? 'Good afternoon'}, $name';
    } else {
      return '${l10n?.goodEvening ?? 'Good evening'}, $name';
    }
  }

  String _getLanguageName(String code) {
    switch (code) {
      case 'uz':
        return 'O\'zbek';
      case 'ru':
        return 'Русский';
      case 'en':
        return 'English';
      default:
        return 'O\'zbek';
    }
  }

  Widget _buildLanguageOption(BuildContext context, String code, String name, SettingsModel settings) {
    final isSelected = settings.languageCode == code;
    return ListTile(
      title: Text(
        name,
        style: TextStyle(
          color: isSelected ? AppColors.accent : AppColors.textPrimary,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedTileColor: AppColors.accent.withOpacity(0.2),
      trailing: isSelected
          ? const Icon(Icons.check, color: AppColors.accent)
          : null,
      onTap: () async {
        debugPrint('✅ Language selected: $code ($name)');
        await _updateSettings(settings.copyWith(languageCode: code));
        
        // Update locale provider for instant change
        final localeNotifier = ref.read(currentLocaleProvider.notifier);
        await localeNotifier.setLocale(code);
        
        if (context.mounted) {
          Navigator.pop(context);
          // Invalidate settings to refresh UI
          ref.invalidate(settingsProvider);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(settingsProvider);

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(
            AppLocalizations.of(context)?.settings ?? 'Settings',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        body: settingsAsync.when(
          data: (settings) {
            _nameController.text = settings.userName;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppSizes.paddingLarge),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User Profile Section
                  SettingsSection(
                    title: AppLocalizations.of(context)?.userProfile ?? 'User Profile',
                    children: [
                      TextField(
                        controller: _nameController,
                        style: const TextStyle(color: AppColors.textPrimary),
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(context)?.name ?? 'Name',
                          labelStyle: const TextStyle(color: AppColors.textSecondary),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                            borderSide: const BorderSide(color: AppColors.glassCard),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                            borderSide: const BorderSide(color: AppColors.accent),
                          ),
                        ),
                        onChanged: (value) {
                          _updateSettings(settings.copyWith(userName: value));
                        },
                      ),
                      const SizedBox(height: AppSizes.paddingMedium),
                      GlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getGreeting(settings.userName, context),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              AppLocalizations.of(context)?.todayIsAFreshStart(settings.userName) ?? '${settings.userName}, today\'s a fresh start.',
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Alarm Settings Section
                  SettingsSection(
                    title: AppLocalizations.of(context)?.alarmSettings ?? 'Alarm Settings',
                    children: [
                      SettingsTile(
                        title: AppLocalizations.of(context)?.alarmSound ?? 'Alarm Sound',
                        subtitle: AlarmSoundModel.getTitleById(settings.selectedAlarmSound),
                        trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                        onTap: () async {
                          final selectedSoundId = await Navigator.of(context).push<String>(
                            MaterialPageRoute(
                              builder: (context) => SoundSelectionPage(
                                selectedSoundId: settings.selectedAlarmSound,
                              ),
                            ),
                          );

                          if (selectedSoundId != null && mounted) {
                            await _updateSettings(settings.copyWith(selectedAlarmSound: selectedSoundId));
                            // Refresh all alarms to use new sound
                            final alarmService = ref.read(alarmServiceProvider);
                            final alarms = await ref.read(initializedHiveServiceProvider).getAllAlarms();
                            for (final alarm in alarms) {
                              if (alarm.isEnabled && alarm.isActive) {
                                await alarmService.scheduleAlarm(alarm);
                              }
                            }
                            // Invalidate settings to refresh UI
                            ref.invalidate(settingsProvider);
                          }
                        },
                      ),
                      const Divider(color: AppColors.glassCard),
                      SettingsTile(
                        title: AppLocalizations.of(context)?.snooze ?? 'Snooze',
                        subtitle: AppLocalizations.of(context)?.minutes(settings.snoozeMinutes) ?? '${settings.snoozeMinutes} minutes',
                        trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                        onTap: () {
                          debugPrint('🔔 Opening snooze duration picker');
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              backgroundColor: AppColors.gradientStart,
                              title: const Text('Snooze Duration', style: TextStyle(color: AppColors.textPrimary)),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: _snoozeOptions.map((minutes) {
                                  return ListTile(
                                    title: Text('$minutes minutes', style: const TextStyle(color: AppColors.textPrimary)),
                                    selected: minutes == settings.snoozeMinutes,
                                    selectedTileColor: AppColors.accent.withOpacity(0.2),
                                    onTap: () {
                                      debugPrint('✅ Snooze duration selected: $minutes minutes');
                                      _updateSettings(settings.copyWith(snoozeMinutes: minutes));
                                      Navigator.pop(context);
                                    },
                                  );
                                }).toList(),
                              ),
                            ),
                          );
                        },
                      ),
                      const Divider(color: AppColors.glassCard),
                      SettingsTile(
                        title: AppLocalizations.of(context)?.vibration ?? 'Vibration',
                        trailing: Switch(
                          value: settings.vibrationEnabled,
                          onChanged: (value) async {
                            debugPrint('📳 Vibration toggled: $value');
                            _updateSettings(settings.copyWith(vibrationEnabled: value));
                            
                            // Test vibration if enabled
                            if (value) {
                              try {
                                await HapticFeedback.mediumImpact();
                                debugPrint('✅ Vibration test successful');
                              } catch (e) {
                                debugPrint('⚠️ Vibration not available: $e');
                              }
                            }
                          },
                          activeColor: AppColors.accent,
                        ),
                      ),
                      const Divider(color: AppColors.glassCard),
                      SettingsTile(
                        title: AppLocalizations.of(context)?.volume ?? 'Volume',
                        subtitle: '${(settings.volume * 100).toInt()}%',
                        trailing: SizedBox(
                          width: 150,
                          child: Slider(
                            value: settings.volume,
                            min: 0.0,
                            max: 1.0,
                            divisions: 10,
                            label: '${(settings.volume * 100).toInt()}%',
                            onChanged: (value) {
                              debugPrint('🔊 Volume changed: ${(value * 100).toInt()}%');
                              _updateSettings(settings.copyWith(volume: value));
                              
                              // Update all active alarms with new volume
                              _updateAlarmVolumes(value);
                            },
                            activeColor: AppColors.accent,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Language Section
                  SettingsSection(
                    title: AppLocalizations.of(context)?.language ?? 'Language',
                    children: [
                      SettingsTile(
                        title: AppLocalizations.of(context)?.selectLanguage ?? 'Select Language',
                        subtitle: _getLanguageName(settings.languageCode),
                        trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                        onTap: () {
                          debugPrint('🌐 Opening language selector');
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              backgroundColor: AppColors.gradientStart,
                              title: Text(
                                AppLocalizations.of(context)?.selectLanguage ?? 'Select Language',
                                style: const TextStyle(color: AppColors.textPrimary),
                              ),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _buildLanguageOption(context, 'uz', 'O\'zbek', settings),
                                  _buildLanguageOption(context, 'ru', 'Русский', settings),
                                  _buildLanguageOption(context, 'en', 'English', settings),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.paddingLarge),

                  // Sleep Tracking Settings Section
                  SettingsSection(
                    title: AppLocalizations.of(context)?.sleepTrackingSettings ?? 'Sleep Tracking Settings',
                    children: [
                      SettingsTile(
                        title: AppLocalizations.of(context)?.autoMode ?? 'Auto Mode',
                        subtitle: AppLocalizations.of(context)?.automaticallyDetectSleep ?? 'Automatically detect sleep',
                        trailing: Switch(
                          value: settings.autoModeEnabled,
                          onChanged: (value) async {
                            debugPrint('🤖 Auto Mode toggled: $value');
                            _updateSettings(settings.copyWith(autoModeEnabled: value));
                            
                            // Start/stop automatic sleep tracker
                            final tracker = ref.read(automaticSleepTrackerProvider);
                            if (value) {
                              await tracker.start();
                              debugPrint('   → Sleep tracking will use automatic detection');
                            } else {
                              await tracker.stop();
                              debugPrint('   → Sleep tracking will use manual mode');
                            }
                          },
                          activeColor: AppColors.accent,
                        ),
                      ),
                      const Divider(color: AppColors.glassCard),
                      SettingsTile(
                        title: AppLocalizations.of(context)?.dailyMotivationalTips ?? 'Daily Motivational Tips',
                        trailing: Switch(
                          value: settings.motivationalTipsEnabled,
                          onChanged: (value) {
                            debugPrint('💡 Daily Motivational Tips toggled: $value');
                            _updateSettings(settings.copyWith(motivationalTipsEnabled: value));
                            if (value) {
                              debugPrint('   → Motivational tips will be shown daily');
                            } else {
                              debugPrint('   → Motivational tips disabled');
                            }
                          },
                          activeColor: AppColors.accent,
                        ),
                      ),
                      const Divider(color: AppColors.glassCard),
                      SettingsTile(
                        title: AppLocalizations.of(context)?.emojiMode ?? 'Emoji Mode',
                        trailing: Switch(
                          value: settings.emojiModeEnabled,
                          onChanged: (value) {
                            _updateSettings(settings.copyWith(emojiModeEnabled: value));
                          },
                          activeColor: AppColors.accent,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Text(
              'Error: $error',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ),
      ),
    );
  }
}

