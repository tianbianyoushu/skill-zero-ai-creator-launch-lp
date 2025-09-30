import 'package:flutter/material.dart';

import '../../core/l10n/l10n.dart';
import 'craving.dart';
import 'craving_presets.dart';

class NewCravingSheet extends StatefulWidget {
  const NewCravingSheet({super.key});

  @override
  State<NewCravingSheet> createState() => _NewCravingSheetState();
}

class _NewCravingSheetState extends State<NewCravingSheet> {
  int _intensity = 3;
  String _trigger = '';
  String _coping = '';
  final _noteCtrl = TextEditingController();

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final triggers = buildDefaultTriggers(l10n);
    final copings = buildDefaultCopings(l10n);
    final selectedTrigger =
        triggers.contains(_trigger) ? _trigger : (triggers.isNotEmpty ? triggers.first : '');
    final selectedCoping =
        copings.contains(_coping) ? _coping : (copings.isNotEmpty ? copings.first : '');
    final padding = MediaQuery.of(context).viewInsets + const EdgeInsets.all(16);
    return Padding(
      padding: padding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.cravingNewTitle,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(l10n.cravingIntensityLabel),
          Slider(
            value: _intensity.toDouble(),
            min: 1,
            max: 5,
            divisions: 4,
            label: _intensity.toString(),
            onChanged: (v) => setState(() => _intensity = v.toInt()),
          ),
          const SizedBox(height: 8),
          Text(l10n.cravingTriggerLabel),
          Wrap(
            spacing: 8,
            children: [
              for (final t in triggers)
                ChoiceChip(
                  label: Text(t),
                  selected: selectedTrigger == t,
                  onSelected: (_) => setState(() => _trigger = t),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(l10n.cravingCopingLabel),
          Wrap(
            spacing: 8,
            children: [
              for (final c in copings)
                ChoiceChip(
                  label: Text(c),
                  selected: selectedCoping == c,
                  onSelected: (_) => setState(() => _coping = c),
                ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _noteCtrl,
            decoration: InputDecoration(
              labelText: l10n.cravingNoteLabel,
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: () {
                    Navigator.pop(
                      context,
                      Craving(
                        timestamp: DateTime.now(),
                        intensity: _intensity,
                        trigger: selectedTrigger,
                        coping: selectedCoping,
                        note: _noteCtrl.text.trim().isEmpty
                            ? null
                            : _noteCtrl.text.trim(),
                      ),
                    );
                  },
                  child: Text(l10n.commonSave),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
