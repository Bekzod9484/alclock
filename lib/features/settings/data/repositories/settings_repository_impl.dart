import '../../../../core/models/settings_model.dart';
import '../../../../services/hive_service.dart';
import '../../domain/repositories/settings_repository.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  final HiveService _hiveService;

  SettingsRepositoryImpl(this._hiveService);

  @override
  Future<SettingsModel> getSettings() async {
    return await _hiveService.getSettings();
  }

  @override
  Future<void> saveSettings(SettingsModel settings) async {
    await _hiveService.saveSettings(settings);
  }
}

