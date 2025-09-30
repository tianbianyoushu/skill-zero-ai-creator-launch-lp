import 'package:flutter/widgets.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';

String formatCurrency(num value, Locale locale, String currencyCode) {
  final formatter = NumberFormat.currency(
    locale: locale.toLanguageTag(),
    name: currencyCode,
  );
  return formatter.format(value);
}

String formatDuration(Duration duration, AppLocalizations l10n) {
  final days = duration.inDays;
  final hours = duration.inHours.remainder(24);
  final minutes = duration.inMinutes.remainder(60);
  final parts = <String>[];
  if (days > 0) parts.add(l10n.durationDays(days));
  if (hours > 0) parts.add(l10n.durationHours(hours));
  if (minutes > 0 || parts.isEmpty) parts.add(l10n.durationMinutes(minutes));
  return parts.join(' ');
}

String formatDate(DateTime date, Locale locale) {
  return DateFormat.yMMMd(locale.toLanguageTag()).format(date);
}

String formatDateTime(DateTime date, Locale locale) {
  final dateFormatter = DateFormat.yMMMd(locale.toLanguageTag());
  final timeFormatter = DateFormat.Hm(locale.toLanguageTag());
  return '${dateFormatter.format(date)} ${timeFormatter.format(date)}';
}
