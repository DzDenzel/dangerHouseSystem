import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/state/base_state.dart';
import '../data/repositories/settings_repository.dart';

final settingsRepositoryProvider = Provider((ref) => SettingsRepository());

final settingsProvider = StateNotifierProvider<SettingsNotifier, SimpleState<Map<String, dynamic>>>((ref) {
  return SettingsNotifier(ref.watch(settingsRepositoryProvider));
});

class SettingsNotifier extends StateNotifier<SimpleState<Map<String, dynamic>>> {
  final SettingsRepository _repository;

  SettingsNotifier(this._repository) : super(const SimpleState.initial()) {
    loadSettings();
  }

  Future<void> loadSettings() async {
    state = const SimpleState.loading();
    try {
      final settings = await _repository.loadSettings();
      state = SimpleState.data(settings);
    } catch (e) {
      state = SimpleState.error(e.toString());
    }
  }

  Future<bool> saveSettings(Map<String, dynamic> settings) async {
    final previousState = state;
    state = SimpleState.data(settings);
    try {
      await _repository.saveSettings(settings);
      return true;
    } catch (e) {
      state = previousState;
      state = SimpleState.error(e.toString());
      return false;
    }
  }

  Future<bool> updateSetting(String key, dynamic value) async {
    final currentSettings = state.data ?? {};
    final newSettings = {...currentSettings, key: value};
    return await saveSettings(newSettings);
  }

  void reset() {
    state = const SimpleState.initial();
  }
}

final settingsDataProvider = Provider<Map<String, dynamic>?>((ref) {
  final state = ref.watch(settingsProvider);
  return state.data;
});

final settingsLoadingProvider = Provider<bool>((ref) {
  final state = ref.watch(settingsProvider);
  return state.isLoading;
});

final settingsErrorProvider = Provider<String?>((ref) {
  final state = ref.watch(settingsProvider);
  return state.error;
});
