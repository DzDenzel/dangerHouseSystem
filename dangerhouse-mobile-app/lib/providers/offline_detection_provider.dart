import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/providers/network_providers.dart';
import '../core/state/base_state.dart';
import '../data/repositories/offline_detection_repository.dart';

class OfflineDetectionNotifier extends StateNotifier<SimpleState<List<OfflineDetectionDraft>>> {
  OfflineDetectionNotifier(this._repository) : super(const SimpleState.initial()) {
    loadDrafts();
  }

  final OfflineDetectionRepository _repository;

  Future<void> loadDrafts() async {
    state = const SimpleState.loading();
    try {
      final drafts = await _repository.loadDrafts();
      state = SimpleState.data(drafts);
    } catch (e) {
      state = SimpleState.error(e.toString());
    }
  }

  Future<int> syncAllDrafts() async {
    final synced = await _repository.syncAllDrafts();
    await loadDrafts();
    return synced;
  }
}

final offlineDetectionNotifierProvider =
    StateNotifierProvider<OfflineDetectionNotifier, SimpleState<List<OfflineDetectionDraft>>>((ref) {
  final repository = ref.watch(offlineDetectionRepositoryProvider);
  return OfflineDetectionNotifier(repository);
});

final offlineDetectionDraftCountProvider = Provider<int>((ref) {
  final state = ref.watch(offlineDetectionNotifierProvider);
  return state.data?.length ?? 0;
});
