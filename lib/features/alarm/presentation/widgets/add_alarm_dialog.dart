import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:alclock/l10n/app_localizations.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/constants/sizes.dart';
import '../../../../core/models/alarm_model.dart';
import '../../../../core/models/alarm_sound_model.dart';
import '../../../../core/utils/app_date_utils.dart';
import '../../../../core/widgets/glass_card.dart';
import '../providers/alarm_provider.dart';
import '../pages/sound_selection_page.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import 'motivation_note_input.dart';
import '../../utils/motivation_generator.dart';

class AddAlarmDialog extends ConsumerStatefulWidget {
  final AlarmModel? existingAlarm;

  const AddAlarmDialog({super.key, this.existingAlarm});

  @override
  ConsumerState<AddAlarmDialog> createState() => _AddAlarmDialogState();
}

class _AddAlarmDialogState extends ConsumerState<AddAlarmDialog> {
  late TimeOfDay selectedTime;
  final Set<int> selectedDays = <int>{};
  String selectedSoundName = 'alarm1';
  String? note;
  bool _mathLockEnabled = false; // PLAN HARD mode
  bool _isDisposed = false;

  // Short weekday names in Uzbek
  static const List<String> shortDayNames = ['Du', 'Se', 'Ch', 'Pa', 'Ju', 'Sh', 'Ya'];

  @override
  void initState() {
    super.initState();
    try {
      selectedTime = widget.existingAlarm != null
          ? TimeOfDay.fromDateTime(widget.existingAlarm!.time)
          : TimeOfDay.now();

      if (widget.existingAlarm != null) {
        // Safely handle repeatDays - ensure it's never null
        final existingDays = widget.existingAlarm!.repeatDays;
        if (existingDays.isNotEmpty) {
          selectedDays.addAll(existingDays);
        }
        selectedSoundName = widget.existingAlarm!.soundName ?? 'alarm1';
        note = widget.existingAlarm!.note;
        _mathLockEnabled = widget.existingAlarm!.mathLockEnabled;
      } else {
        selectedSoundName = 'alarm1';
        _mathLockEnabled = false; // Default: PLAN HARD is OFF
        // Will assign random motivation when dialog opens
      }
    } catch (e) {
      debugPrint('❌ Error in initState: $e');
      // Fallback to safe defaults
      selectedTime = TimeOfDay.now();
      selectedSoundName = 'alarm1';
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: selectedTime,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );
    if (picked != null && !_isDisposed && mounted) {
      setState(() => selectedTime = picked);
    }
  }

  void _toggleDay(int day) {
    if (_isDisposed || !mounted) return;
    setState(() {
      if (selectedDays.contains(day)) {
        selectedDays.remove(day);
      } else {
        selectedDays.add(day);
      }
    });
  }

  Future<void> _pickSound() async {
    if (_isDisposed || !mounted) return;
    
    final selectedSoundId = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (context) => SoundSelectionPage(
          selectedSoundId: selectedSoundName,
        ),
      ),
    );

    if (selectedSoundId != null && !_isDisposed && mounted) {
      setState(() {
        selectedSoundName = selectedSoundId;
      });
    }
  }

  Future<void> _saveAlarm() async {
    if (_isDisposed || !mounted) return;

    try {
      final now = DateTime.now();
      final alarmTime = DateTime(
        now.year,
        now.month,
        now.day,
        selectedTime.hour,
        selectedTime.minute,
      );

      // Ensure soundName is never null
      final safeSoundName = selectedSoundName.isNotEmpty ? selectedSoundName : 'alarm1';

      // Ensure repeatDays is never null and is a valid list
      final safeRepeatDays = selectedDays.isEmpty 
          ? <int>[]
          : (selectedDays.toList()..sort());

      // If note is empty, assign random motivation
      final finalNote = (note == null || note!.isEmpty)
          ? MotivationGenerator.randomMotivation()
          : note;

      final alarm = AlarmModel(
        id: widget.existingAlarm?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        time: alarmTime,
        repeatDays: safeRepeatDays,
        isEnabled: widget.existingAlarm?.isEnabled ?? true,
        soundName: safeSoundName,
        isVibrationEnabled: widget.existingAlarm?.isVibrationEnabled ?? true,
        volume: widget.existingAlarm?.volume ?? 0.8,
        isActive: widget.existingAlarm?.isActive ?? true,
        note: finalNote,
        mathLockEnabled: _mathLockEnabled,
      );

      // Debug log for PLAN HARD
      print('[PLAN HARD] Alarm saved. mathLockEnabled=$_mathLockEnabled');

      // Close dialog immediately (synchronous)
      if (mounted && !_isDisposed) {
        Navigator.of(context).pop();
      }

      // Update state using controller (non-blocking, optimistic update)
      final controller = ref.read(alarmListProvider.notifier);
      if (widget.existingAlarm != null) {
        controller.updateAlarm(alarm);
      } else {
        controller.addAlarm(alarm);
      }
    } catch (e) {
      debugPrint('❌ Error saving alarm: $e');
      // Show error to user if dialog is still open
      if (mounted && !_isDisposed) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Xatolik: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    // Debug: Check platform and switch state
    print('[PLAN HARD] Build called. Platform.isAndroid=${Platform.isAndroid}, _mathLockEnabled=$_mathLockEnabled');
    
    // Get default sound from settings if creating new alarm (only once)
    // Use ref.listen instead of ref.watch to avoid rebuilds
    if (widget.existingAlarm == null && selectedSoundName == 'alarm1') {
      final settingsAsync = ref.watch(settingsProvider);
      settingsAsync.whenData((settings) {
        if (!_isDisposed && mounted && selectedSoundName == 'alarm1') {
          final defaultSound = settings.selectedAlarmSound;
          if (defaultSound.isNotEmpty && defaultSound != 'alarm1') {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!_isDisposed && mounted && selectedSoundName == 'alarm1') {
                setState(() {
                  selectedSoundName = defaultSound;
                });
              }
            });
          }
        }
      });
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      child: GlassCard(
        padding: const EdgeInsets.all(AppSizes.paddingLarge),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.existingAlarm != null 
                    ? (l10n?.editAlarm ?? 'Edit Alarm')
                    : (l10n?.addAlarm ?? 'Add Alarm'),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSizes.paddingLarge),
              
              // Compact Time Picker Container
              GestureDetector(
                onTap: _selectTime,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: BoxDecoration(
                    color: AppColors.glassCard.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Text(
                    AppDateUtils.formatTimeOfDay(selectedTime),
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              
              const SizedBox(height: AppSizes.paddingLarge),
              
              // Sound Picker
              Text(
                l10n?.alarmSound ?? 'Alarm sound',
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSizes.paddingSmall),
              GestureDetector(
                onTap: _pickSound,
                child: GlassCard(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            AlarmSoundModel.getTitleById(selectedSoundName.isNotEmpty ? selectedSoundName : 'alarm1'),
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.music_note,
                          color: AppColors.textSecondary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: AppSizes.paddingLarge),
              
              // Repeat Days Selector
              Text(
                l10n?.repeat ?? 'Repeat',
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSizes.paddingMedium),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: List.generate(7, (index) {
                  final day = index + 1;
                  final isSelected = selectedDays.contains(day);
                  return GestureDetector(
                    onTap: () => _toggleDay(day),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? AppColors.accent 
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(19),
                        border: Border.all(
                          color: isSelected 
                              ? AppColors.accent 
                              : AppColors.textSecondary.withOpacity(0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          shortDayNames[index],
                          style: TextStyle(
                            color: isSelected 
                                ? Colors.white 
                                : AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
              
              const SizedBox(height: AppSizes.paddingLarge),
              
              // PLAN HARD Switch (Android only) - after Repeat, before Note
              if (Platform.isAndroid)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: SwitchListTile(
                      value: _mathLockEnabled,
                      onChanged: (value) {
                        setState(() {
                          _mathLockEnabled = value;
                        });
                        print('[PLAN HARD] Switch toggled: $value');
                      },
                      title: const Text(
                        'PLAN HARD',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: const Text(
                        'Alarmni o\'chirish uchun tenglama yechiladi',
                      ),
                      secondary: const Icon(
                        Icons.lock,
                        color: Colors.orange,
                      ),
                    ),
                  ),
                ),
              
              const SizedBox(height: AppSizes.paddingLarge),
              
              // Motivation Note Input
              MotivationNoteInput(
                initialNote: note,
                onNoteChanged: (newNote) {
                  if (!_isDisposed && mounted) {
                    setState(() {
                      note = newNote;
                    });
                  }
                },
              ),
              
              const SizedBox(height: AppSizes.paddingLarge),
              
              // Buttons - Same width, larger, with shadow
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 46,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.gradientStart,
                          foregroundColor: AppColors.textPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          l10n?.cancel ?? 'Cancel',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSizes.paddingMedium),
                  Expanded(
                    child: Container(
                      height: 46,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accent.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _saveAlarm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          l10n?.save ?? 'Save',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
