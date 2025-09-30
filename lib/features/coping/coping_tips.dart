import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class CopingTip {
  final String title;
  final String description;

  const CopingTip({required this.title, required this.description});
}

List<CopingTip> buildCopingTips(AppLocalizations l10n) => [
      CopingTip(
        title: l10n.copingBreathingTitle,
        description: l10n.copingBreathingDescription,
      ),
      CopingTip(
        title: l10n.copingWaterTitle,
        description: l10n.copingWaterDescription,
      ),
      CopingTip(
        title: l10n.copingWalkTitle,
        description: l10n.copingWalkDescription,
      ),
      CopingTip(
        title: l10n.copingGumTitle,
        description: l10n.copingGumDescription,
      ),
      CopingTip(
        title: l10n.copingStretchTitle,
        description: l10n.copingStretchDescription,
      ),
    ];
