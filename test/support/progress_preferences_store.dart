import 'dart:async';

// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Disk-level failures, including failures reported after the value was written.
class ProgressPreferencesStore extends InMemorySharedPreferencesStore {
  ProgressPreferencesStore() : super.empty();

  String? failKey;
  bool throwFailure = false;
  bool failAfterWrite = false;
  String? holdKey;
  final entered = Completer<void>();
  final release = Completer<void>();

  Future<bool> _run(String key, Future<bool> Function() write) async {
    if (key == 'flutter.$holdKey') {
      holdKey = null;
      entered.complete();
      await release.future;
    }
    if (key != 'flutter.$failKey') return write();
    failKey = null;
    if (failAfterWrite) await write();
    if (throwFailure) throw StateError('Injected disk failure');
    return false;
  }

  @override
  Future<bool> setValue(String valueType, String key, Object value) =>
      _run(key, () => super.setValue(valueType, key, value));

  @override
  Future<bool> remove(String key) => _run(key, () => super.remove(key));
}

ProgressPreferencesStore installProgressPreferencesStore() {
  SharedPreferences.setMockInitialValues({});
  final store = ProgressPreferencesStore();
  SharedPreferencesStorePlatform.instance = store;
  return store;
}
