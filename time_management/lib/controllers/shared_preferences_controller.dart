import 'dart:async';

import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences/util/legacy_to_async_migration_util.dart';

class SharedPreferencesController extends GetxController {
  static const String SESSION_END = 'session_end';
  static const String SESSION_RUNNING = 'sessionRunning';
  static const String SESSION_PAYLOAD = 'sessionPayload';
  static const String SESSION_NOTIF = 'sessionNotifID';
  static const allowedList = <String>{
    SESSION_END,
    SESSION_RUNNING,
    SESSION_PAYLOAD,
    SESSION_NOTIF,
  };

  final Future<SharedPreferencesWithCache> _prefs =
      SharedPreferencesWithCache.create(
          cacheOptions:
              const SharedPreferencesWithCacheOptions(allowList: allowedList));
  final Completer<void> _preferencesReady = Completer<void>();

  @override
  onInit() {
    super.onInit();
    _migratePreferences();
    _preferencesReady.complete();
  }

  Future<bool> getStatus() async {
    return _preferencesReady.isCompleted;
  }

  Future<bool> updateValue(String key, String value) async {
    final SharedPreferencesWithCache pref = await _prefs;
    try {
      await pref.setString(key, value);
    } on Exception catch (e) {
      return false;
    }
    return true;
  }

  Future<Map<String, String>> getSessionPref() async {
    Map<String, String> cache = {};
    for (String text in allowedList) {
      cache[text] = (await getValue(text)) ?? '';
    }
    return cache;
  }

  Future<Map<String, String>> getSessionPayload(
      Map<String, String> cache) async {
    List<String> payloadSplit =
        (cache[SharedPreferencesController.allowedList.elementAt(2)] ?? '')
            .split('|');
    Map<String, String> args =
        Map.fromEntries(payloadSplit.map<MapEntry<String, String>>((String e) {
      List<String> data = e.split(":");
      if (data.length == 2) {
        return MapEntry(data[0], data[1]);
      } else {
        return MapEntry(e, e);
      }
    }));
    return args;
  }

  Future<String?> getValue(String key) async {
    final SharedPreferencesWithCache pref = await _prefs;
    try {
      return pref.getString(key);
    } on Exception catch (e) {
      return null;
    }
  }

  Future<void> _migratePreferences() async {
    // #docregion migrate
    const SharedPreferencesOptions sharedPreferencesOptions =
        SharedPreferencesOptions();
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await migrateLegacySharedPreferencesToSharedPreferencesAsyncIfNecessary(
      legacySharedPreferencesInstance: prefs,
      sharedPreferencesAsyncOptions: sharedPreferencesOptions,
      migrationCompletedKey: 'migrationCompleted',
    );
    // #enddocregion migrate
  }
}
