import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/l10n.dart';
import '../../core/utils/format.dart';
import '../quit/profile.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final now = DateTime.now();
    final elapsed = profile.elapsed(now);
    final saved = profile.moneySaved(now);
    final avoided = profile.cigarettesAvoided(now);

    final l10n = context.l10n;
    final locale = Localizations.localeOf(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.homeTitle)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.isOnboarded
                          ? l10n.homeStatusInProgress
                          : l10n.homePromptSetQuitDate,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    if (profile.isOnboarded) ...[
                      Text('${l10n.homeElapsedLabel}: '
                          '${formatDuration(elapsed, l10n)}'),
                      const SizedBox(height: 4),
                      Text('${l10n.homeSavingsLabel}: '
                          '${formatCurrency(saved, locale, profile.currencyCode)}'),
                      const SizedBox(height: 4),
                      Text('${l10n.homeCigarettesLabel}: '
                          '${l10n.cigarettesCount(avoided)}'),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _QuickAction(
                  icon: Icons.add,
                  label: l10n.quickActionLogCraving,
                  onTap: () => context.push('/cravings'),
                ),
                _QuickAction(
                  icon: Icons.favorite,
                  label: l10n.quickActionCoping,
                  onTap: () => context.push('/coping'),
                ),
                _QuickAction(
                  icon: Icons.insights,
                  label: l10n.quickActionStats,
                  onTap: () => context.push('/stats'),
                ),
                _QuickAction(
                  icon: Icons.settings,
                  label: l10n.quickActionSettings,
                  onTap: () => context.push('/settings'),
                ),
                _QuickAction(
                  icon: Icons.sports_esports,
                  label: 'ミニゲーム',
                  onTap: () => context.push('/game'),
                ),
              ],
            ),
            const Spacer(),
            if (!profile.isOnboarded)
              FilledButton(
                onPressed: () => context.push('/onboarding'),
                child: Text(l10n.homeStartCta),
              ),
          ],
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Ink(
        width: 160,
        height: 80,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Theme.of(context).colorScheme.primaryContainer,
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 22),
              const SizedBox(width: 8),
              Text(label),
            ],
          ),
        ),
      ),
    );
  }
}
