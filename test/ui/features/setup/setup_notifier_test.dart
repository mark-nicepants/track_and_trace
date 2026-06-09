import 'dart:convert';

import 'package:app/data/repositories/track_and_trace_repository.dart';
import 'package:app/data/services/in_memory_preference_service.dart';
import 'package:app/domain/entities/machine_type.dart';
import 'package:app/shared/inject.dart';
import 'package:app/ui/features/setup/setup_keys.dart';
import 'package:app/ui/features/setup/setup_notifier.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart' hide Matcher;

import '../../../helpers/di_test_helper.dart';

void main() {
  late Dio dio;
  late DioAdapter adapter;
  late InMemoryPreferenceService prefs;

  setUp(() async {
    dio = Dio(BaseOptions(baseUrl: 'http://test.local'));
    adapter = DioAdapter(dio: dio);
    prefs = InMemoryPreferenceService();
    await setupTestDi(dio: dio, prefs: prefs);
    injector.registerSingleton<TrackAndTraceRepository>(TrackAndTraceRepository());
  });

  tearDown(tearDownTestDi);

  void replyMachineTypes(List<Map<String, Object?>> body) {
    adapter.onPost('/get-machine-types', (server) => server.reply(200, body));
  }

  void networkError() {
    adapter.onPost(
      '/get-machine-types',
      (server) => server.throws(
        0,
        DioException(
          requestOptions: RequestOptions(path: '/get-machine-types'),
          type: DioExceptionType.connectionError,
        ),
      ),
    );
  }

  test('build() loads machine types from the network and caches them', () async {
    replyMachineTypes([
      {'id': 'mt-1', 'displayName': 'Loader'},
      {'id': 'mt-2', 'displayName': 'Truck'},
    ]);

    final container = ProviderContainer();
    addTearDown(container.dispose);

    final state = await container.read(setupProvider.future);
    expect(state.machineTypes, hasLength(2));
    expect(state.fromCache, isFalse);
    expect(state.selectedType, isNull);
    expect(state.capacity, isNull);

    final cached = await prefs.readString(machineTypesCacheKey);
    expect(cached, isNotNull);
    final decoded = jsonDecode(cached!) as List<Object?>;
    expect(decoded, hasLength(2));
  });

  test('build() falls back to cached list on network failure and flags fromCache', () async {
    await prefs.writeString(
      machineTypesCacheKey,
      jsonEncode([
        {'id': 'cached-1', 'displayName': 'Cached Loader'},
      ]),
    );
    networkError();

    final container = ProviderContainer();
    addTearDown(container.dispose);

    final state = await container.read(setupProvider.future);
    expect(state.machineTypes, hasLength(1));
    expect(state.machineTypes.first.id, 'cached-1');
    expect(state.fromCache, isTrue);
  });

  test('build() with no cache + network failure returns empty list (not fromCache)', () async {
    networkError();

    final container = ProviderContainer();
    addTearDown(container.dispose);

    final state = await container.read(setupProvider.future);
    expect(state.machineTypes, isEmpty);
    expect(state.fromCache, isFalse);
  });

  test('build() pre-populates saved type + capacity', () async {
    await prefs.writeString(machineTypeKey, jsonEncode({'id': 'mt-2', 'displayName': 'Truck'}));
    await prefs.writeString(machineCapacityKey, '14.5');
    replyMachineTypes([
      {'id': 'mt-1', 'displayName': 'Loader'},
      {'id': 'mt-2', 'displayName': 'Truck'},
    ]);

    final container = ProviderContainer();
    addTearDown(container.dispose);

    final state = await container.read(setupProvider.future);
    expect(state.selectedType?.id, 'mt-2');
    // Saved type is matched against the fresh list (same instance from the
    // fresh DTOs), so equality must hold.
    expect(state.machineTypes.contains(state.selectedType), isTrue);
    expect(state.capacity, 14.5);
  });

  test('selectType updates selectedType', () async {
    replyMachineTypes([
      {'id': 'mt-1', 'displayName': 'Loader'},
    ]);

    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container.read(setupProvider.future);
    container.read(setupProvider.notifier).selectType(MachineType('mt-1', 'Loader'));

    final state = container.read(setupProvider).value!;
    expect(state.selectedType?.id, 'mt-1');
  });

  test('setCapacity updates capacity', () async {
    replyMachineTypes(const []);
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container.read(setupProvider.future);
    container.read(setupProvider.notifier).setCapacity(12.5);

    expect(container.read(setupProvider).value!.capacity, 12.5);
  });

  test('confirm() persists machine type + capacity and returns true', () async {
    replyMachineTypes([
      {'id': 'mt-1', 'displayName': 'Loader'},
    ]);

    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container.read(setupProvider.future);
    final notifier = container.read(setupProvider.notifier);
    notifier.selectType(MachineType('mt-1', 'Loader'));
    notifier.setCapacity(20);

    final saved = await notifier.confirm();
    expect(saved, isTrue);

    final type = await prefs.readString(machineTypeKey);
    expect(type, isNotNull);
    final decoded = jsonDecode(type!) as Map<String, Object?>;
    expect(decoded['id'], 'mt-1');
    expect(decoded['displayName'], 'Loader');

    final capacity = await prefs.readString(machineCapacityKey);
    expect(double.parse(capacity!), 20.0);
  });

  test('confirm() without selection returns false and writes nothing', () async {
    replyMachineTypes(const []);
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container.read(setupProvider.future);
    final saved = await container.read(setupProvider.notifier).confirm();
    expect(saved, isFalse);
    expect(await prefs.readString(machineTypeKey), isNull);
    expect(await prefs.readString(machineCapacityKey), isNull);
  });
}
