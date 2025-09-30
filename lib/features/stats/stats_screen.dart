import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/l10n.dart';
import '../../core/utils/format.dart';
import '../quit/profile.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final now = DateTime.now();
    final saved = profile.moneySaved(now);
    final avoided = profile.cigarettesAvoided(now);

    final l10n = context.l10n;
    final locale = Localizations.localeOf(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.statsTitle)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StatTile(
              title: l10n.statsSavingsLabel,
              value: formatCurrency(saved, locale, profile.currencyCode),
            ),
            _StatTile(
              title: l10n.statsCigarettesLabel,
              value: l10n.statsCigarettesValue(avoided),
            ),
            _StatTile(
              title: l10n.statsDaysLabel,
              value: l10n.statsDaysValue(profile.elapsed(now).inDays),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.statsHealthHeading,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('・${l10n.statsHealthTip20Min}')
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String title;
  final String value;
  const _StatTile({required this.title, required this.value});
  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(title),
        trailing: Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}
