import 'package:flutter_test/flutter_test.dart';
import 'package:taptapdoner/domain/quests/starter_quest_catalog.dart';
import 'package:taptapdoner/l10n/app_strings.dart';

void main() {
  test('starter quest catalog contains 40 unique localized quests', () {
    final definitions = StarterQuestCatalog.definitions;
    final ids = definitions.map((definition) => definition.id).toSet();
    final english = AppStrings.forLanguageCode('en');
    final turkish = AppStrings.forLanguageCode('tr');

    expect(definitions, hasLength(40));
    expect(ids, hasLength(definitions.length));

    for (final definition in definitions) {
      final titleKey = 'quest.${definition.id}.title';
      final rewardKey = 'quest.${definition.id}.reward';

      expect(english.questTitle(definition.id), isNot(titleKey));
      expect(english.questReward(definition.id), isNot(rewardKey));
      expect(turkish.questTitle(definition.id), isNot(titleKey));
      expect(turkish.questReward(definition.id), isNot(rewardKey));
    }
  });
}
