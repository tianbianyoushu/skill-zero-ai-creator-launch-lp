import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/l10n.dart';
import '../../core/utils/format.dart';
import 'craving.dart';
import 'cravings_controller.dart';
import 'new_craving_sheet.dart';

class CravingsScreen extends ConsumerWidget {
  const CravingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cravings = ref.watch(cravingsProvider);
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.cravingsTitle)),
      body: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: cravings.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final c = cravings[index];
          final dateText = formatDateTime(c.timestamp.toLocal(), locale);
          final subtitle = c.note == null || c.note!.isEmpty
              ? dateText
              : '$dateText\n${c.note}';
          return Dismissible(
            key: ValueKey(c.timestamp.toIso8601String()),
            background: Container(
              color: Theme.of(context).colorScheme.errorContainer,
            ),
            onDismissed: (_) => ref.read(cravingsProvider.notifier).removeAt(index),
            child: ListTile(
              leading: CircleAvatar(child: Text('${c.intensity}')),
              title: Text('${c.trigger} → ${c.coping}'),
              subtitle: Text(subtitle.trim(), maxLines: 2),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await showModalBottomSheet<Craving>(
            context: context,
            isScrollControlled: true,
            builder: (_) => const NewCravingSheet(),
          );
          if (result != null) {
            ref.read(cravingsProvider.notifier).add(result);
          }
        },
        icon: const Icon(Icons.add),
        label: Text(l10n.cravingsAddEntry),
      ),
    );
  }
}
