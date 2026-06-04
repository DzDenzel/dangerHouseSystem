import 'dart:convert';
import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'detection_repository.dart';

class OfflineDetectionDraft {
  final String id;
  final int buildingId;
  final String? buildingName;
  final String? buildingAddress;
  final String? description;
  final String createdAt;
  final List<String> imagePaths;

  const OfflineDetectionDraft({
    required this.id,
    required this.buildingId,
    this.buildingName,
    this.buildingAddress,
    this.description,
    required this.createdAt,
    required this.imagePaths,
  });

  factory OfflineDetectionDraft.fromJson(Map<String, dynamic> json) {
    return OfflineDetectionDraft(
      id: json['id'] as String,
      buildingId: json['buildingId'] as int,
      buildingName: json['buildingName'] as String?,
      buildingAddress: json['buildingAddress'] as String?,
      description: json['description'] as String?,
      createdAt: json['createdAt'] as String,
      imagePaths: (json['imagePaths'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'buildingId': buildingId,
      'buildingName': buildingName,
      'buildingAddress': buildingAddress,
      'description': description,
      'createdAt': createdAt,
      'imagePaths': imagePaths,
    };
  }
}

class OfflineDetectionRepository {
  OfflineDetectionRepository(this._detectionRepository);

  final DetectionRepository _detectionRepository;

  static const String _draftsKey = 'offline_detection_drafts';

  Future<List<OfflineDetectionDraft>> loadDrafts() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_draftsKey);
    if (raw == null || raw.isEmpty) {
      return const [];
    }

    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .whereType<Map>()
        .map((item) => OfflineDetectionDraft.fromJson(
              item.map((key, value) => MapEntry(key.toString(), value)),
            ))
        .toList();
  }

  Future<int> getPendingCount() async {
    final drafts = await loadDrafts();
    return drafts.length;
  }

  Future<OfflineDetectionDraft> saveDraft({
    required int buildingId,
    String? buildingName,
    String? buildingAddress,
    String? description,
    required List<XFile> images,
  }) async {
    final draftId = DateTime.now().millisecondsSinceEpoch.toString();
    final draftDir = await _getDraftDirectory(draftId);
    final storedPaths = <String>[];

    for (var index = 0; index < images.length; index++) {
      final file = images[index];
      final extension = p.extension(file.name).isNotEmpty ? p.extension(file.name) : '.jpg';
      final targetPath = p.join(draftDir.path, 'image_$index$extension');
      final bytes = await file.readAsBytes();
      await File(targetPath).writeAsBytes(bytes, flush: true);
      storedPaths.add(targetPath);
    }

    final draft = OfflineDetectionDraft(
      id: draftId,
      buildingId: buildingId,
      buildingName: buildingName,
      buildingAddress: buildingAddress,
      description: description,
      createdAt: DateTime.now().toIso8601String(),
      imagePaths: storedPaths,
    );

    final drafts = await loadDrafts();
    final updatedDrafts = [draft, ...drafts];
    await _saveDrafts(updatedDrafts);
    return draft;
  }

  Future<int> syncAllDrafts() async {
    final drafts = await loadDrafts();
    var successCount = 0;

    for (final draft in drafts) {
      final synced = await syncDraft(draft);
      if (synced) {
        successCount++;
      }
    }

    return successCount;
  }

  Future<bool> syncDraft(OfflineDetectionDraft draft) async {
    final imageBytes = <List<int>>[];
    final fileNames = <String>[];

    for (final path in draft.imagePaths) {
      final file = File(path);
      if (!await file.exists()) {
        continue;
      }
      imageBytes.add(await file.readAsBytes());
      fileNames.add(p.basename(path));
    }

    if (imageBytes.isEmpty) {
      return false;
    }

    final detectionId = await _detectionRepository.createDetectionEmpty(
      buildingId: draft.buildingId,
      description: draft.description,
    );
    if (detectionId == null) {
      return false;
    }

    final uploaded = await _detectionRepository.uploadDetectionImages(
      detectionId: detectionId,
      imageBytes: imageBytes,
      fileNames: fileNames,
    );
    if (!uploaded) {
      return false;
    }

    final started = await _detectionRepository.startDetection(detectionId);
    if (started == null) {
      return false;
    }

    await removeDraft(draft.id);
    return true;
  }

  Future<void> removeDraft(String draftId) async {
    final drafts = await loadDrafts();
    final updatedDrafts = drafts.where((draft) => draft.id != draftId).toList();
    await _saveDrafts(updatedDrafts);

    final draftDir = await _getDraftDirectory(draftId);
    if (await draftDir.exists()) {
      await draftDir.delete(recursive: true);
    }
  }

  Future<void> _saveDrafts(List<OfflineDetectionDraft> drafts) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(drafts.map((item) => item.toJson()).toList());
    await prefs.setString(_draftsKey, encoded);
  }

  Future<Directory> _getDraftDirectory(String draftId) async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(appDir.path, 'offline_detection_drafts', draftId));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }
}
