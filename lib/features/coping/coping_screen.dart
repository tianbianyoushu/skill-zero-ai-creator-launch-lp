import 'package:flutter/material.dart';

import '../../core/l10n/l10n.dart';
import 'coping_tips.dart';

class CopingScreen extends StatelessWidget {
  const CopingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tips = buildCopingTips(l10n);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.copingTitle)),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          for (final tip in tips)
            Card(
              child: ListTile(
                title: Text(tip.title),
                subtitle: Text(tip.description),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: Text(tip.title),
                    content: Text(tip.description),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(l10n.commonOk),
                      )
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
