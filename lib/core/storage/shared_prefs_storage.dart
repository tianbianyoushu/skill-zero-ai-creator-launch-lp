import 'package:shared_preferences/shared_preferences.dart';

import '../../features/cravings/craving.dart';
import '../../features/quit/profile.dart';
import '../../features/settings/app_settings.dart';
import 'storage.dart';

class SharedPrefsStorage implements AppStorage {
  static const _kProfile = 'profile';
  static const _kCravings = 'cravings';
  static const _kSettings = 'settings';

  Future<SharedPreferences> get _prefs async => SharedPreferences.getInstance();

  @override
  Future<QuitProfile?> loadProfile() async {
    final p = await _prefs;
    final data = p.getString(_kProfile);
    if (data == null) return null;
    final map = decodeJson(data);
    return QuitProfile.fromMap(map);
  }

  @override
  Future<void> saveProfile(QuitProfile profile) async {
    final p = await _prefs;
    await p.setString(_kProfile, encodeJson(profile.toMap()));
  }

  @override
  Future<List<Craving>> loadCravings() async {
    final p = await _prefs;
    final data = p.getStringList(_kCravings) ?? const [];
    return data
        .map((s) => Craving.fromMap(decodeJson(s)))
        .toList(growable: false);
  }

  @override
  Future<void> saveCravings(List<Craving> list) async {
    final p = await _prefs;
    final encoded = list.map((c) => encodeJson(c.toMap())).toList();
    await p.setStringList(_kCravings, encoded);
  }

  @override
  Future<AppSettings?> loadSettings() async {
    final p = await _prefs;
    final data = p.getString(_kSettings);
    if (data == null) return null;
    return AppSettings.fromMap(decodeJson(data));
  }

  @override
  Future<void> saveSettings(AppSettings settings) async {
    final p = await _prefs;
    await p.setString(_kSettings, encodeJson(settings.toMap()));
  }
}

