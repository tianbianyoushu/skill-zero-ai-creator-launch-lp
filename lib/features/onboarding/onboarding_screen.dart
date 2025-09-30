import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/options.dart';
import '../../core/l10n/l10n.dart';
import '../../core/utils/format.dart';
import '../quit/profile.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  DateTime? _quitDate;
  final _cigsPerDayCtrl = TextEditingController(text: '20');
  final _cigsPerPackCtrl = TextEditingController(text: '20');
  final _packPriceCtrl = TextEditingController(text: '600');
  late String _countryCode;
  late String _currencyCode;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(profileProvider);
    _quitDate = profile.quitDate;
    _cigsPerDayCtrl.text = profile.cigarettesPerDay.toString();
    _cigsPerPackCtrl.text = profile.cigsPerPack.toString();
    _packPriceCtrl.text = profile.packPrice.toString();
    _countryCode = profile.countryCode;
    _currencyCode = profile.currencyCode;
  }

  @override
  void dispose() {
    _cigsPerDayCtrl.dispose();
    _cigsPerPackCtrl.dispose();
    _packPriceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.onboardingTitle)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text(
              l10n.onboardingSelectQuitDate,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              icon: const Icon(Icons.calendar_today),
              label: Text(
                _quitDate == null
                    ? l10n.onboardingStartToday
                    : l10n.onboardingStartOn(formatDate(_quitDate!, locale)),
              ),
              onPressed: () async {
                final now = DateTime.now();
                final picked = await showDatePicker(
                  context: context,
                  firstDate: DateTime(now.year - 1),
                  lastDate: DateTime(now.year + 2),
                  initialDate: _quitDate ?? now,
                  helpText: l10n.onboardingDatePickerHelp,
                );
                setState(() {
                  _quitDate = picked ?? now;
                });
              },
            ),
            const SizedBox(height: 24),
            Text(
              l10n.onboardingProfileSection,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _cigsPerDayCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: l10n.onboardingCigsPerDayLabel,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _cigsPerPackCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: l10n.onboardingCigsPerPackLabel,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _packPriceCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: l10n.onboardingPackPriceLabel(_currencyCode),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _countryCode,
              decoration: InputDecoration(labelText: l10n.onboardingCountryLabel),
              items: [
                for (final code in supportedCountryCodes)
                  DropdownMenuItem(
                    value: code,
                    child: Text(localizedCountryName(l10n, code)),
                  ),
              ],
              onChanged: (value) {
                if (value == null) return;
                setState(() => _countryCode = value);
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _currencyCode,
              decoration: InputDecoration(labelText: l10n.onboardingCurrencyLabel),
              items: [
                for (final code in supportedCurrencyCodes)
                  DropdownMenuItem(
                    value: code,
                    child: Text(localizedCurrencyName(l10n, code)),
                  ),
              ],
              onChanged: (value) {
                if (value == null) return;
                setState(() => _currencyCode = value);
              },
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () {
                final quitDate = _quitDate ?? DateTime.now();
                final cigsPerDay = int.tryParse(_cigsPerDayCtrl.text.trim()) ?? 20;
                final cigsPerPack = int.tryParse(_cigsPerPackCtrl.text.trim()) ?? 20;
                final packPrice = int.tryParse(_packPriceCtrl.text.trim()) ?? 600;

                ref.read(profileProvider.notifier).setProfile(
                      quitDate: quitDate,
                      cigarettesPerDay: cigsPerDay,
                      cigsPerPack: cigsPerPack,
                      packPrice: packPrice,
                      countryCode: _countryCode,
                      currencyCode: _currencyCode,
                    );
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
              },
              child: Text(l10n.onboardingSubmit),
            ),
          ],
        ),
      ),
    );
  }
}
