import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppLocalizations {
  const AppLocalizations(this.locale, this._strings);

  static const supportedLocales = [Locale('es'), Locale('en')];
  static const delegate = _AppLocalizationsDelegate();

  final Locale locale;
  final Map<String, String> _strings;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  String t(String key, [Map<String, String> params = const {}]) {
    var value = _strings[key] ?? key;
    for (final entry in params.entries) {
      value = value.replaceAll('{${entry.key}}', entry.value);
    }
    return value;
  }
}

extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return AppLocalizations.supportedLocales.any(
      (supportedLocale) => supportedLocale.languageCode == locale.languageCode,
    );
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    final languageCode = isSupported(locale) ? locale.languageCode : 'es';
    final jsonString = await rootBundle.loadString(
      'assets/i18n/$languageCode.json',
    );
    final decoded = json.decode(jsonString) as Map<String, dynamic>;
    return AppLocalizations(
      Locale(languageCode),
      decoded.map((key, value) => MapEntry(key, value.toString())),
    );
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
