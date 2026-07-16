import 'package:flutter_test/flutter_test.dart';
import 'package:taptapdoner/domain/economy/game_number.dart';
import 'package:taptapdoner/domain/economy/number_units.dart';
import 'package:taptapdoner/ui/widgets/value_formatters.dart';

void main() {
  test('large numbers use game unit suffixes instead of long digits', () {
    expect(formatNumberWithUnits(999), '999');
    expect(formatNumberWithUnits(1000), '1.00 Thousand');
    expect(formatNumberWithUnits(1250000), '1.25 Million');
    expect(formatNumberWithUnits(167570000000000), '167.57 Trillion');
    expect(formatNumberWithUnits(999999), '1.00 Million');
    expect(formatNumberWithUnits(1200000000000000), '1.20 Quadrillion');
  });

  test('named units are used through decillion', () {
    final value = formatNumberWithUnits(GameNumber.fromParts(9.22, 18));

    expect(value, '9.22 Quintillion');
    expect(value, isNot(matches(RegExp(r'[eE][+-]?\d'))));
  });

  test('numbers beyond the largest unit use scientific notation', () {
    final value = formatNumberWithUnits(GameNumber.fromParts(1, 96));

    expect(value, '1.00e96');
  });

  test('extended short-scale unit names reach trigintillion', () {
    expect(
      formatNumberWithUnits(GameNumber.fromParts(1.25, 36)),
      '1.25 Undecillion',
    );
    expect(
      formatNumberWithUnits(GameNumber.fromParts(4.2, 63)),
      '4.20 Vigintillion',
    );
    expect(
      formatNumberWithUnits(GameNumber.fromParts(7, 93)),
      '7.00 Trigintillion',
    );
  });

  test('turkish locale uses decimal comma with the same units', () {
    expect(formatNumberWithUnits(1250000, locale: 'tr'), '1,25 Milyon');
    expect(
      formatNumberWithUnits(GameNumber.fromParts(2.5, 63), locale: 'tr'),
      '2,50 Vigintilyon',
    );
  });

  test('click values use conventional short-scale abbreviations', () {
    expect(formatNumberWithUnitAbbreviations(1000), '1.00 K');
    expect(formatNumberWithUnitAbbreviations(1250000), '1.25 M');
    expect(formatNumberWithUnitAbbreviations(1e9), '1.00 B');
    expect(formatNumberWithUnitAbbreviations(1e12), '1.00 T');
    expect(formatNumberWithUnitAbbreviations(1e15), '1.00 Qa');
    expect(formatNumberWithUnitAbbreviations(1e18), '1.00 Qi');
  });

  test('click abbreviations stay unambiguous in turkish', () {
    expect(formatNumberWithUnitAbbreviations(1250000, locale: 'tr'), '1,25 M');
    expect(formatNumberWithUnitAbbreviations(1e9, locale: 'tr'), '1,00 B');
  });
}
