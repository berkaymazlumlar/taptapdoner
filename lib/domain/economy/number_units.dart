import 'dart:math' as math;

import 'package:taptapdoner/domain/economy/game_number.dart';

const _englishUnits = [
  '',
  'Thousand',
  'Million',
  'Billion',
  'Trillion',
  'Quadrillion',
  'Quintillion',
  'Sextillion',
  'Septillion',
  'Octillion',
  'Nonillion',
  'Decillion',
  'Undecillion',
  'Duodecillion',
  'Tredecillion',
  'Quattuordecillion',
  'Quindecillion',
  'Sexdecillion',
  'Septendecillion',
  'Octodecillion',
  'Novemdecillion',
  'Vigintillion',
  'Unvigintillion',
  'Duovigintillion',
  'Tresvigintillion',
  'Quattuorvigintillion',
  'Quinvigintillion',
  'Sesvigintillion',
  'Septemvigintillion',
  'Octovigintillion',
  'Novemvigintillion',
  'Trigintillion',
];

const _turkishUnits = [
  '',
  'Bin',
  'Milyon',
  'Milyar',
  'Trilyon',
  'Katrilyon',
  'Kentilyon',
  'Sekstilyon',
  'Septilyon',
  'Oktilyon',
  'Nonilyon',
  'Desilyon',
  'Undesilyon',
  'Dodesilyon',
  'Tredesilyon',
  'Katordesilyon',
  'Kendesilyon',
  'Seksdesilyon',
  'Septendesilyon',
  'Oktodesilyon',
  'Novemdesilyon',
  'Vigintilyon',
  'Unvigintilyon',
  'Duovigintilyon',
  'Tresvigintilyon',
  'Katuorvigintilyon',
  'Kinvigintilyon',
  'Sesvigintilyon',
  'Septemvigintilyon',
  'Oktovigintilyon',
  'Novemvigintilyon',
  'Trigintilyon',
];

// Conventional short-scale abbreviations commonly used by incremental games.
// They stay locale-independent so, for example, B always means billion and is
// never confused with the Turkish word "bin".
const _abbreviatedUnits = [
  '',
  'K',
  'M',
  'B',
  'T',
  'Qa',
  'Qi',
  'Sx',
  'Sp',
  'Oc',
  'No',
  'Dc',
  'Ud',
  'Dd',
  'Td',
  'Qad',
  'Qid',
  'Sxd',
  'Spd',
  'Ocd',
  'Nod',
  'Vg',
  'Uvg',
  'Dvg',
  'Tvg',
  'Qavg',
  'Qivg',
  'Sxvg',
  'Spvg',
  'Ocvg',
  'Novg',
  'Tg',
];

String formatNumberWithUnitNames(Object value, {String locale = 'en'}) {
  return _formatNumberWithUnits(
    value,
    locale: locale,
    units: _unitsForLocale(locale),
  );
}

String formatNumberWithUnitAbbreviations(Object value, {String locale = 'en'}) {
  return _formatNumberWithUnits(
    value,
    locale: locale,
    units: _abbreviatedUnits,
  );
}

String _formatNumberWithUnits(
  Object value, {
  required String locale,
  required List<String> units,
}) {
  final gameValue = value is GameNumber
      ? value
      : GameNumber.fromNum(value as num);
  if (gameValue.isZero) {
    return '0';
  }
  if (gameValue.exponent >= _englishUnits.length * 3) {
    final decimals = _unitDecimals;
    final coefficient = _fixed(gameValue.mantissa, decimals, locale);
    return '${coefficient}e${gameValue.exponent}';
  }
  final raw = gameValue.toDouble();
  if (raw.isNaN) {
    return '0';
  }
  if (!raw.isFinite) {
    return raw.isNegative ? '-MAX' : 'MAX';
  }

  final sign = raw < 0 ? '-' : '';
  final absolute = raw.abs();
  if (absolute < 1000) {
    return '$sign${_trimFixed(absolute, 0, locale)}';
  }

  var unitIndex = math.min(
    (math.log(absolute) / math.log(1000)).floor(),
    units.length - 1,
  );
  var scaled = absolute / math.pow(1000.0, unitIndex);
  var decimals = _unitDecimals;
  var rounded = _roundToDecimals(scaled, decimals);
  if (rounded >= 1000 && unitIndex < units.length - 1) {
    unitIndex += 1;
    scaled = absolute / math.pow(1000.0, unitIndex);
    decimals = _unitDecimals;
    rounded = _roundToDecimals(scaled, decimals);
  }

  final unit = units[unitIndex];
  final formatted = _fixed(rounded, decimals, locale);
  return unit.isEmpty ? '$sign$formatted' : '$sign$formatted $unit';
}

List<String> _unitsForLocale(String locale) {
  return locale.toLowerCase().startsWith('tr') ? _turkishUnits : _englishUnits;
}

const _unitDecimals = 2;

double _roundToDecimals(double value, int decimals) {
  if (decimals <= 0) {
    return value.roundToDouble();
  }
  final factor = math.pow(10, decimals).toDouble();
  return (value * factor).roundToDouble() / factor;
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

String _fixed(double value, int decimals, String locale) {
  final text = value.toStringAsFixed(decimals);
  return locale.toLowerCase().startsWith('tr')
      ? text.replaceAll('.', ',')
      : text;
}
