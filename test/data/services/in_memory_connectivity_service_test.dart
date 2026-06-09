import '../../helpers/fakes/in_memory_connectivity_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('initial state is online when constructed without args', () async {
    final s = InMemoryConnectivityService();
    expect(await s.check(), isTrue);
  });

  test('initial=false reports offline', () async {
    final s = InMemoryConnectivityService(initial: false);
    expect(await s.check(), isFalse);
  });

  test('emit updates both the stream and check()', () async {
    final s = InMemoryConnectivityService();
    final events = <bool>[];
    final sub = s.changes.listen(events.add);

    s
      ..emit(false)
      ..emit(true)
      ..emit(false);

    await Future<void>.delayed(Duration.zero);
    expect(events, [false, true, false]);
    expect(await s.check(), isFalse);

    await sub.cancel();
  });

  test('broadcast stream supports multiple subscribers', () async {
    final s = InMemoryConnectivityService();
    final a = <bool>[];
    final b = <bool>[];
    final subA = s.changes.listen(a.add);
    final subB = s.changes.listen(b.add);

    s.emit(false);
    await Future<void>.delayed(Duration.zero);

    expect(a, [false]);
    expect(b, [false]);

    await subA.cancel();
    await subB.cancel();
  });
}
