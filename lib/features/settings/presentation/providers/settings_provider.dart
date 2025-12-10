import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/settings_model.dart';
import '../../../../core/providers/shared_providers.dart';
import '../../data/repositories/settings_repository_impl.dart';
import '../../domain/repositories/settings_repository.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  final hiveService = ref.watch(initializedHiveServiceProvider);
  return SettingsRepositoryImpl(hiveService);
});

final settingsProvider = FutureProvider<SettingsModel>((ref) async {
  final repository = ref.watch(settingsRepositoryProvider);
  return await repository.getSettings();
});

