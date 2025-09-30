import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'notification_service.dart';

List<MilestoneNotification> buildMilestoneNotifications(AppLocalizations l10n) => [
      MilestoneNotification(
        offset: const Duration(hours: 24),
        body: l10n.notificationMilestone1Day,
      ),
      MilestoneNotification(
        offset: const Duration(days: 3),
        body: l10n.notificationMilestone3Days,
      ),
      MilestoneNotification(
        offset: const Duration(days: 7),
        body: l10n.notificationMilestone7Days,
      ),
      MilestoneNotification(
        offset: const Duration(days: 14),
        body: l10n.notificationMilestone14Days,
      ),
      MilestoneNotification(
        offset: const Duration(days: 30),
        body: l10n.notificationMilestone30Days,
      ),
      MilestoneNotification(
        offset: const Duration(days: 60),
        body: l10n.notificationMilestone60Days,
      ),
      MilestoneNotification(
        offset: const Duration(days: 90),
        body: l10n.notificationMilestone90Days,
      ),
    ];
