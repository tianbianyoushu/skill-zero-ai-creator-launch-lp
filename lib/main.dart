import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'core/app_router.dart';
import 'core/notifications/milestone_messages.dart';
import 'core/notifications/notification_service.dart';
import 'core/theme.dart';
import 'features/quit/profile.dart';
import 'features/settings/app_settings.dart';

void main() {
  runApp(const ProviderScope(child: App()));
}

class App extends ConsumerStatefulWidget {
  const App({super.key});

  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App> {
  late final ProviderSubscription<AppSettings> _settingsSubscription;
  late final ProviderSubscription<QuitProfile> _profileSubscription;

  @override
  void initState() {
    super.initState();
    _settingsSubscription = ref.listen<AppSettings>(
      settingsProvider,
      (previous, next) {
        Future.microtask(() => _handleSettingsChanged(next));
      },
      fireImmediately: true,
    );

    _profileSubscription = ref.listen<QuitProfile>(
      profileProvider,
      (previous, next) {
        Future.microtask(() => _handleProfileChanged(next));
      },
      fireImmediately: true,
    );
  }

  Future<void> _handleSettingsChanged(AppSettings settings) async {
    if (!settings.notificationsEnabled) {
      await NotificationService.instance.cancelAll();
      return;
    }

    await NotificationService.instance.init();

    final l10n = await AppLocalizations.delegate.load(settings.locale);
    final time = settings.dailyReminderTime;
    if (time != null) {
      await NotificationService.instance.scheduleDailyAt(
        time,
        title: l10n.notificationDailyTitle,
        body: l10n.notificationDailyBody,
      );
    } else {
      await NotificationService.instance.cancelReminder();
    }

    final profile = ref.read(profileProvider);
    if (profile.quitDate != null) {
      final milestones = buildMilestoneNotifications(l10n);
      await NotificationService.instance.scheduleMilestones(
        profile.quitDate!,
        milestones: milestones,
        title: l10n.notificationMilestoneTitle,
      );
    }
  }

  Future<void> _handleProfileChanged(QuitProfile profile) async {
    final settings = ref.read(settingsProvider);
    if (!settings.notificationsEnabled) return;
    if (profile.quitDate != null) {
      await NotificationService.instance.init();
      final l10n = await AppLocalizations.delegate.load(settings.locale);
      final milestones = buildMilestoneNotifications(l10n);
      await NotificationService.instance.scheduleMilestones(
        profile.quitDate!,
        milestones: milestones,
        title: l10n.notificationMilestoneTitle,
      );
    } else {
      await NotificationService.instance.cancelMilestones();
    }
  }

  @override
  void dispose() {
    _settingsSubscription.close();
    _profileSubscription.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    final settings = ref.watch(settingsProvider);
    return MaterialApp.router(
      title: 'Quit Smoking',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      locale: settings.locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router,
    );
  }
}
