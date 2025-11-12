import 'dart:async';

import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences/util/legacy_to_async_migration_util.dart';

class SharedPreferencesController extends GetxController {
  static const allowedList = <String>{
    'sessionEnd',
    'sessionRunning',
    'sessionPayload',
    'sessionNotifID',
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
