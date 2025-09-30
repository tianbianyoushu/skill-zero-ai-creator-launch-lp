import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/shared_prefs_storage.dart';

class AppSettings {
  final bool notificationsEnabled;
  // minutes from midnight (0-1439) for daily reminder
  final int? dailyReminderMinutes;
  final String localeCode;

  const AppSettings({
    this.notificationsEnabled = false,
    this.dailyReminderMinutes,
    this.localeCode = 'ja',
  });

  Locale get locale => Locale(localeCode);

  TimeOfDay? get dailyReminderTime => dailyReminderMinutes == null
      ? null
      : TimeOfDay(
          hour: (dailyReminderMinutes! ~/ 60) % 24,
          minute: dailyReminderMinutes! % 60,
        );

  AppSettings copyWith({
    bool? notificationsEnabled,
    int? dailyReminderMinutes,
    String? localeCode,
  }) =>
      AppSettings(
        notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
        dailyReminderMinutes: dailyReminderMinutes ?? this.dailyReminderMinutes,
        localeCode: localeCode ?? this.localeCode,
      );

  Map<String, dynamic> toMap() => {
        'notificationsEnabled': notificationsEnabled,
        'dailyReminderMinutes': dailyReminderMinutes,
        'localeCode': localeCode,
      };

  factory AppSettings.fromMap(Map<String, dynamic> map) => AppSettings(
        notificationsEnabled: (map['notificationsEnabled'] as bool?) ?? false,
        dailyReminderMinutes: map['dailyReminderMinutes'] as int?,
        localeCode: (map['localeCode'] as String?) ?? 'ja',
      );
}

class AppSettingsController extends StateNotifier<AppSettings> {
  AppSettingsController() : super(const AppSettings()) {
    _load();
  }

  final _storage = SharedPrefsStorage();

  Future<void> _load() async {
    final loaded = await _storage.loadSettings();
    if (loaded != null) state = loaded;
  }

  Future<void> setNotificationsEnabled(bool value) async {
    state = state.copyWith(notificationsEnabled: value);
    await _storage.saveSettings(state);
  }

  Future<void> setDailyReminderTime(TimeOfDay? time) async {
    final minutes = time == null ? null : time.hour * 60 + time.minute;
    state = state.copyWith(dailyReminderMinutes: minutes);
    await _storage.saveSettings(state);
  }

  Future<void> setLocaleCode(String code) async {
    state = state.copyWith(localeCode: code);
    await _storage.saveSettings(state);
  }
}

final settingsProvider =
    StateNotifierProvider<AppSettingsController, AppSettings>((ref) {
  return AppSettingsController();
});
