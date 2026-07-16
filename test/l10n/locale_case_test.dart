import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taptapdoner/l10n/locale_case.dart';

void main() {
  group('locale-aware casing', () {
    test('uppercases Turkish dotted and dotless i correctly', () {
      expect(
        localeUpperCase('Nakit, işçi, ılık ışık', const Locale('tr')),
        'NAKİT, İŞÇİ, ILIK IŞIK',
      );
    });

    test('lowercases Turkish dotted and dotless I correctly', () {
      expect(
        localeLowerCase('NAKİT, İŞÇİ, ILIK IŞIK', const Locale('tr')),
        'nakit, işçi, ılık ışık',
      );
    });

    test('keeps default Unicode casing for other locales', () {
      expect(localeUpperCase('Nakit', const Locale('en')), 'NAKIT');
      expect(localeLowerCase('Istanbul', const Locale('en')), 'istanbul');
    });
  });
}
