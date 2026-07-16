import 'package:flutter/widgets.dart';

/// Locale-aware casing for text shown to the user.
///
/// Dart's built-in [String.toUpperCase] and [String.toLowerCase] are locale
/// independent. Turkish has dotted/dotless I rules that therefore need to be
/// applied before the Unicode default casing operation.
String localeUpperCase(String value, Locale locale) {
  if (locale.languageCode.toLowerCase() == 'tr') {
    return value.replaceAll('i', 'İ').replaceAll('ı', 'I').toUpperCase();
  }
  return value.toUpperCase();
}

String localeLowerCase(String value, Locale locale) {
  if (locale.languageCode.toLowerCase() == 'tr') {
    return value.replaceAll('I', 'ı').replaceAll('İ', 'i').toLowerCase();
  }
  return value.toLowerCase();
}

extension LocaleAwareStringCase on String {
  String toLocaleUpperCase(BuildContext context) =>
      localeUpperCase(this, Localizations.localeOf(context));

  String toLocaleLowerCase(BuildContext context) =>
      localeLowerCase(this, Localizations.localeOf(context));
}
