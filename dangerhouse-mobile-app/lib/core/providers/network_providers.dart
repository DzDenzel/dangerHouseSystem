import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/task_repository.dart';
import '../../data/repositories/detection_repository.dart';
import '../../data/repositories/building_repository.dart';
import '../../data/repositories/system_repository.dart';
import '../../data/repositories/report_repository.dart';
import '../../data/repositories/offline_detection_repository.dart';
import '../../data/sources/auth_remote_data_source.dart';
import '../../data/sources/building_remote_data_source.dart';
import '../../data/sources/detection_remote_data_source.dart';
import '../network/dio_client.dart';

final dioClientProvider = Provider<DioClient>((ref) {
  return DioClient();
});

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return AuthRemoteDataSourceImpl(dioClient: dioClient);
});

final buildingRemoteDataSourceProvider = Provider<BuildingRemoteDataSource>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return BuildingRemoteDataSourceImpl(dioClient: dioClient);
});

final detectionRemoteDataSourceProvider = Provider<DetectionRemoteDataSource>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return DetectionRemoteDataSourceImpl(dioClient: dioClient);
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final remoteDataSource = ref.watch(authRemoteDataSourceProvider);
  return AuthRepositoryImpl(remoteDataSource: remoteDataSource);
});

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return TaskRepository(dioClient);
});

final detectionRepositoryProvider = Provider<DetectionRepository>((ref) {
  final remoteDataSource = ref.watch(detectionRemoteDataSourceProvider);
  return DetectionRepositoryImpl(remoteDataSource: remoteDataSource);
});

final buildingRepositoryProvider = Provider<BuildingRepository>((ref) {
  final remoteDataSource = ref.watch(buildingRemoteDataSourceProvider);
  return BuildingRepositoryImpl(remoteDataSource: remoteDataSource);
});

final systemRepositoryProvider = Provider<SystemRepository>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return SystemRepository(dioClient);
});

final reportRepositoryProvider = Provider<ReportRepository>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return ReportRepository(dioClient);
});

final offlineDetectionRepositoryProvider = Provider<OfflineDetectionRepository>((ref) {
  final detectionRepository = ref.watch(detectionRepositoryProvider);
  return OfflineDetectionRepository(detectionRepository);
});
