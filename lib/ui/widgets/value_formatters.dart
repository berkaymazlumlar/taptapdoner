import 'package:flutter/widgets.dart';
import 'package:taptapdoner/domain/economy/game_number.dart';
import 'package:taptapdoner/domain/economy/number_units.dart';

const currencySymbol = '₵';

String formatCompactNumber(BuildContext context, Object value) {
  final locale = Localizations.localeOf(context).toLanguageTag();
  return formatNumberWithUnits(value, locale: locale);
}

String formatNumberWithUnits(Object value, {String locale = 'en'}) {
  return formatNumberWithUnitNames(value, locale: locale);
}

String formatCompactCurrency(BuildContext context, Object value) {
  return '${formatCompactNumber(context, value)} $currencySymbol';
}

String formatClickCurrency(BuildContext context, Object value) {
  final locale = Localizations.localeOf(context).toLanguageTag();
  return '${formatNumberWithUnitAbbreviations(value, locale: locale)} $currencySymbol';
}

String formatCompactDecimal(BuildContext context, Object value) {
  final raw = value is GameNumber
      ? value.toDouble()
      : (value as num).toDouble();
  if (raw.isFinite && raw.abs() < 10) {
    return _trimFixed(raw, 1, Localizations.localeOf(context).toLanguageTag());
  }
  return formatCompactNumber(context, value);
}

String formatCompactCurrencyRate(BuildContext context, Object value) {
  final locale = Localizations.localeOf(context).toLanguageTag();
  final suffix = locale.toLowerCase().startsWith('tr') ? '/sn' : '/s';
  return '${formatCompactDecimal(context, value)} $currencySymbol$suffix';
}

String formatShortDuration(Duration duration) {
  final minutes = duration.inMinutes;
  final seconds = duration.inSeconds.remainder(60);
  if (minutes <= 0) {
    return '${seconds}s';
  }
  return '${minutes}m ${seconds.toString().padLeft(2, '0')}s';
}

String _trimFixed(double value, int decimals, String locale) {
  final text = value.toStringAsFixed(decimals);
  final trimmed = text
      .replaceFirst(RegExp(r'\.?0+$'), '')
      .replaceFirst(RegExp(r'^\-0$'), '0');
  if (locale.toLowerCase().startsWith('tr')) {
    return trimmed.replaceAll('.', ',');
  }
  return trimmed;
}
