import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

const currencySymbol = '₵';

String formatCompactNumber(BuildContext context, num value) {
  final locale = Localizations.localeOf(context).toLanguageTag();
  return NumberFormat.compact(locale: locale).format(value);
}

String formatCompactCurrency(BuildContext context, num value) {
  return '${formatCompactNumber(context, value)} $currencySymbol';
}

String formatCompactDecimal(BuildContext context, num value) {
  if (value < 10) {
    return value.toStringAsFixed(1);
  }
  return formatCompactNumber(context, value.round());
}

String formatCompactCurrencyRate(BuildContext context, num value) {
  return '${formatCompactDecimal(context, value)} $currencySymbol/s';
}

String formatShortDuration(Duration duration) {
  final minutes = duration.inMinutes;
  final seconds = duration.inSeconds.remainder(60);
  if (minutes <= 0) {
    return '${seconds}s';
  }
  return '${minutes}m ${seconds.toString().padLeft(2, '0')}s';
}
