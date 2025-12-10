import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/constants/sizes.dart';
import '../../../../core/models/alarm_sound_model.dart';
import '../../../../core/providers/alarm_sounds_provider.dart';
import '../../../../core/widgets/gradient_background.dart';
import '../../../../core/widgets/glass_card.dart';

class SoundSelectionPage extends ConsumerStatefulWidget {
  final String? selectedSoundId;
  final Function(String)? onSoundSelected;

  const SoundSelectionPage({
    super.key,
    this.selectedSoundId,
    this.onSoundSelected,
  });

  @override
  ConsumerState<SoundSelectionPage> createState() => _SoundSelectionPageState();
}

class _SoundSelectionPageState extends ConsumerState<SoundSelectionPage> {
  AudioPlayer? _audioPlayer;
  String? _currentlyPlayingId;
  bool _isPlaying = false;
  bool _isDisposed = false;
  StreamSubscription<PlayerState>? _playerStateSubscription;
  Timer? _autoStopTimer;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _stopPreviewSync();
    _playerStateSubscription?.cancel();
    _playerStateSubscription = null;
    _autoStopTimer?.cancel();
    _autoStopTimer = null;
    _audioPlayer?.dispose();
    _audioPlayer = null;
    super.dispose();
  }

  /// Synchronous stop - safe to call from dispose()
  void _stopPreviewSync() {
    try {
      _autoStopTimer?.cancel();
      _autoStopTimer = null;
      _playerStateSubscription?.cancel();
      _playerStateSubscription = null;
      _audioPlayer?.stop();
    } catch (e) {
      debugPrint('Error stopping preview (sync): $e');
    }
  }

  /// Async stop - updates UI safely
  Future<void> _stopPreview() async {
    if (_isDisposed) return;

    try {
      _autoStopTimer?.cancel();
      _autoStopTimer = null;
      _playerStateSubscription?.cancel();
      _playerStateSubscription = null;

      if (_audioPlayer != null) {
        await _audioPlayer!.stop();
      }

      if (!_isDisposed && mounted) {
        setState(() {
          _isPlaying = false;
          _currentlyPlayingId = null;
        });
      }
    } catch (e) {
      debugPrint('Error stopping preview: $e');
      if (!_isDisposed && mounted) {
        setState(() {
          _isPlaying = false;
          _currentlyPlayingId = null;
        });
      }
    }
  }

  /// Play preview sound - uses AudioSource.asset for proper loading
  Future<void> _previewSound(AlarmSoundModel sound) async {
    // Prevent if disposed
    if (_isDisposed) return;

    // If same sound is playing, stop it
    if (_isPlaying && _currentlyPlayingId == sound.id) {
      await _stopPreview();
      return;
    }

    try {
      // Stop previous preview if playing
      if (_isPlaying && _currentlyPlayingId != null) {
        await _stopPreview();
      }

      // Check again after async stop
      if (_isDisposed || !mounted) return;

      // Create new audio player if needed
      if (_audioPlayer == null) {
        _audioPlayer = AudioPlayer();
      }

      // Update UI before async operations
      if (!_isDisposed && mounted) {
        setState(() {
          _isPlaying = true;
          _currentlyPlayingId = sound.id;
        });
      }

      // Load and play from assets using AudioSource.asset
      // This is the correct way to load assets with just_audio
      await _audioPlayer!.setAudioSource(
        AudioSource.asset(sound.assetPath),
      );
      
      // Check again after loading
      if (_isDisposed || !mounted || _currentlyPlayingId != sound.id) {
        return;
      }

      await _audioPlayer!.play();

      // Listen for completion - with proper cancellation
      _playerStateSubscription?.cancel();
      _playerStateSubscription = _audioPlayer!.playerStateStream.listen(
        (state) {
          if (_isDisposed || !mounted) return;
          
          if (state.processingState == ProcessingState.completed) {
            if (_currentlyPlayingId == sound.id) {
              if (!_isDisposed && mounted) {
                setState(() {
                  _isPlaying = false;
                  _currentlyPlayingId = null;
                });
              }
            }
          }
        },
        onError: (error) {
          debugPrint('❌ Audio player error: $error');
          if (!_isDisposed && mounted) {
            setState(() {
              _isPlaying = false;
              _currentlyPlayingId = null;
            });
          }
        },
      );

      // Auto-stop after 5 seconds as fallback
      _autoStopTimer?.cancel();
      _autoStopTimer = Timer(const Duration(seconds: 5), () {
        if (!_isDisposed && mounted && _currentlyPlayingId == sound.id) {
          _stopPreview();
        }
      });
    } catch (e, stackTrace) {
      debugPrint('❌ Error previewing sound ${sound.id}: $e');
      debugPrint('Stack trace: $stackTrace');
      // Log error but don't show snackbar - just reset UI
      if (!_isDisposed && mounted) {
        setState(() {
          _isPlaying = false;
          _currentlyPlayingId = null;
        });
      }
    }
  }

  void _selectSound(AlarmSoundModel sound) {
    // Stop preview when selecting
    _stopPreviewSync();
    widget.onSoundSelected?.call(sound.id);
    if (Navigator.canPop(context)) {
      Navigator.of(context).pop(sound.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final availableSounds = ref.watch(alarmSoundsProvider);
    final selectedId = widget.selectedSoundId;

    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) {
        if (didPop) {
          // Stop preview synchronously when popping
          _stopPreviewSync();
        }
      },
      child: GradientBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: const Text(
              'Select Alarm Sound',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
          body: ListView.builder(
            padding: const EdgeInsets.all(AppSizes.paddingLarge),
            itemCount: availableSounds.length,
            itemBuilder: (context, index) {
              final sound = availableSounds[index];
              final isSelected = sound.id == selectedId;
              final isPlaying = _isPlaying && _currentlyPlayingId == sound.id;

              return GlassCard(
                margin: const EdgeInsets.only(bottom: AppSizes.paddingMedium),
                child: RadioListTile<String>(
                  value: sound.id,
                  groupValue: selectedId,
                  onChanged: (value) {
                    if (value != null) {
                      _selectSound(sound);
                    }
                  },
                  title: Text(
                    sound.title,
                    style: TextStyle(
                      color: isSelected ? AppColors.accent : AppColors.textPrimary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  secondary: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isPlaying)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent),
                          ),
                        )
                      else
                        IconButton(
                          icon: const Icon(Icons.play_arrow, color: AppColors.accent),
                          onPressed: () => _previewSound(sound),
                          tooltip: 'Preview',
                        ),
                      if (isSelected)
                        const Icon(Icons.check_circle, color: AppColors.accent)
                      else
                        const SizedBox.shrink(),
                    ],
                  ),
                  activeColor: AppColors.accent,
                  selected: isSelected,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
