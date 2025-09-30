import 'dart:convert';

import '../../features/cravings/craving.dart';
import '../../features/quit/profile.dart';
import '../../features/settings/app_settings.dart';

abstract class AppStorage {
  Future<void> saveProfile(QuitProfile profile);
  Future<QuitProfile?> loadProfile();

  Future<void> saveCravings(List<Craving> list);
  Future<List<Craving>> loadCravings();

  Future<void> saveSettings(AppSettings settings);
  Future<AppSettings?> loadSettings();
}

// Simple JSON helpers
Map<String, dynamic> decodeJson(String source) =>
    json.decode(source) as Map<String, dynamic>;

String encodeJson(Map<String, dynamic> map) => json.encode(map);

