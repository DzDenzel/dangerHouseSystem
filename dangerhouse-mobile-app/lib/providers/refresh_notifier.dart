import 'package:flutter_riverpod/flutter_riverpod.dart';

enum RefreshEventType {
  buildingCreated,
  buildingUpdated,
  buildingDeleted,
  detectionCreated,
  detectionUpdated,
  detectionDeleted,
  all,
}

class RefreshEvent {
  final RefreshEventType type;
  final DateTime timestamp;
  final Map<String, dynamic>? data;

  RefreshEvent({
    required this.type,
    Map<String, dynamic>? data,
  })  : timestamp = DateTime.now(),
        data = data ?? {};

  @override
  String toString() => 'RefreshEvent(type: $type, timestamp: $timestamp)';
}

class RefreshNotifier extends StateNotifier<RefreshEvent?> {
  RefreshNotifier() : super(null);

  void notify(RefreshEventType type, {Map<String, dynamic>? data}) {
    state = RefreshEvent(type: type, data: data);
  }

  void notifyBuildingCreated({int? buildingId}) {
    notify(RefreshEventType.buildingCreated, data: {'buildingId': buildingId});
  }

  void notifyBuildingUpdated({int? buildingId}) {
    notify(RefreshEventType.buildingUpdated, data: {'buildingId': buildingId});
  }

  void notifyBuildingDeleted({int? buildingId}) {
    notify(RefreshEventType.buildingDeleted, data: {'buildingId': buildingId});
  }

  void notifyDetectionCreated({int? detectionId}) {
    notify(RefreshEventType.detectionCreated, data: {'detectionId': detectionId});
  }

  void notifyDetectionUpdated({int? detectionId}) {
    notify(RefreshEventType.detectionUpdated, data: {'detectionId': detectionId});
  }

  void notifyDetectionDeleted({int? detectionId}) {
    notify(RefreshEventType.detectionDeleted, data: {'detectionId': detectionId});
  }

  void notifyRefreshAll() {
    notify(RefreshEventType.all);
  }

  void clear() {
    state = null;
  }
}

final refreshNotifierProvider = StateNotifierProvider<RefreshNotifier, RefreshEvent?>(
  (ref) => RefreshNotifier(),
);
