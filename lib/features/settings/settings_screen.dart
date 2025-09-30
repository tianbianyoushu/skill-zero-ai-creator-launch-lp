import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/options.dart';
import '../../core/l10n/l10n.dart';
import '../../core/notifications/notification_service.dart';
import '../quit/profile.dart';
import 'app_settings.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final settings = ref.watch(settingsProvider);
    final profile = ref.watch(profileProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        children: [
          SwitchListTile(
            secondary: const Icon(Icons.notifications_active_outlined),
            title: Text(l10n.settingsEnableNotifications),
            value: settings.notificationsEnabled,
            onChanged: (v) async {
              if (v) {
                final granted = await NotificationService.instance.requestPermissions();
                if (!granted) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.settingsNotificationsPermissionDenied)),
                    );
                  }
                  return;
                }
                await NotificationService.instance.init();
              } else {
                await NotificationService.instance.cancelAll();
              }
              await ref.read(settingsProvider.notifier).setNotificationsEnabled(v);
            },
          ),
          Builder(builder: (context) {
            final time = settings.dailyReminderTime;
            final enabled = settings.notificationsEnabled;
            final subtitle = time == null
                ? l10n.settingsDailyReminderUnset
                : l10n.settingsDailyReminderSubtitle(
                    '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                  );
            return ListTile(
              leading: const Icon(Icons.schedule),
              title: Text(l10n.settingsDailyReminderTitle),
              subtitle: Text(subtitle),
              onTap: () async {
                if (!enabled) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.settingsEnableNotificationsFirst)),
                  );
                  return;
                }
                final initial = time ?? const TimeOfDay(hour: 9, minute: 0);
                final picked = await showTimePicker(context: context, initialTime: initial);
                if (picked != null) {
                  await ref.read(settingsProvider.notifier).setDailyReminderTime(picked);
                  await NotificationService.instance.scheduleDailyAt(
                    picked,
                    title: l10n.notificationDailyTitle,
                    body: l10n.notificationDailyBody,
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content:
                            Text(l10n.settingsDailyReminderSet(picked.format(context))),
                      ),
                    );
                  }
                }
              },
              trailing: time != null
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      tooltip: l10n.settingsReminderClear,
                      onPressed: () async {
                        await ref.read(settingsProvider.notifier).setDailyReminderTime(null);
                        await NotificationService.instance.cancelReminder();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(l10n.settingsDailyReminderCleared)),
                          );
                        }
                      },
                    )
                  : null,
            );
          }),
          ListTile(
            leading: const Icon(Icons.notification_important_outlined),
            title: Text(l10n.settingsSendTestNotification),
            onTap: () async {
              await NotificationService.instance.showSimple(
                title: l10n.notificationTestTitle,
                body: l10n.notificationTestBody,
              );
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(l10n.settingsLanguageTitle),
            subtitle: Text(localizedLanguageName(l10n, settings.localeCode)),
            trailing: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: settings.localeCode,
                items: [
                  for (final code in supportedLanguageCodes)
                    DropdownMenuItem(
                      value: code,
                      child: Text(localizedLanguageName(l10n, code)),
                    ),
                ],
                onChanged: (code) async {
                  if (code == null || code == settings.localeCode) return;
                  await ref.read(settingsProvider.notifier).setLocaleCode(code);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.settingsLanguageUpdated)),
                    );
                  }
                },
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.public),
            title: Text(l10n.settingsCountryTitle),
            subtitle: Text(localizedCountryName(l10n, profile.countryCode)),
            trailing: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: profile.countryCode,
                items: [
                  for (final code in supportedCountryCodes)
                    DropdownMenuItem(
                      value: code,
                      child: Text(localizedCountryName(l10n, code)),
                    ),
                ],
                onChanged: (code) async {
                  if (code == null || code == profile.countryCode) return;
                  ref.read(profileProvider.notifier).updateCountry(code);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.settingsCountryUpdated)),
                    );
                  }
                },
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.currency_exchange),
            title: Text(l10n.settingsCurrencyTitle),
            subtitle: Text(localizedCurrencyName(l10n, profile.currencyCode)),
            trailing: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: profile.currencyCode,
                items: [
                  for (final code in supportedCurrencyCodes)
                    DropdownMenuItem(
                      value: code,
                      child: Text(localizedCurrencyName(l10n, code)),
                    ),
                ],
                onChanged: (code) async {
                  if (code == null || code == profile.currencyCode) return;
                  ref.read(profileProvider.notifier).updateCurrency(code);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.settingsCurrencyUpdated)),
                    );
                  }
                },
              ),
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.refresh),
            title: Text(l10n.settingsResetProfile),
            subtitle: Text(l10n.settingsResetProfileSubtitle),
            onTap: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: Text(l10n.settingsResetConfirmTitle),
                  content: Text(l10n.settingsResetConfirmMessage),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(l10n.commonCancel),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: Text(l10n.settingsResetAction),
                    )
                  ],
                ),
              );
              if (ok == true) {
                ref.read(profileProvider.notifier).reset();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.settingsResetSuccess)),
                  );
                }
              }
            },
          ),
          const Divider(height: 1),
          AboutListTile(
            icon: Icon(Icons.info_outline),
            applicationName: l10n.appTitle,
            applicationVersion: '0.1.0',
            applicationLegalese: l10n.aboutLegalese,
          ),
        ],
      ),
    );
  }
}
