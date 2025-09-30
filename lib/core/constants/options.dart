import 'package:flutter_gen/gen_l10n/app_localizations.dart';

const supportedCountryCodes = <String>['JP', 'US', 'GB', 'DE', 'AU'];
const supportedCurrencyCodes = <String>['JPY', 'USD', 'EUR', 'GBP', 'AUD'];
const supportedLanguageCodes = <String>['ja', 'en'];

String localizedCountryName(AppLocalizations l10n, String code) {
  switch (code) {
    case 'JP':
      return l10n.countryJapan;
    case 'US':
      return l10n.countryUnitedStates;
    case 'GB':
      return l10n.countryUnitedKingdom;
    case 'DE':
      return l10n.countryGermany;
    case 'AU':
      return l10n.countryAustralia;
    default:
      return code;
  }
}

String localizedCurrencyName(AppLocalizations l10n, String code) {
  switch (code) {
    case 'JPY':
      return l10n.currencyJpy;
    case 'USD':
      return l10n.currencyUsd;
    case 'EUR':
      return l10n.currencyEur;
    case 'GBP':
      return l10n.currencyGbp;
    case 'AUD':
      return l10n.currencyAud;
    default:
      return code;
  }
}

String localizedLanguageName(AppLocalizations l10n, String code) {
  switch (code) {
    case 'ja':
      return l10n.languageJapanese;
    case 'en':
      return l10n.languageEnglish;
    default:
      return code;
  }
}
