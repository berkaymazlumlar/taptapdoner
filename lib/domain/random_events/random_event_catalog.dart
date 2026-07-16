import 'package:taptapdoner/domain/random_events/random_event_models.dart';

abstract final class RandomEventCatalog {
  static final events = <RandomEventDefinition>[
    RandomEventDefinition(
      id: 'EVT_001',
      title: 'Döner Festivali',
      type: RandomEventType.social,
      rarity: RandomEventRarity.common,
      weight: 100,
      unlockCondition: 'default',
      eventText:
          'Mahallede döner festivali düzenleniyor. Tezgah açmak ister misin?',
      rewardSummary: '5 dakikalık büyük kazanç',
      riskSummary: 'Hazırlık masrafı',
      cooldownGroup: 'festival',
      effectTags: ['instant_money', 'money_cost'],
      choices: [
        RandomEventChoice(
          key: 'decline',
          label: 'Boş Ver',
          outcomeLogic: 'Fırsat kaçar.',
          outcomes: [
            RandomEventOutcome(
              key: 'declined',
              probability: 1,
              effect: RandomEventEffect(
                type: RandomEventEffectType.noEffect,
                value: 0,
              ),
              resultText: 'Festivali uzaktan izledin. Dükkan düzeni bozulmadı.',
            ),
          ],
        ),
        RandomEventChoice(
          key: 'accept',
          label: 'Katıl',
          outcomeLogic:
              '%70: 5 dakikalık kazanç ödülü. %30: mevcut paranın %5’i gider.',
          outcomes: [
            RandomEventOutcome(
              key: 'festival_success',
              probability: 0.70,
              effect: RandomEventEffect(
                type: RandomEventEffectType.instantMoney,
                value: 300,
              ),
              resultText:
                  'Tezgah kapış kapış sattı. Festivalden güzel kazanç geldi.',
            ),
            RandomEventOutcome(
              key: 'festival_cost',
              probability: 0.30,
              effect: RandomEventEffect(
                type: RandomEventEffectType.moneyCost,
                value: 0.05,
                target: '300',
              ),
              resultText:
                  'Hazırlık masrafı beklenenden fazla tuttu. Biraz para gitti.',
            ),
          ],
        ),
      ],
    ),
    RandomEventDefinition(
      id: 'EVT_002',
      title: 'Fenomen Ziyareti',
      type: RandomEventType.social,
      rarity: RandomEventRarity.rare,
      weight: 55,
      unlockCondition: 'default',
      eventText:
          'Ünlü bir yemek fenomeni dükkanına geldi. Ona özel döner hazırlayacak mısın?',
      rewardSummary: '10 dakika tüm gelir x2',
      riskSummary: 'Beğenmezse kısa süreli moral düşer',
      cooldownGroup: 'social',
      effectTags: ['global_boost', 'reputation_penalty'],
      choices: [
        _decline('Boş Ver', 'Fenomen başka yere geçti. Gün normal akıyor.'),
        RandomEventChoice(
          key: 'accept',
          label: 'Hazırla',
          outcomeLogic:
              '%60: 10 dakika tüm gelir x2. %40: 3 dakika gelir -%20.',
          outcomes: [
            RandomEventOutcome(
              key: 'influencer_loved_it',
              probability: 0.60,
              effect: RandomEventEffect(
                type: RandomEventEffectType.globalBoost,
                value: 2,
                duration: Duration(minutes: 10),
              ),
              resultText:
                  'Fenomen döneri paylaştı. Kalabalık büyüdü, gelir ikiye katlandı.',
            ),
            RandomEventOutcome(
              key: 'influencer_mood_loss',
              probability: 0.40,
              effect: RandomEventEffect(
                type: RandomEventEffectType.globalPenalty,
                value: 0.80,
                duration: Duration(minutes: 3),
              ),
              resultText:
                  'Fenomen çok etkilenmedi. Mutfakta kısa süreli moral düşüşü var.',
            ),
          ],
        ),
      ],
    ),
    RandomEventDefinition(
      id: 'EVT_003',
      title: 'Gece Siparişi',
      type: RandomEventType.reward,
      rarity: RandomEventRarity.common,
      weight: 100,
      unlockCondition: 'staff unlocked',
      eventText:
          'Gece yarısı büyük bir toplu sipariş geldi. Kabul edecek misin?',
      rewardSummary: 'Pasif gelir x600 para',
      riskSummary: 'Personel yorulabilir',
      cooldownGroup: 'order',
      effectTags: ['instant_money', 'passive_penalty'],
      choices: [
        _decline(
          'Reddet',
          'Geceyi sakin kapattın. Fırsat kaçtı ama ekip dinlendi.',
        ),
        RandomEventChoice(
          key: 'accept',
          label: 'Kabul Et',
          outcomeLogic:
              'Anında passiveIncomePerSecond x600 para. %25 ek risk: 2 dakika pasif gelir -%20.',
          outcomes: [
            RandomEventOutcome(
              key: 'night_order_paid',
              probability: 0.75,
              effect: RandomEventEffect(
                type: RandomEventEffectType.instantMoney,
                value: 600,
              ),
              resultText:
                  'Gece siparişi yetişti. Kasaya büyük bir ödeme girdi.',
            ),
            RandomEventOutcome(
              key: 'night_order_tired_staff',
              probability: 0.25,
              effect: RandomEventEffect(
                type: RandomEventEffectType.passivePenalty,
                value: 0.80,
                duration: Duration(minutes: 2),
              ),
              resultText:
                  'Sipariş yetişti ama personel yoruldu. Pasif gelir kısa süre düştü.',
            ),
          ],
        ),
      ],
    ),
    RandomEventDefinition(
      id: 'EVT_004',
      title: 'Gizemli Sos Ustası',
      type: RandomEventType.risk,
      rarity: RandomEventRarity.rare,
      weight: 55,
      unlockCondition: 'menu unlocked',
      eventText:
          'Yaşlı bir sos ustası sana gizli tarifini öğretmek istiyor. Dinleyecek misin?',
      rewardSummary: '10 dakika menü etkisi +%25',
      riskSummary: 'Sos tutmayabilir',
      cooldownGroup: 'recipe',
      effectTags: ['menu_boost', 'tap_penalty'],
      choices: [
        _decline(
          'Reddet',
          'Tarif sırrı kapıda kaldı. Servis aynı tempoda sürüyor.',
        ),
        RandomEventChoice(
          key: 'accept',
          label: 'Dinle',
          outcomeLogic: '%80: 10 dakika menü +%25. %20: 2 dakika tap -%15.',
          outcomes: [
            RandomEventOutcome(
              key: 'sauce_secret',
              probability: 0.80,
              effect: RandomEventEffect(
                type: RandomEventEffectType.menuBoost,
                value: 1.25,
                duration: Duration(minutes: 10),
              ),
              resultText: 'Sos tuttu. Menü değeri kısa süreliğine yükseldi.',
            ),
            RandomEventOutcome(
              key: 'sauce_failed',
              probability: 0.20,
              effect: RandomEventEffect(
                type: RandomEventEffectType.tapPenalty,
                value: 0.85,
                duration: Duration(minutes: 2),
              ),
              resultText:
                  'Sos fazla baskın oldu. Elle servis temposu biraz düştü.',
            ),
          ],
        ),
      ],
    ),
    RandomEventDefinition(
      id: 'EVT_005',
      title: 'Bozuk Ocak Alarmı',
      type: RandomEventType.maintenance,
      rarity: RandomEventRarity.common,
      weight: 100,
      unlockCondition: 'oven unlocked',
      eventText:
          'Ocağın garip sesler çıkarıyor. Hemen tamirci çağıracak mısın?',
      rewardSummary: '5 dakika tüm gelir +%15',
      riskSummary: 'Beklersen arıza riski var',
      cooldownGroup: 'maintenance',
      effectTags: ['money_cost', 'global_boost', 'passive_penalty'],
      choices: [
        RandomEventChoice(
          key: 'decline',
          label: 'Bekle',
          outcomeLogic: '%40: 2 dakika pasif -%30. %60: bir şey olmaz.',
          outcomes: [
            RandomEventOutcome(
              key: 'oven_wait_ok',
              probability: 0.60,
              effect: RandomEventEffect(
                type: RandomEventEffectType.noEffect,
                value: 0,
              ),
              resultText: 'Ses kesildi. Şimdilik masraf çıkmadı.',
            ),
            RandomEventOutcome(
              key: 'oven_wait_penalty',
              probability: 0.40,
              effect: RandomEventEffect(
                type: RandomEventEffectType.passivePenalty,
                value: 0.70,
                duration: Duration(minutes: 2),
              ),
              resultText: 'Ocak aksadı. Pasif gelir kısa süreliğine düştü.',
            ),
          ],
        ),
        RandomEventChoice(
          key: 'accept',
          label: 'Tamirci Çağır',
          outcomeLogic: 'Mevcut paranın %3’ü gider, 5 dakika tüm gelir +%15.',
          outcomes: [
            RandomEventOutcome(
              key: 'oven_repaired',
              probability: 1,
              effect: RandomEventEffect(
                type: RandomEventEffectType.globalBoost,
                value: 1.15,
                duration: Duration(minutes: 5),
                target: 'cost:0.03',
              ),
              resultText:
                  'Tamirci ocağı ayarladı. Masraf çıktı ama servis hızlandı.',
            ),
          ],
        ),
      ],
    ),
    RandomEventDefinition(
      id: 'EVT_006',
      title: 'Aç Müşteri Grubu',
      type: RandomEventType.challenge,
      rarity: RandomEventRarity.common,
      weight: 100,
      unlockCondition: 'default',
      eventText:
          'Bir otobüs dolusu aç müşteri dükkanın önünde durdu. Hepsine yetişmeye çalışır mısın?',
      rewardSummary: '60 saniye tap x3',
      riskSummary: 'Yoğun tempoda hata riski',
      cooldownGroup: 'crowd',
      effectTags: ['tap_boost'],
      choices: [
        _decline('Boş Ver', 'Kalabalığı pas geçtin. Dükkan düzeni korundu.'),
        RandomEventChoice(
          key: 'accept',
          label: 'Yetiş',
          outcomeLogic: '60 saniye boyunca her tap x3.',
          outcomes: [
            RandomEventOutcome(
              key: 'crowd_tap_boost',
              probability: 1,
              effect: RandomEventEffect(
                type: RandomEventEffectType.tapBoost,
                value: 3,
                duration: Duration(seconds: 60),
              ),
              resultText:
                  'Kalabalığa yetiştin. Elle kesim geliri kısa süreliğine patladı.',
            ),
          ],
        ),
      ],
    ),
    RandomEventDefinition(
      id: 'EVT_007',
      title: 'Rakip Dönerci Meydan Okudu',
      type: RandomEventType.challenge,
      rarity: RandomEventRarity.rare,
      weight: 55,
      unlockCondition: 'knife item tier >= 2',
      eventText:
          'Yan sokaktaki dönerci en hızlı kesen kazansın diye meydan okudu.',
      rewardSummary: 'Başarılı olursa büyük ödül',
      riskSummary: 'Başaramazsan küçük kayıp',
      cooldownGroup: 'challenge',
      effectTags: ['challenge', 'instant_money', 'reputation', 'money_cost'],
      choices: [
        _decline(
          'Boş Ver',
          'Meydan okumayı kabul etmedin. Rekabet başka güne kaldı.',
        ),
        RandomEventChoice(
          key: 'accept',
          label: 'Meydan Oku',
          outcomeLogic:
              '%65: passiveIncomePerSecond x900 para + itibar. %35: mevcut paranın %3’ü gider.',
          outcomes: [
            RandomEventOutcome(
              key: 'rival_won',
              probability: 0.65,
              effect: RandomEventEffect(
                type: RandomEventEffectType.instantMoney,
                value: 900,
                target: 'reputation:1',
              ),
              resultText:
                  'Rakibi geride bıraktın. Hem para hem itibar kazandın.',
            ),
            RandomEventOutcome(
              key: 'rival_lost',
              probability: 0.35,
              effect: RandomEventEffect(
                type: RandomEventEffectType.moneyCost,
                value: 0.03,
                target: '180',
              ),
              resultText:
                  'Yarışı kaybettin. Küçük bir hazırlık masrafı kasadan çıktı.',
            ),
          ],
        ),
      ],
    ),
    RandomEventDefinition(
      id: 'EVT_019',
      title: 'Tedarikçi İndirimi',
      type: RandomEventType.investment,
      rarity: RandomEventRarity.common,
      weight: 100,
      unlockCondition: 'default',
      eventText: 'Tedarikçin bugün indirim yaptı. Malzeme stoklayacak mısın?',
      rewardSummary: '10 dakika upgrade maliyeti -%10',
      riskSummary: 'Ön ödeme gerekir',
      cooldownGroup: 'supplier',
      effectTags: ['upgrade_discount', 'money_cost'],
      choices: [
        _decline('Boş Ver', 'İndirimi kaçırdın. Nakit kasada kaldı.'),
        RandomEventChoice(
          key: 'accept',
          label: 'Stokla',
          outcomeLogic: 'Mevcut paranın %2’si gider, 10 dakika upgrade -%10.',
          outcomes: [
            RandomEventOutcome(
              key: 'supplier_discount',
              probability: 1,
              effect: RandomEventEffect(
                type: RandomEventEffectType.upgradeDiscount,
                value: 0.90,
                duration: Duration(minutes: 10),
                target: 'cost:0.02',
              ),
              resultText:
                  'Stoklar doldu. Kısa süreliğine upgrade maliyetleri düştü.',
            ),
          ],
        ),
      ],
    ),
    RandomEventDefinition(
      id: 'EVT_020',
      title: 'Çalışan Prim İstiyor',
      type: RandomEventType.staff,
      rarity: RandomEventRarity.common,
      weight: 100,
      unlockCondition: 'staff unlocked',
      eventText: 'Personel prim istiyor. Kabul edecek misin?',
      rewardSummary: '10 dakika pasif +%30',
      riskSummary: 'Para gider',
      cooldownGroup: 'staff',
      effectTags: ['money_cost', 'passive_boost', 'passive_penalty'],
      choices: [
        RandomEventChoice(
          key: 'decline',
          label: 'Reddet',
          outcomeLogic: '3 dakika pasif gelir -%10.',
          outcomes: [
            RandomEventOutcome(
              key: 'staff_unhappy',
              probability: 1,
              effect: RandomEventEffect(
                type: RandomEventEffectType.passivePenalty,
                value: 0.90,
                duration: Duration(minutes: 3),
              ),
              resultText:
                  'Personel biraz bozuldu. Pasif gelir kısa süreliğine azaldı.',
            ),
          ],
        ),
        RandomEventChoice(
          key: 'accept',
          label: 'Prim Ver',
          outcomeLogic: 'Mevcut paranın %5’i gider, 10 dakika pasif +%30.',
          outcomes: [
            RandomEventOutcome(
              key: 'staff_bonus',
              probability: 1,
              effect: RandomEventEffect(
                type: RandomEventEffectType.passiveBoost,
                value: 1.30,
                duration: Duration(minutes: 10),
                target: 'cost:0.05',
              ),
              resultText: 'Prim ekibi motive etti. Pasif gelir yükseldi.',
            ),
          ],
        ),
      ],
    ),
  ];

  static final byId = <String, RandomEventDefinition>{
    for (final event in events) event.id: event,
  };

  static RandomEventChoice _decline(String label, String resultText) {
    return RandomEventChoice(
      key: 'decline',
      label: label,
      outcomeLogic: 'Fırsat kaçar.',
      outcomes: [
        RandomEventOutcome(
          key: 'declined',
          probability: 1,
          effect: RandomEventEffect(
            type: RandomEventEffectType.noEffect,
            value: 0,
          ),
          resultText: resultText,
        ),
      ],
    );
  }
}
