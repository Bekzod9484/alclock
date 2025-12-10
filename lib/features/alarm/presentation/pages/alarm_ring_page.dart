import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:alclock/l10n/app_localizations.dart';
import 'package:just_audio/just_audio.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/constants/sizes.dart';
import '../../../../core/models/alarm_model.dart';
import '../../../../core/models/alarm_sound_model.dart';
import 'package:intl/intl.dart';
import '../../../../core/widgets/gradient_background.dart';
import '../../../../core/widgets/neumorphic_button.dart';
import '../../../../core/providers/shared_providers.dart';
import '../../../../core/utils/motivational_messages.dart';
import '../../../../services/alarm_player.dart';

class AlarmRingPage extends ConsumerStatefulWidget {
  final String alarmId;
  final String? soundName; // Optional: sound name passed from native

  const AlarmRingPage({
    super.key,
    required this.alarmId,
    this.soundName,
  });

  @override
  ConsumerState<AlarmRingPage> createState() => _AlarmRingPageState();
}

class _AlarmRingPageState extends ConsumerState<AlarmRingPage> {
  AlarmModel? _alarm;
  Timer? _timeTimer;
  Timer? _vibrationTimer;
  DateTime _currentTime = DateTime.now();
  bool _isLoading = true;
  String _motivationalMessage = '';
  AudioPlayer? _audioPlayer;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    // Make this page full-screen
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    
    _loadAlarm();
    _loadMotivationalMessage();
    _startTimer();
    _startVibration();
    _startAlarmSound();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _timeTimer?.cancel();
    _vibrationTimer?.cancel();
    _stopAlarmSound();
    _audioPlayer?.dispose();
    _audioPlayer = null;
    
    // Restore system UI
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    
    super.dispose();
  }

  Future<void> _startAlarmSound() async {
    if (_isDisposed) return;

    try {
      // Get sound name from widget or alarm
      String soundName = widget.soundName ?? 'alarm1';
      if (_alarm != null && _alarm!.soundName != null) {
        soundName = _alarm!.soundName!;
      }

      // Start native alarm player (for background playback)
      await AlarmPlayer.startAlarm(soundName);

      // Also play in Flutter for foreground
      await _playAlarmSound(soundName);
    } catch (e) {
      print('❌ Error starting alarm sound: $e');
    }
  }

  Future<void> _playAlarmSound(String soundName) async {
    if (_isDisposed) return;

    try {
      _audioPlayer?.dispose();
      _audioPlayer = AudioPlayer();

      // Get sound asset path
      final soundPath = AlarmSoundModel.getAssetPathById(soundName);

      print('🔊 Loading alarm sound: $soundPath');

      // Load and play sound in loop
      await _audioPlayer!.setAudioSource(
        AudioSource.asset(soundPath),
      );
      await _audioPlayer!.setLoopMode(LoopMode.one); // Loop continuously
      await _audioPlayer!.setVolume(1.0); // Full volume
      await _audioPlayer!.play();

      // Sound is playing

      print('✅ Playing alarm sound in loop: $soundPath');
    } catch (e) {
      print('❌ Error playing alarm sound: $e');
    }
  }

  Future<void> _stopAlarmSound() async {
    try {
      // Stop native alarm player
      await AlarmPlayer.stopAlarm();

      // Stop Flutter audio player
      await _audioPlayer?.stop();
      await _audioPlayer?.dispose();
      _audioPlayer = null;

      // Sound stopped
    } catch (e) {
      print('Error stopping alarm sound: $e');
    }
  }

  Future<void> _loadAlarm() async {
    try {
      final hiveService = ref.read(initializedHiveServiceProvider);
      final alarms = await hiveService.getAllAlarms();
      
      // Try to find alarm (might be snooze alarm)
      AlarmModel? alarm;
      try {
        alarm = alarms.firstWhere((a) => a.id == widget.alarmId);
      } catch (e) {
        // If not found, try without _snooze suffix
        final baseId = widget.alarmId.replaceAll('_snooze', '');
        try {
          alarm = alarms.firstWhere((a) => a.id == baseId);
        } catch (e2) {
          print('⚠️ Alarm not found: ${widget.alarmId}');
        }
      }

      if (!_isDisposed && mounted) {
        setState(() {
          _alarm = alarm;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading alarm: $e');
      if (!_isDisposed && mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _loadMotivationalMessage() {
    // Get a fully random motivational message (no time-based logic)
    final message = MotivationalMessages.getRandomMessage();
    if (!_isDisposed && mounted) {
      setState(() {
        _motivationalMessage = message;
      });
    }
  }

  void _startTimer() {
    _timeTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isDisposed && mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    });
  }

  void _startVibration() {
    if (_alarm == null || (_alarm?.isVibrationEnabled ?? true)) {
      _vibrationTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
        if (!_isDisposed) {
          HapticFeedback.heavyImpact();
        }
      });
    }
  }

  Future<void> _handleStop() async {
    if (_isDisposed) return;
    
    try {
      // Stop vibration
      _vibrationTimer?.cancel();
      _vibrationTimer = null;
      
      // Stop alarm sound immediately
      await _stopAlarmSound();

      // Stop alarm via AlarmService
      final alarmService = ref.read(alarmServiceProvider);
      await alarmService.stopAlarm(widget.alarmId);
      
      print('✅ Alarm stopped: ${widget.alarmId}');

      // Save sleep record (optional)
      await _saveSleepRecord();

      // Close the AlarmPage
      if (!_isDisposed && mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      print('❌ Error stopping alarm: $e');
      // Still close the page even if there's an error
      if (!_isDisposed && mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _handleSnooze5Minutes() async {
    if (_isDisposed) return;
    
    try {
      // Stop vibration
      _vibrationTimer?.cancel();
      _vibrationTimer = null;
      
      // Stop alarm sound immediately
      await _stopAlarmSound();

      // Get the sound name to preserve it for snooze
      String soundName = widget.soundName ?? 'alarm1';
      if (_alarm != null && _alarm!.soundName != null) {
        soundName = _alarm!.soundName!;
      }

      // Schedule snooze via AlarmService
      final alarmService = ref.read(alarmServiceProvider);
      await alarmService.scheduleSnooze(widget.alarmId);
      
      print('✅ Alarm snoozed: ${widget.alarmId} - will ring again in 5 minutes with sound: $soundName');

      // Close the AlarmPage
      if (!_isDisposed && mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      print('❌ Error snoozing alarm: $e');
      // Still close the page even if there's an error
      if (!_isDisposed && mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _saveSleepRecord() async {
    try {
      // Implementation for saving sleep record
      // This can be customized based on your sleep tracking logic
    } catch (e) {
      print('Error saving sleep record: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Prevent back button from dismissing alarm
        return false;
      },
      child: Scaffold(
        body: GradientBackground(
          child: SafeArea(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.accent,
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Current time
                      Text(
                        DateFormat('HH:mm').format(_currentTime),
                        style: const TextStyle(
                          fontSize: 72,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSizes.paddingLarge),

                      // Alarm time
                      if (_alarm != null)
                        Text(
                          '${AppLocalizations.of(context)?.alarmRinging ?? 'Alarm'}: ${DateFormat('HH:mm').format(_alarm!.time)}',
                          style: const TextStyle(
                            fontSize: 24,
                            color: AppColors.textSecondary,
                          ),
                        ),

                      const SizedBox(height: AppSizes.paddingXLarge),

                      // Motivational message
                      if (_motivationalMessage.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSizes.paddingLarge,
                          ),
                          child: Text(
                            _motivationalMessage,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 18,
                              color: AppColors.textSecondary,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),

                      const Spacer(),

                      // Stop and Snooze buttons
                      Padding(
                        padding: const EdgeInsets.all(AppSizes.paddingLarge),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Snooze button
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: NeumorphicButton(
                                  onPressed: _handleSnooze5Minutes,
                                  height: 80,
                                  borderRadius: AppSizes.radiusMedium,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSizes.paddingSmall,
                                      vertical: AppSizes.paddingMedium,
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.snooze,
                                          color: AppColors.accent,
                                          size: 24,
                                        ),
                                        const SizedBox(width: 6),
                                        Flexible(
                                          child: Text(
                                            AppLocalizations.of(context)?.snoozeButton ?? '5 minutes later',
                                            style: const TextStyle(
                                              color: AppColors.textPrimary,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            // Stop button
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(left: 6),
                                child: NeumorphicButton(
                                  onPressed: _handleStop,
                                  height: 80,
                                  borderRadius: AppSizes.radiusMedium,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSizes.paddingSmall,
                                      vertical: AppSizes.paddingMedium,
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.stop_circle,
                                          color: AppColors.accent,
                                          size: 24,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          AppLocalizations.of(context)?.stop ?? 'Stop',
                                          style: const TextStyle(
                                            color: AppColors.textPrimary,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
