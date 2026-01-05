import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/alarm_model.dart';
import '../../../../core/providers/shared_providers.dart';
import '../../data/repositories/alarm_repository_impl.dart';
import '../../domain/repositories/alarm_repository.dart';

/// REPOSITORY PROVIDER
final alarmRepositoryProvider = Provider<AlarmRepository>((ref) {
  final hive = ref.watch(initializedHiveServiceProvider);
  final alarm = ref.watch(alarmServiceProvider);
  return AlarmRepositoryImpl(hive, alarm);
});

/// ALARM LIST STATE NOTIFIER PROVIDER
final alarmListProvider =
    StateNotifierProvider<AlarmListController, List<AlarmModel>>((ref) {
  final repo = ref.watch(alarmRepositoryProvider);
  return AlarmListController(repo);
});

/// ALARM LIST CONTROLLER
class AlarmListController extends StateNotifier<List<AlarmModel>> {
  final AlarmRepository _repo;
  bool _isLoading = false;
  Timer? _reloadTimer;

  AlarmListController(this._repo) : super([]) {
    // Load initial data in background - use Future.microtask to avoid blocking
    Future.microtask(() => _loadAlarms());
  }

  @override
  void dispose() {
    _reloadTimer?.cancel();
    super.dispose();
  }

  /// Load alarms from repository (background)
  /// Prevents race conditions with debouncing
  Future<void> _loadAlarms() async {
    // Prevent multiple simultaneous loads
    if (_isLoading) return;
    
    _isLoading = true;
    try {
      final data = await _repo.getAllAlarms();
      // Ensure all alarms are valid
      final validAlarms = data.where((alarm) {
        try {
          return alarm.id.isNotEmpty;
        } catch (e) {
          return false;
        }
      }).toList();
      state = validAlarms;
    } catch (e) {
      print('❌ Error loading alarms: $e');
      // Handle error silently or log it
      state = [];
    } finally {
      _isLoading = false;
    }
  }

  /// Debounced reload - prevents multiple rapid reloads
  void _debouncedReload() {
    _reloadTimer?.cancel();
    _reloadTimer = Timer(const Duration(milliseconds: 300), () {
      unawaited(_loadAlarms());
    });
  }

  /// Add new alarm (optimistic update)
  /// Safe async execution - won't block UI
  void addAlarm(AlarmModel alarm) {
    try {
      // Validate alarm before adding
      if (alarm.id.isEmpty) {
        print('❌ Cannot add alarm with empty ID');
        return;
      }
      
      // 1. Update state immediately (optimistic)
      state = [...state, alarm];
      
      // 2. Save to Hive and schedule in background (non-blocking)
      unawaited(_saveAndScheduleAlarm(alarm));
    } catch (e) {
      print('❌ Error adding alarm: $e');
      // Reload to get correct state
      _debouncedReload();
    }
  }

  /// Internal method to save and schedule alarm safely
  Future<void> _saveAndScheduleAlarm(AlarmModel alarm) async {
    try {
      print('💾 [AlarmProvider] Saving alarm to Hive: ${alarm.id}, enabled: ${alarm.isEnabled}');
      
      // Save to Hive first
      await _repo.saveAlarm(alarm);
      print('✅ [AlarmProvider] Alarm saved to Hive');
      
      // Then schedule (this will cancel existing alarm first)
      print('🔔 [AlarmProvider] Calling scheduleAlarm...');
      _repo.scheduleAlarm(alarm);
      print('✅ [AlarmProvider] scheduleAlarm called (async)');
      
      // Debounced reload to ensure consistency
      _debouncedReload();
    } catch (e, stackTrace) {
      print('❌ [AlarmProvider] Error saving/scheduling alarm: $e');
      print('❌ [AlarmProvider] Stack trace: $stackTrace');
      // Reload to get correct state
      _debouncedReload();
    }
  }

  /// Update existing alarm (optimistic update)
  /// Safe async execution - won't block UI
  void updateAlarm(AlarmModel alarm) {
    try {
      // Validate alarm before updating
      if (alarm.id.isEmpty) {
        print('❌ Cannot update alarm with empty ID');
        return;
      }
      
      // 1. Update state immediately (optimistic)
      final index = state.indexWhere((a) => a.id == alarm.id);
      if (index != -1) {
        final updated = [...state];
        updated[index] = alarm;
        state = updated;
      } else {
        // Alarm not found, add it instead
        state = [...state, alarm];
      }
      
      // 2. Save to Hive and schedule in background (non-blocking)
      unawaited(_saveAndScheduleAlarm(alarm));
    } catch (e) {
      print('❌ Error updating alarm: $e');
      // Reload to get correct state
      _debouncedReload();
    }
  }

  /// Delete alarm (optimistic update)
  /// Safe async execution - won't block UI
  void deleteAlarm(String id) {
    // 1. Update state immediately (optimistic)
    state = state.where((a) => a.id != id).toList();
    
    // 2. Cancel alarm and delete from Hive in background (non-blocking)
    unawaited(_cancelAndDeleteAlarm(id));
  }

  /// Internal method to cancel and delete alarm safely
  Future<void> _cancelAndDeleteAlarm(String id) async {
    try {
      // Cancel alarm first
      _repo.cancelAlarm(id);
      
      // Then delete from Hive
      await _repo.deleteAlarm(id);
      
      // Debounced reload to ensure consistency
      _debouncedReload();
    } catch (e) {
      print('❌ Error cancelling/deleting alarm: $e');
      // Reload to get correct state
      _debouncedReload();
    }
  }

  /// Toggle alarm ON/OFF (optimistic update)
  /// CRITICAL: This is called from UI, must be instant and safe
  void toggleAlarm(String id, bool enabled) {
    print('🔔 [AlarmProvider] Toggle alarm called: id=$id, enabled=$enabled');
    
    // 1. Find alarm
    final index = state.indexWhere((a) => a.id == id);
    if (index == -1) {
      print('⚠️ [AlarmProvider] Alarm not found for toggle: $id');
      return;
    }
    
    // 2. Update state immediately (optimistic) - UI responds instantly
    final alarm = state[index];
    print('🔔 [AlarmProvider] Found alarm: ${alarm.id}, current enabled: ${alarm.isEnabled}');
    
    final updated = alarm.copyWith(isEnabled: enabled);
    final newState = [...state];
    newState[index] = updated;
    state = newState;
    
    print('🔔 [AlarmProvider] State updated, new enabled: ${updated.isEnabled}');
    
    // 3. Save to Hive and schedule/cancel in background (non-blocking)
    // scheduleAlarm will cancel existing alarm first, then schedule if enabled
    print('🔔 [AlarmProvider] Starting save and schedule...');
    unawaited(_saveAndScheduleAlarm(updated));
    print('🔔 [AlarmProvider] Toggle alarm completed (async operation started)');
  }
}
