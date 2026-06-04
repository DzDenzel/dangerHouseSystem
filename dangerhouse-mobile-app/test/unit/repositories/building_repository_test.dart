import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dangerhouse_app/data/models/building_models.dart';
import 'package:dangerhouse_app/data/repositories/building_repository.dart';
import 'package:dangerhouse_app/data/sources/building_remote_data_source.dart';
import 'package:dangerhouse_app/core/errors/exceptions.dart';
import 'package:dangerhouse_app/core/errors/error_handler.dart';

class MockBuildingRemoteDataSource extends Mock
    implements BuildingRemoteDataSource {}

class FakeCreateBuildingRequest extends Fake implements CreateBuildingRequest {}

class FakeUpdateBuildingRequest extends Fake implements UpdateBuildingRequest {}

void main() {
  late BuildingRepositoryImpl repository;
  late MockBuildingRemoteDataSource mockRemoteDataSource;

  setUpAll(() {
    registerFallbackValue(FakeCreateBuildingRequest());
    registerFallbackValue(FakeUpdateBuildingRequest());
    ErrorHandler.setEnableToast(false);
  });

  tearDownAll(() {
    ErrorHandler.setEnableToast(true);
  });

  setUp(() {
    mockRemoteDataSource = MockBuildingRemoteDataSource();
    repository = BuildingRepositoryImpl(remoteDataSource: mockRemoteDataSource);
  });

  group('BuildingRepository', () {
    const testBuilding = Building(
      id: 1,
      name: 'Test Building',
      address: 'Test Address',
      structureType: 'CONCRETE',
      initialRiskLevel: 'LOW',
    );

    group('getBuildings', () {
      test('returns list of buildings on success', () async {
        final List<Building> buildings = [testBuilding];

        when(() => mockRemoteDataSource.getBuildings(
              query: any(named: 'query'),
              page: any(named: 'page'),
              size: any(named: 'size'),
              address: any(named: 'address'),
              riskLevels: any(named: 'riskLevels'),
            )).thenAnswer((_) async => buildings);

        final result = await repository.getBuildings(page: 1, size: 10);

        expect(result, hasLength(1));
        expect(result.first.name, equals('Test Building'));
      });

      test('returns empty list on error', () async {
        when(() => mockRemoteDataSource.getBuildings(
              query: any(named: 'query'),
              page: any(named: 'page'),
              size: any(named: 'size'),
              address: any(named: 'address'),
              riskLevels: any(named: 'riskLevels'),
            )).thenThrow(const ServerException('Network error'));

        final result = await repository.getBuildings(page: 1, size: 10);

        expect(result, isEmpty);
      });

      test('filters by risk levels', () async {
        final List<Building> buildings = [testBuilding];
        final riskLevels = ['LOW', 'MEDIUM'];

        when(() => mockRemoteDataSource.getBuildings(
              query: any(named: 'query'),
              page: any(named: 'page'),
              size: any(named: 'size'),
              address: any(named: 'address'),
              riskLevels: riskLevels,
            )).thenAnswer((_) async => buildings);

        final result =
            await repository.getBuildings(page: 1, size: 10, riskLevels: riskLevels);

        expect(result, hasLength(1));
        verify(() => mockRemoteDataSource.getBuildings(
              query: null,
              page: 1,
              size: 10,
              address: null,
              riskLevels: riskLevels,
            )).called(1);
      });
    });

    group('getBuildingById', () {
      test('returns building on success', () async {
        when(() => mockRemoteDataSource.getBuildingById(1))
            .thenAnswer((_) async => testBuilding);

        final result = await repository.getBuildingById(1);

        expect(result, isNotNull);
        expect(result!.id, equals(1));
        expect(result.name, equals('Test Building'));
      });

      test('returns null on error', () async {
        when(() => mockRemoteDataSource.getBuildingById(999))
            .thenThrow(const NotFoundException('Building not found'));

        final result = await repository.getBuildingById(999);

        expect(result, isNull);
      });
    });

    group('createBuilding', () {
      test('returns created building on success', () async {
        const request = CreateBuildingRequest(
          name: 'New Building',
          address: 'New Address',
          structureType: 'CONCRETE',
        );

        when(() => mockRemoteDataSource.createBuilding(request))
            .thenAnswer((_) async => testBuilding);

        final result = await repository.createBuilding(request);

        expect(result, isNotNull);
        expect(result!.name, equals('Test Building'));
        verify(() => mockRemoteDataSource.createBuilding(request)).called(1);
      });

      test('returns null on creation error', () async {
        const request = CreateBuildingRequest(
          name: 'Invalid Building',
          address: '',
          structureType: 'CONCRETE',
        );

        when(() => mockRemoteDataSource.createBuilding(request))
            .thenThrow(const ValidationException('地址不能为空'));

        final result = await repository.createBuilding(request);

        expect(result, isNull);
      });
    });

    group('updateBuilding', () {
      test('returns updated building on success', () async {
        const request = UpdateBuildingRequest(
          name: 'Updated Building',
          address: 'Updated Address',
        );

        const updatedBuilding = Building(
          id: 1,
          name: 'Updated Building',
          address: 'Updated Address',
          structureType: 'CONCRETE',
        );

        when(() => mockRemoteDataSource.updateBuilding(1, request))
            .thenAnswer((_) async => updatedBuilding);

        final result = await repository.updateBuilding(1, request);

        expect(result, isNotNull);
        expect(result!.name, equals('Updated Building'));
      });

      test('returns null on update error', () async {
        const request = UpdateBuildingRequest(name: 'Updated');

        when(() => mockRemoteDataSource.updateBuilding(999, request))
            .thenThrow(const NotFoundException('Building not found'));

        final result = await repository.updateBuilding(999, request);

        expect(result, isNull);
      });
    });

    group('deleteBuilding', () {
      test('returns true on successful deletion', () async {
        when(() => mockRemoteDataSource.deleteBuilding(1))
            .thenAnswer((_) async {});

        final result = await repository.deleteBuilding(1);

        expect(result, isTrue);
        verify(() => mockRemoteDataSource.deleteBuilding(1)).called(1);
      });

      test('returns false on deletion error', () async {
        when(() => mockRemoteDataSource.deleteBuilding(999))
            .thenThrow(const NotFoundException('Building not found'));

        final result = await repository.deleteBuilding(999);

        expect(result, isFalse);
      });
    });

    group('searchBuildings', () {
      test('returns matching buildings on success', () async {
        final List<Building> buildings = [testBuilding];

        when(() => mockRemoteDataSource.searchBuildings('Test'))
            .thenAnswer((_) async => buildings);

        final result = await repository.searchBuildings('Test');

        expect(result, hasLength(1));
        expect(result.first.name, contains('Test'));
      });

      test('returns empty list on search error', () async {
        when(() => mockRemoteDataSource.searchBuildings('Test'))
            .thenThrow(const ServerException('Network error'));

        final result = await repository.searchBuildings('Test');

        expect(result, isEmpty);
      });
    });
  });
}
