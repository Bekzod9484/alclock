import 'dart:async';
import 'dart:io';
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
import '../../../../utils/android_alarm_debug.dart';
import '../../../../plan_hard/math_equation_generator.dart';

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

  // PLAN HARD mode state
  String? _mathEquation;
  int? _correctAnswer;
  final TextEditingController _answerController = TextEditingController();
  String? _errorMessage;

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

    // Android alarm debug log - alarm trigger va ringing screen
    _logAlarmTriggered();
  }

  /// Alarm trigger va ringing screen ochilishini log qilish
  void _logAlarmTriggered() {
    final soundName = widget.soundName ?? _alarm?.soundName ?? 'alarm1';

    // Alarm vaqti yetdi (Receiver ishga tushdi)
    AndroidAlarmDebug.logAlarmTriggered(
      alarmId: widget.alarmId,
      soundName: soundName,
    );

    // Ringing ekrani ochildi
    AndroidAlarmDebug.logRingingScreenOpened(
      alarmId: widget.alarmId,
      soundName: soundName,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // PLAN HARD mode initialization (Android only) - after alarm is loaded
    if (Platform.isAndroid && _alarm != null && _mathEquation == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _initializePlanHard();
      });
    }
  }

  /// Initialize PLAN HARD mode (Android only)
  void _initializePlanHard() {
    if (_alarm?.mathLockEnabled == true && _mathEquation == null) {
      // Generate math equation
      final equationData = MathEquationGenerator.generate();
      setState(() {
        _mathEquation = equationData.equation;
        _correctAnswer = equationData.answer;
      });

      // Log PLAN HARD activation
      print('[ANDROID-ALARM] 🔒 PLAN HARD yoqildi');
      print('[ANDROID-ALARM] 🧮 Tenglama: $_mathEquation');
      AndroidAlarmDebug.logAlarmError(
        alarmId: widget.alarmId,
        error: 'PLAN HARD mode active - math equation required',
      );

      // Android hard blocking
      _enableAndroidHardBlocking();
    }
  }

  /// Enable Android hard blocking (prevent exit, keep screen on)
  void _enableAndroidHardBlocking() {
    if (!Platform.isAndroid) return;

    // Keep screen on
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    // Disable back button (handled in WillPopScope)
  }

  @override
  void dispose() {
    _isDisposed = true;
    _timeTimer?.cancel();
    _vibrationTimer?.cancel();
    _stopAlarmSound();
    _audioPlayer?.dispose();
    _audioPlayer = null;
    _answerController.dispose();

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
      print('🔊 [AlarmRingPage] Starting alarm sound...');

      // Get sound name from widget or alarm
      String soundName = widget.soundName ?? 'alarm1';
      if (_alarm != null && _alarm!.soundName != null) {
        soundName = _alarm!.soundName!;
      }

      print('🔊 [AlarmRingPage] Using sound: $soundName');

      // Platform-specific audio playback
      // iOS: Use just_audio only (AlarmPlayer is Android-only)
      // Android: Use both AlarmPlayer (native) and just_audio (backup)
      if (Platform.isIOS) {
        // iOS: Play audio using just_audio
        // NOTE: iOS cannot auto-play audio when app is terminated.
        // This is an Apple limitation. Audio only plays when app is open.
        print(
            '🔊 [AlarmRingPage iOS] Starting audio playback via just_audio...');
        await _playAlarmSound(soundName);
        print('✅ [AlarmRingPage iOS] Audio playback started');
      } else if (Platform.isAndroid) {
        // Android: Use native AlarmPlayer for background playback
        print('🔊 [AlarmRingPage Android] Starting native alarm player...');
        try {
          await AlarmPlayer.startAlarm(soundName);
          print('✅ [AlarmRingPage Android] Native alarm player started');
        } catch (e) {
          print(
              '⚠️ [AlarmRingPage Android] Native player failed, using just_audio: $e');
        }

        // Also play in Flutter for foreground (backup/duplicate playback)
        print('🔊 [AlarmRingPage Android] Starting Flutter audio player...');
        await _playAlarmSound(soundName);
      }

      print('✅ [AlarmRingPage] Alarm sound started successfully');
    } catch (e, stackTrace) {
      print('❌ [AlarmRingPage] Error starting alarm sound: $e');
      print('❌ [AlarmRingPage] Stack trace: $stackTrace');
    }
  }

  Future<void> _playAlarmSound(String soundName) async {
    if (_isDisposed) return;

    try {
      print('🔊 [AlarmRingPage] Starting alarm sound playback: $soundName');

      _audioPlayer?.dispose();
      _audioPlayer = AudioPlayer();

      // Get sound asset path
      final soundPath = AlarmSoundModel.getAssetPathById(soundName);
      print('🔊 [AlarmRingPage] Sound asset path: $soundPath');

      // Load and play sound in loop
      await _audioPlayer!.setAudioSource(
        AudioSource.asset(soundPath),
      );
      print('🔊 [AlarmRingPage] Audio source loaded');

      await _audioPlayer!.setLoopMode(LoopMode.one); // Loop continuously
      await _audioPlayer!.setVolume(1.0); // Full volume

      print('🔊 [AlarmRingPage] Starting playback...');
      await _audioPlayer!.play();

      print('✅ [AlarmRingPage] Alarm sound playing in loop: $soundPath');

      // Android alarm debug log - alarm musiqasi chalinyapti
      AndroidAlarmDebug.logAlarmPlaying(
        alarmId: widget.alarmId,
        soundName: soundName,
      );
    } catch (e, stackTrace) {
      print('❌ [AlarmRingPage] Error playing alarm sound: $e');
      print('❌ [AlarmRingPage] Stack trace: $stackTrace');
    }
  }

  Future<void> _stopAlarmSound() async {
    try {
      // Stop native alarm player (Android only)
      if (Platform.isAndroid) {
        try {
          await AlarmPlayer.stopAlarm();
        } catch (e) {
          print('⚠️ Error stopping native alarm player: $e');
        }
      }

      // Stop Flutter audio player (works on both platforms)
      await _audioPlayer?.stop();
      await _audioPlayer?.dispose();
      _audioPlayer = null;

      print('✅ Alarm sound stopped');
    } catch (e) {
      print('❌ Error stopping alarm sound: $e');
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

    // PLAN HARD mode: prevent stop without solving equation
    if (Platform.isAndroid && _alarm?.mathLockEnabled == true) {
      print('[ANDROID-ALARM] ⚠️ PLAN HARD rejimi: avval tenglamani yeching');
      return;
    }

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

      // Android alarm debug log - alarm to'xtatildi
      AndroidAlarmDebug.logAlarmStopped(alarmId: widget.alarmId);

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

    // PLAN HARD mode: prevent snooze without solving equation
    if (Platform.isAndroid && _alarm?.mathLockEnabled == true) {
      print('[ANDROID-ALARM] ⚠️ PLAN HARD rejimi: avval tenglamani yeching');
      return;
    }

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

      print(
          '✅ Alarm snoozed: ${widget.alarmId} - will ring again in 5 minutes with sound: $soundName');

      // Android alarm debug log - snooze bosildi
      final snoozeTime = DateTime.now().add(const Duration(minutes: 5));
      AndroidAlarmDebug.logSnoozePressed(
        alarmId: widget.alarmId,
        snoozeTime: snoozeTime,
        soundName: soundName,
      );

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

  /// Validate math answer (PLAN HARD mode)
  Future<void> _validateMathAnswer() async {
    if (_correctAnswer == null || _mathEquation == null) {
      return;
    }

    final userAnswer = int.tryParse(_answerController.text.trim());

    if (userAnswer == null) {
      setState(() {
        _errorMessage = 'Iltimos, raqam kiriting';
      });
      return;
    }

    if (userAnswer == _correctAnswer) {
      // Correct answer - stop alarm
      print('[ANDROID-ALARM] ✅ To\'g\'ri javob. Alarm o\'chirildi');

      // Stop alarm
      await _handleStopAfterMath();
    } else {
      // Incorrect answer - show error, continue alarm
      print('[ANDROID-ALARM] ❌ Noto\'g\'ri javob, alarm davom etmoqda');

      setState(() {
        _errorMessage = 'Noto\'g\'ri javob! Qayta urinib ko\'ring.';
        _answerController.clear();
      });

      // Haptic feedback for wrong answer
      HapticFeedback.heavyImpact();
    }
  }

  /// Stop alarm after correct math answer
  Future<void> _handleStopAfterMath() async {
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

      print('✅ Alarm stopped after math validation: ${widget.alarmId}');

      // Android alarm debug log - alarm to'xtatildi
      AndroidAlarmDebug.logAlarmStopped(alarmId: widget.alarmId);

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

  @override
  Widget build(BuildContext context) {
    final isPlanHard = Platform.isAndroid && _alarm?.mathLockEnabled == true;

    return WillPopScope(
      onWillPop: () async {
        // PLAN HARD mode: prevent back button
        if (isPlanHard) {
          print(
              '[ANDROID-ALARM] ⚠️ PLAN HARD rejimi: avval tenglamani yeching');
          return false;
        }
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

                      // PLAN HARD mode: Math equation UI
                      if (isPlanHard && _mathEquation != null)
                        Padding(
                          padding: const EdgeInsets.all(AppSizes.paddingLarge),
                          child: Column(
                            children: [
                              // PLAN HARD label
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.accent.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.lock,
                                      color: AppColors.accent,
                                      size: 20,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'PLAN HARD - Majburiy uyg\'onish',
                                      style: TextStyle(
                                        color: AppColors.accent,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: AppSizes.paddingLarge),

                              // Math equation
                              Text(
                                _mathEquation!,
                                style: const TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: AppSizes.paddingLarge),

                              // Answer input
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSizes.paddingLarge,
                                ),
                                child: TextField(
                                  controller: _answerController,
                                  keyboardType: TextInputType.number,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Javob',
                                    hintStyle: TextStyle(
                                      color: AppColors.textSecondary
                                          .withOpacity(0.5),
                                    ),
                                    filled: true,
                                    fillColor:
                                        AppColors.glassCard.withOpacity(0.3),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide(
                                        color: AppColors.accent,
                                        width: 2,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide(
                                        color:
                                            AppColors.accent.withOpacity(0.5),
                                        width: 2,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide(
                                        color: AppColors.accent,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              // Error message
                              if (_errorMessage != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 12),
                                  child: Text(
                                    _errorMessage!,
                                    style: const TextStyle(
                                      color: Colors.red,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),

                              const SizedBox(height: AppSizes.paddingLarge),

                              // Tekshirish button
                              SizedBox(
                                width: double.infinity,
                                child: NeumorphicButton(
                                  onPressed: _validateMathAnswer,
                                  height: 60,
                                  borderRadius: AppSizes.radiusMedium,
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.check_circle,
                                        color: AppColors.accent,
                                        size: 24,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Tekshirish',
                                        style: TextStyle(
                                          color: AppColors.textPrimary,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        // Normal mode: Stop and Snooze buttons
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
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
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
                                              AppLocalizations.of(context)
                                                      ?.snoozeButton ??
                                                  '5 minutes later',
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
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.stop_circle,
                                            color: AppColors.accent,
                                            size: 24,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            AppLocalizations.of(context)
                                                    ?.stop ??
                                                'Stop',
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
