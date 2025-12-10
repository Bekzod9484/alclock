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

  AlarmListController(this._repo) : super([]) {
    // Load initial data in background - use Future.microtask to avoid blocking
    Future.microtask(() => _loadAlarms());
  }

  /// Load alarms from repository (background)
  Future<void> _loadAlarms() async {
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
    }
  }

  /// Add new alarm (optimistic update)
  void addAlarm(AlarmModel alarm) {
    try {
      // Validate alarm before adding
      if (alarm.id.isEmpty) {
        print('❌ Cannot add alarm with empty ID');
        return;
      }
      
      // 1. Update state immediately (optimistic)
      state = [...state, alarm];
      
      // 2. Save to Hive in background
      unawaited(_repo.saveAlarm(alarm).catchError((e) {
        print('❌ Error saving alarm: $e');
        // Reload to get correct state
        unawaited(_loadAlarms());
      }));
      
      // 3. Schedule in background
      _repo.scheduleAlarm(alarm);
      
      // 4. Reload from storage in background to ensure consistency
      unawaited(_loadAlarms());
    } catch (e) {
      print('❌ Error adding alarm: $e');
      // Reload to get correct state
      unawaited(_loadAlarms());
    }
  }

  /// Update existing alarm (optimistic update)
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
      
      // 2. Save to Hive in background
      unawaited(_repo.saveAlarm(alarm).catchError((e) {
        print('❌ Error saving alarm: $e');
        // Reload to get correct state
        unawaited(_loadAlarms());
      }));
      
      // 3. Schedule in background
      _repo.scheduleAlarm(alarm);
      
      // 4. Reload from storage in background
      unawaited(_loadAlarms());
    } catch (e) {
      print('❌ Error updating alarm: $e');
      // Reload to get correct state
      unawaited(_loadAlarms());
    }
  }

  /// Delete alarm (optimistic update)
  void deleteAlarm(String id) {
    // 1. Update state immediately (optimistic)
    state = state.where((a) => a.id != id).toList();
    
    // 2. Cancel alarm in background
    _repo.cancelAlarm(id);
    
    // 3. Delete from Hive in background
    unawaited(_repo.deleteAlarm(id));
    
    // 4. Reload from storage in background
    unawaited(_loadAlarms());
  }

  /// Toggle alarm ON/OFF (optimistic update)
  void toggleAlarm(String id, bool enabled) {
    // 1. Find alarm
    final index = state.indexWhere((a) => a.id == id);
    if (index == -1) return;
    
    // 2. Update state immediately (optimistic)
    final alarm = state[index];
    final updated = alarm.copyWith(isEnabled: enabled);
    final newState = [...state];
    newState[index] = updated;
    state = newState;
    
    // 3. Save to Hive in background
    unawaited(_repo.saveAlarm(updated));
    
    // 4. Schedule or cancel in background
    _repo.scheduleAlarm(updated);
    
    // 5. Reload from storage in background
    unawaited(_loadAlarms());
  }
}
