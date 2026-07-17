import 'package:taptapdoner/domain/random_events/random_event_models.dart';

abstract final class RandomEventCatalog {
  static final events = List<RandomEventDefinition>.unmodifiable(
    _eventSeeds.map(_buildEvent),
  );

  static final byId = <String, RandomEventDefinition>{
    for (final event in events) event.id: event,
  };

  static RandomEventDefinition _buildEvent(_EventSeed seed) {
    return RandomEventDefinition(
      id: seed.id,
      title: seed.title,
      type: _eventType(seed.type),
      rarity: _rarity(seed.rarity),
      weight: seed.weight,
      unlockCondition: seed.unlockCondition,
      eventText: seed.eventText,
      rewardSummary: seed.rewardSummary,
      riskSummary: seed.riskSummary,
      cooldownGroup: seed.cooldownGroup,
      effectTags: seed.effectTags
          .split(';')
          .where((tag) => tag.isNotEmpty)
          .toList(growable: false),
      choices: _choices(seed),
    );
  }

  static List<RandomEventChoice> _choices(_EventSeed seed) {
    final choices = <RandomEventChoice>[
      RandomEventChoice(
        key: 'decline',
        label: seed.declineLabel,
        outcomeLogic: seed.declineLogic,
        outcomes: _outcomesFor(
          seed.id,
          'decline',
          seed.declineLogic,
          seed.effectTags,
          isDecline: true,
        ),
      ),
      RandomEventChoice(
        key: 'accept',
        label: seed.acceptLabel,
        outcomeLogic: seed.acceptLogic,
        outcomes: _outcomesFor(
          seed.id,
          'accept',
          seed.acceptLogic,
          seed.effectTags,
        ),
      ),
    ];
    if (seed.adOption.isNotEmpty) {
      choices.add(
        RandomEventChoice(
          key: 'rewarded_ad',
          label: 'Reklam ?zle',
          outcomeLogic: seed.adOption,
          requiresRewardedAd: true,
          outcomes: _rewardedAdOutcomes(seed),
        ),
      );
    }
    return choices;
  }

  static List<RandomEventOutcome> _rewardedAdOutcomes(_EventSeed seed) {
    final logic = seed.adOption;
    final effect = _effectFromSegment(logic, seed.effectTags, seed.acceptLogic);
    return [
      RandomEventOutcome(
        key: '${seed.id}_rewarded_ad',
        probability: 1,
        effect: effect,
        resultText:
            'Reklam deste?iyle risk azald? ve f?rsat g?venli ?ekilde de?erlendirildi.',
      ),
    ];
  }

  static List<RandomEventOutcome> _outcomesFor(
    String eventId,
    String choiceKey,
    String logic,
    String effectTags, {
    bool isDecline = false,
  }) {
    if (isDecline && _isMostlyNoEffect(logic)) {
      return [
        _noEffect(
          eventId,
          choiceKey,
          'F?rsat? pas ge?tin. D?kk?n d?zeni bozulmad?.',
        ),
      ];
    }

    final pieces = _probabilityPieces(logic);
    if (pieces.isEmpty) {
      final effect = _effectFromSegment(logic, effectTags, logic);
      return [
        RandomEventOutcome(
          key: '${eventId}_${choiceKey}_effect',
          probability: 1,
          effect: effect,
          resultText: _resultText(effect.type, isDecline: isDecline),
        ),
      ];
    }

    return pieces.indexed
        .map((entry) {
          final index = entry.$1;
          final piece = entry.$2;
          final effect = _effectFromSegment(piece.segment, effectTags, logic);
          return RandomEventOutcome(
            key: '${eventId}_${choiceKey}_${index + 1}',
            probability: piece.probability,
            effect: effect,
            resultText: _resultText(effect.type, isDecline: isDecline),
          );
        })
        .toList(growable: false);
  }

  static bool _isMostlyNoEffect(String logic) {
    final lower = logic.toLowerCase();
    return lower.contains('f?rsat ka?ar') ||
        lower.contains('hi?bir ?ey olmaz') && !lower.contains('%');
  }

  static List<_ProbabilityPiece> _probabilityPieces(String logic) {
    final matches = RegExp(r'%(\d+)\s*:').allMatches(logic).toList();
    if (matches.isEmpty) {
      return const <_ProbabilityPiece>[];
    }
    final pieces = <_ProbabilityPiece>[];
    for (var index = 0; index < matches.length; index += 1) {
      final match = matches[index];
      final nextStart = index + 1 < matches.length
          ? matches[index + 1].start
          : logic.length;
      pieces.add(
        _ProbabilityPiece(
          (int.parse(match.group(1)!) / 100).clamp(0, 1).toDouble(),
          logic.substring(match.end, nextStart).trim(),
        ),
      );
    }
    return pieces;
  }

  static RandomEventEffect _effectFromSegment(
    String segment,
    String effectTags,
    String fullLogic,
  ) {
    final lower = segment.toLowerCase();
    final tags = effectTags.toLowerCase();
    final combined = '$lower ${fullLogic.toLowerCase()}';
    final upfrontCost = _costTarget(fullLogic);

    if (_mentionsLoss(lower) && !_hasSupportedPositiveEffect(lower, tags)) {
      return RandomEventEffect(
        type: RandomEventEffectType.moneyCost,
        value: _percentValue(lower, fallback: 0.03),
        target: _capSeconds(lower),
      );
    }
    if (lower.contains('hi?bir ?ey') ||
        lower.contains('bo?') ||
        lower.contains('deneyim')) {
      return const RandomEventEffect(
        type: RandomEventEffectType.noEffect,
        value: 0,
      );
    }
    if (lower.contains('itibar') && _mentionsGain(lower)) {
      return RandomEventEffect(
        type: RandomEventEffectType.reputationGain,
        value: _flatNumberAfter(lower, 'itibar', fallback: 1),
      );
    }
    if ((lower.contains('tap') || tags.contains('crit_tap')) &&
        _mentionsPenalty(lower)) {
      return RandomEventEffect(
        type: RandomEventEffectType.tapPenalty,
        value: _penaltyMultiplier(lower, fallback: 0.85),
        duration: _duration(lower),
      );
    }
    if ((lower.contains('tap') ||
            tags.contains('crit_tap') ||
            tags.contains('tap_boost')) &&
        _mentionsGain(lower)) {
      return RandomEventEffect(
        type: RandomEventEffectType.tapBoost,
        value: _boostMultiplier(
          lower,
          fallback: tags.contains('crit_tap') ? 2.0 : 1.5,
        ),
        duration: _duration(lower),
        target: upfrontCost,
      );
    }
    if ((lower.contains('pasif') ||
            lower.contains('passive') ||
            lower.contains('personel')) &&
        _mentionsPenalty(lower)) {
      return RandomEventEffect(
        type: RandomEventEffectType.passivePenalty,
        value: _penaltyMultiplier(lower, fallback: 0.85),
        duration: _duration(lower),
      );
    }
    if ((lower.contains('pasif') ||
            lower.contains('passive') ||
            tags.contains('passive_boost')) &&
        _mentionsGain(lower)) {
      return RandomEventEffect(
        type: RandomEventEffectType.passiveBoost,
        value: _boostMultiplier(lower, fallback: 1.3),
        duration: _duration(lower),
        target: upfrontCost,
      );
    }
    if ((lower.contains('men?') || lower.contains('menu')) &&
        _mentionsPenalty(lower)) {
      return RandomEventEffect(
        type: RandomEventEffectType.menuPenalty,
        value: _penaltyMultiplier(lower, fallback: 0.85),
        duration: _duration(lower),
      );
    }
    if ((lower.contains('men?') ||
            lower.contains('menu') ||
            tags.contains('menu_boost')) &&
        _mentionsGain(lower)) {
      return RandomEventEffect(
        type: RandomEventEffectType.menuBoost,
        value: _boostMultiplier(lower, fallback: 1.25),
        duration: _duration(lower),
        target: upfrontCost,
      );
    }
    if (lower.contains('upgrade') && lower.contains('-')) {
      return RandomEventEffect(
        type: RandomEventEffectType.upgradeDiscount,
        value: _discountMultiplier(lower, fallback: 0.9),
        duration: _duration(lower),
        target: upfrontCost,
      );
    }
    if (lower.contains('upgrade') && lower.contains('+')) {
      return RandomEventEffect(
        type: RandomEventEffectType.upgradeCostPenalty,
        value: _boostMultiplier(lower, fallback: 1.08),
        duration: _duration(lower),
      );
    }
    if ((lower.contains('t?m gelir') ||
            lower.contains('gelir') ||
            tags.contains('global')) &&
        _mentionsPenalty(lower)) {
      return RandomEventEffect(
        type: RandomEventEffectType.globalPenalty,
        value: _penaltyMultiplier(lower, fallback: 0.9),
        duration: _duration(lower),
      );
    }
    if ((lower.contains('t?m gelir') ||
            lower.contains('gelir') ||
            tags.contains('global_boost')) &&
        _mentionsGain(lower)) {
      return RandomEventEffect(
        type: RandomEventEffectType.globalBoost,
        value: _boostMultiplier(lower, fallback: 1.25),
        duration: _duration(lower),
        target: upfrontCost,
      );
    }
    if (tags.contains('instant_money') || combined.contains('para')) {
      return RandomEventEffect(
        type: RandomEventEffectType.instantMoney,
        value: _incomeSeconds(combined),
        target: _reputationTarget(combined),
      );
    }
    if (tags.contains('money_cost')) {
      return RandomEventEffect(
        type: RandomEventEffectType.moneyCost,
        value: _percentValue(combined, fallback: 0.03),
        target: _capSeconds(combined),
      );
    }
    return const RandomEventEffect(
      type: RandomEventEffectType.noEffect,
      value: 0,
    );
  }

  static RandomEventOutcome _noEffect(
    String eventId,
    String choiceKey,
    String resultText,
  ) {
    return RandomEventOutcome(
      key: '${eventId}_${choiceKey}_no_effect',
      probability: 1,
      effect: const RandomEventEffect(
        type: RandomEventEffectType.noEffect,
        value: 0,
      ),
      resultText: resultText,
    );
  }

  static String _resultText(
    RandomEventEffectType type, {
    required bool isDecline,
  }) {
    if (isDecline && type == RandomEventEffectType.noEffect) {
      return 'F?rsat? pas ge?tin. D?kk?n d?zeni bozulmad?.';
    }
    return switch (type) {
      RandomEventEffectType.instantMoney =>
        'F?rsat kazanca d?nd?. Kasaya ek para girdi.',
      RandomEventEffectType.moneyCost => 'Bu karar?n k???k bir maliyeti oldu.',
      RandomEventEffectType.tapBoost => 'Kesim temposu y?kseldi.',
      RandomEventEffectType.tapPenalty =>
        'Kesim temposu k?sa s?reli?ine d??t?.',
      RandomEventEffectType.passiveBoost =>
        'Ekip daha verimli ?al??maya ba?lad?.',
      RandomEventEffectType.passivePenalty => 'Ekip k?sa s?reli?ine yava?lad?.',
      RandomEventEffectType.globalBoost => 'D?kk?n?n genel kazanc? y?kseldi.',
      RandomEventEffectType.globalPenalty =>
        'D?kk?n?n genel kazanc? k?sa s?reli?ine d??t?.',
      RandomEventEffectType.menuBoost =>
        'Men? etkisi k?sa s?reli?ine g??lendi.',
      RandomEventEffectType.menuPenalty =>
        'Men? etkisi k?sa s?reli?ine zay?flad?.',
      RandomEventEffectType.upgradeDiscount =>
        'Upgrade maliyetleri k?sa s?reli?ine d??t?.',
      RandomEventEffectType.upgradeCostPenalty =>
        'Upgrade maliyetleri k?sa s?reli?ine y?kseldi.',
      RandomEventEffectType.reputationGain => 'D?kk?n?n itibar? artt?.',
      RandomEventEffectType.reputationBoost ||
      RandomEventEffectType.reputationPenalty ||
      RandomEventEffectType.permanentBonus ||
      RandomEventEffectType.challengeStart ||
      RandomEventEffectType.noEffect => 'Kayda de?er bir de?i?iklik olmad?.',
    };
  }

  static bool _mentionsGain(String text) {
    return text.contains('+') ||
        text.contains('x') ||
        text.contains('?') ||
        text.contains('kazan') ||
        text.contains('s?f?rlan?r') ||
        text.contains('ba?ar?l?');
  }

  static bool _mentionsPenalty(String text) {
    return text.contains('-') ||
        text.contains('d??') ||
        text.contains('yar?ya') ||
        text.contains('ceza') ||
        text.contains('risk');
  }

  static bool _mentionsLoss(String text) {
    return text.contains('gider') ||
        text.contains('masraf') ||
        text.contains('ceza') ||
        text.contains('kayb');
  }

  static bool _hasSupportedPositiveEffect(String text, String tags) {
    if (!_mentionsGain(text)) {
      return false;
    }
    return text.contains('tap') ||
        text.contains('pasif') ||
        text.contains('passive') ||
        text.contains('tüm gelir') ||
        text.contains('gelir') ||
        text.contains('menü') ||
        text.contains('menu') ||
        text.contains('upgrade') ||
        tags.contains('tap_boost') ||
        tags.contains('passive_boost') ||
        tags.contains('global_boost') ||
        tags.contains('menu_boost') ||
        tags.contains('upgrade_discount');
  }

  static String? _costTarget(String text) {
    final lower = text.toLowerCase();
    if (!_mentionsLoss(lower)) {
      return null;
    }
    final percent = _percentValue(lower, fallback: 0);
    return percent > 0 ? 'cost:${percent.toStringAsFixed(3)}' : null;
  }

  static double _percentValue(String text, {required double fallback}) {
    final match = RegExp(r'%(\d+(?:[\.,]\d+)?)').firstMatch(text);
    if (match == null) {
      return fallback;
    }
    return (double.parse(match.group(1)!.replaceAll(',', '.')) / 100)
        .clamp(0, 1)
        .toDouble();
  }

  static double _incomeSeconds(String text) {
    final match = RegExp(r'[x?]\s*(\d+(?:[\.,]\d+)?)').firstMatch(text);
    if (match != null) {
      return double.parse(match.group(1)!.replaceAll(',', '.'));
    }
    if (text.contains('b?y?k')) {
      return 900;
    }
    if (text.contains('k???k')) {
      return 150;
    }
    return 300;
  }

  static double _boostMultiplier(String text, {required double fallback}) {
    final multiply = RegExp(r'[x?]\s*(\d+(?:[\.,]\d+)?)').firstMatch(text);
    if (multiply != null) {
      return double.parse(multiply.group(1)!.replaceAll(',', '.'));
    }
    final plus = RegExp(r'\+%\s*(\d+(?:[\.,]\d+)?)').firstMatch(text);
    if (plus != null) {
      return 1 + double.parse(plus.group(1)!.replaceAll(',', '.')) / 100;
    }
    return fallback;
  }

  static double _penaltyMultiplier(String text, {required double fallback}) {
    final minus = RegExp(r'-%\s*(\d+(?:[\.,]\d+)?)').firstMatch(text);
    if (minus != null) {
      return 1 - double.parse(minus.group(1)!.replaceAll(',', '.')) / 100;
    }
    if (text.contains('yar?ya')) {
      return 0.5;
    }
    return fallback;
  }

  static double _discountMultiplier(String text, {required double fallback}) {
    final minus = RegExp(r'-%\s*(\d+(?:[\.,]\d+)?)').firstMatch(text);
    if (minus != null) {
      return 1 - double.parse(minus.group(1)!.replaceAll(',', '.')) / 100;
    }
    return fallback;
  }

  static double _flatNumberAfter(
    String text,
    String word, {
    required double fallback,
  }) {
    final match = RegExp('$word\\s*\\+\\s*(\\d+)').firstMatch(text);
    if (match == null) {
      return fallback;
    }
    return double.parse(match.group(1)!);
  }

  static Duration? _duration(String text) {
    final minutes = RegExp(r'(\d+)\s*dakika').firstMatch(text);
    if (minutes != null) {
      return Duration(minutes: int.parse(minutes.group(1)!));
    }
    final seconds = RegExp(r'(\d+)\s*saniye').firstMatch(text);
    if (seconds != null) {
      return Duration(seconds: int.parse(seconds.group(1)!));
    }
    return null;
  }

  static String _capSeconds(String text) {
    if (text.contains('%8') || text.contains('%10')) {
      return '600';
    }
    if (text.contains('%6') || text.contains('%7')) {
      return '420';
    }
    return '300';
  }

  static String? _reputationTarget(String text) {
    final match = RegExp(r'itibar\s*\+\s*(\d+)').firstMatch(text);
    if (match == null) {
      return null;
    }
    return 'reputation:${match.group(1)}';
  }

  static RandomEventType _eventType(String value) {
    return switch (value) {
      'reward' => RandomEventType.reward,
      'risk' => RandomEventType.risk,
      'challenge' => RandomEventType.challenge,
      'maintenance' => RandomEventType.maintenance,
      'social' => RandomEventType.social,
      'funny' => RandomEventType.funny,
      'investment' => RandomEventType.investment,
      'staff' => RandomEventType.staff,
      'knife' => RandomEventType.knife,
      'menu' || 'recipe' => RandomEventType.menu,
      'crowd' => RandomEventType.crowd,
      'order' => RandomEventType.order,
      'festival' => RandomEventType.festival,
      'rival' => RandomEventType.rival,
      _ => RandomEventType.reward,
    };
  }

  static RandomEventRarity _rarity(String value) {
    return switch (value) {
      'rare' => RandomEventRarity.rare,
      'epic' => RandomEventRarity.epic,
      'legendary' => RandomEventRarity.legendary,
      _ => RandomEventRarity.common,
    };
  }
}

class _ProbabilityPiece {
  const _ProbabilityPiece(this.probability, this.segment);
  final double probability;
  final String segment;
}

class _EventSeed {
  const _EventSeed({
    required this.id,
    required this.title,
    required this.type,
    required this.rarity,
    required this.weight,
    required this.unlockCondition,
    required this.eventText,
    required this.acceptLabel,
    required this.declineLabel,
    required this.rewardSummary,
    required this.riskSummary,
    required this.acceptLogic,
    required this.declineLogic,
    required this.adOption,
    required this.effectTags,
    required this.cooldownGroup,
  });
  final String id;
  final String title;
  final String type;
  final String rarity;
  final int weight;
  final String unlockCondition;
  final String eventText;
  final String acceptLabel;
  final String declineLabel;
  final String rewardSummary;
  final String riskSummary;
  final String acceptLogic;
  final String declineLogic;
  final String adOption;
  final String effectTags;
  final String cooldownGroup;
}

const _eventSeeds = <_EventSeed>[
  _EventSeed(
    id: "EVT_001",
    title: "Döner Festivali",
    type: "social",
    rarity: "common",
    weight: 100,
    unlockCondition: "default",
    eventText:
        "Mahallede döner festivali düzenleniyor. Tezgâh açmak ister misin?",
    acceptLabel: "Katıl",
    declineLabel: "Boş Ver",
    rewardSummary: "5 dakikalık büyük kazanç",
    riskSummary: "Hazırlık masrafı",
    acceptLogic:
        "%70: 5 dakikalık kazanç ödülü. %30: mevcut paranın %5’i hazırlık masrafı olarak gider.",
    declineLogic:
        "Hayır seçilirse genelde hiçbir şey olmaz; sadece fırsat kaçar.",
    adOption: "",
    effectTags: "instant_money;money_cost",
    cooldownGroup: "festival",
  ),
  _EventSeed(
    id: "EVT_002",
    title: "Fenomen Ziyareti",
    type: "social",
    rarity: "rare",
    weight: 55,
    unlockCondition: "default",
    eventText:
        "Ünlü bir yemek fenomeni dükkânına geldi. Ona özel döner hazırlayacak mısın?",
    acceptLabel: "Hazırla",
    declineLabel: "Boş Ver",
    rewardSummary: "10 dakika tüm gelir x2",
    riskSummary: "Beğenmezse moral bozulur",
    acceptLogic:
        "%60: 10 dakika tüm gelir x2. %40: 3 dakika itibar kazanımı -%20 veya moral debuff.",
    declineLogic:
        "Hayır seçilirse genelde hiçbir şey olmaz; sadece fırsat kaçar.",
    adOption: "",
    effectTags: "global_boost;reputation_penalty",
    cooldownGroup: "social",
  ),
  _EventSeed(
    id: "EVT_003",
    title: "Gece Siparişi",
    type: "reward",
    rarity: "common",
    weight: 100,
    unlockCondition: "staff unlocked",
    eventText: "Gece yarısı büyük bir toplu sipariş geldi. Kabul edecek misin?",
    acceptLabel: "Kabul Et",
    declineLabel: "Reddet",
    rewardSummary: "Pasif gelir ×600 para",
    riskSummary: "Personel yorulur",
    acceptLogic:
        "Anında passiveIncomePerSecond × 600 para. %25 ek risk: 2 dakika pasif gelir -%20.",
    declineLogic:
        "Hayır seçilirse genelde hiçbir şey olmaz; sadece fırsat kaçar.",
    adOption: "",
    effectTags: "instant_money;passive_penalty",
    cooldownGroup: "order",
  ),
  _EventSeed(
    id: "EVT_004",
    title: "Gizemli Sos Ustası",
    type: "risk",
    rarity: "rare",
    weight: 55,
    unlockCondition: "menu unlocked",
    eventText:
        "Yaşlı bir sos ustası sana gizli tarifini öğretmek istiyor. Dinleyecek misin?",
    acceptLabel: "Dinle",
    declineLabel: "Reddet",
    rewardSummary: "10 dakika Menü etkisi +%25",
    riskSummary: "Sos tutmayabilir",
    acceptLogic:
        "%80: 10 dakika Menü etkisi +%25. %20: 2 dakika tap geliri -%15.",
    declineLogic:
        "Hayır seçilirse genelde hiçbir şey olmaz; sadece fırsat kaçar.",
    adOption: "",
    effectTags: "menu_boost;tap_penalty",
    cooldownGroup: "recipe",
  ),
  _EventSeed(
    id: "EVT_005",
    title: "Bozuk Ocak Alarmı",
    type: "maintenance",
    rarity: "common",
    weight: 100,
    unlockCondition: "oven unlocked",
    eventText: "Ocağın garip sesler çıkarıyor. Hemen tamirci çağıracak mısın?",
    acceptLabel: "Tamirci Çağır",
    declineLabel: "Bekle",
    rewardSummary: "5 dakika tüm gelir +%15",
    riskSummary: "Hayır seçilirse arıza riski",
    acceptLogic: "Evet: mevcut paranın %3’ü gider, 5 dakika tüm gelir +%15.",
    declineLogic: "%40: 2 dakika pasif gelir -%30. %60: hiçbir şey olmaz.",
    adOption: "",
    effectTags: "money_cost;global_boost;passive_penalty",
    cooldownGroup: "maintenance",
  ),
  _EventSeed(
    id: "EVT_006",
    title: "Aç Müşteri Grubu",
    type: "challenge",
    rarity: "common",
    weight: 100,
    unlockCondition: "default",
    eventText:
        "Bir otobüs dolusu aç müşteri dükkânın önünde durdu. Hepsine yetişmeye çalışır mısın?",
    acceptLabel: "Yetiş",
    declineLabel: "Boş Ver",
    rewardSummary: "60 saniye tap x3",
    riskSummary: "Turbo bekleme uzar",
    acceptLogic:
        "60 saniye boyunca her tap x3. Etkinlik bitince 2 dakika turbo cooldown uzar.",
    declineLogic:
        "Hayır seçilirse genelde hiçbir şey olmaz; sadece fırsat kaçar.",
    adOption: "",
    effectTags: "tap_boost;turbo_penalty",
    cooldownGroup: "crowd",
  ),
  _EventSeed(
    id: "EVT_007",
    title: "Rakip Dönerci Meydan Okudu",
    type: "challenge",
    rarity: "rare",
    weight: 55,
    unlockCondition: "knife item tier >= 2",
    eventText:
        "Yan sokaktaki dönerci en hızlı kesen kazansın diye meydan okudu.",
    acceptLabel: "Meydan Oku",
    declineLabel: "Boş Ver",
    rewardSummary: "Başarılı olursa büyük ödül",
    riskSummary: "Başaramazsan küçük kayıp",
    acceptLogic:
        "30 saniyelik tap challenge başlar. Başarılı: passiveIncomePerSecond × 900 para + itibar +1. Başarısız: mevcut paranın %3’ü gider.",
    declineLogic:
        "Hayır seçilirse genelde hiçbir şey olmaz; sadece fırsat kaçar.",
    adOption: "",
    effectTags: "challenge;instant_money;reputation;money_cost",
    cooldownGroup: "challenge",
  ),
  _EventSeed(
    id: "EVT_008",
    title: "Belediye Denetimi",
    type: "maintenance",
    rarity: "common",
    weight: 100,
    unlockCondition: "default",
    eventText: "Belediye denetimi geldi. Dükkânı toparlamak ister misin?",
    acceptLabel: "Toparla",
    declineLabel: "Risk Al",
    rewardSummary: "10 dakika itibar kazanımı +%20",
    riskSummary: "Ceza riski",
    acceptLogic:
        "Evet: mevcut paranın %4’ü gider, 10 dakika itibar kazanımı +%20.",
    declineLogic:
        "%35: mevcut paranın %8’i ceza olarak gider. %65: hiçbir şey olmaz.",
    adOption: "",
    effectTags: "money_cost;reputation_boost",
    cooldownGroup: "inspection",
  ),
  _EventSeed(
    id: "EVT_009",
    title: "Altın Et Fırsatı",
    type: "investment",
    rarity: "rare",
    weight: 55,
    unlockCondition: "menu unlocked",
    eventText:
        "Kasap özel kalite et teklif ediyor. Pahalı ama çok lezzetli görünüyor.",
    acceptLabel: "Satın Al",
    declineLabel: "Boş Ver",
    rewardSummary: "10 dakika tüm gelir x2.5",
    riskSummary: "Mevcut paranın %10’u gider",
    acceptLogic: "Mevcut paranın %10’u gider, 10 dakika tüm gelir x2.5.",
    declineLogic:
        "Hayır seçilirse genelde hiçbir şey olmaz; sadece fırsat kaçar.",
    adOption: "",
    effectTags: "money_cost;global_boost",
    cooldownGroup: "supplier",
  ),
  _EventSeed(
    id: "EVT_010",
    title: "Turbo Tüpü Bulundu",
    type: "reward",
    rarity: "common",
    weight: 100,
    unlockCondition: "turbo unlocked",
    eventText: "Depoda eski bir turbo tüpü buldun. Kullanmak ister misin?",
    acceptLabel: "Kullan",
    declineLabel: "Sakla",
    rewardSummary: "Turbo anında hazır olur",
    riskSummary: "Turbo süresi azalabilir",
    acceptLogic:
        "Turbo cooldown sıfırlanır. %20 risk: bir sonraki turbo süresi yarıya iner.",
    declineLogic:
        "Hayır seçilirse genelde hiçbir şey olmaz; sadece fırsat kaçar.",
    adOption: "",
    effectTags: "turbo_ready;turbo_penalty",
    cooldownGroup: "turbo",
  ),
  _EventSeed(
    id: "EVT_011",
    title: "Martı Döner Çaldı",
    type: "funny",
    rarity: "common",
    weight: 100,
    unlockCondition: "default",
    eventText: "Bir martı tezgahtan döner parçası kapıp kaçtı!",
    acceptLabel: "Kovala",
    declineLabel: "Boş Ver",
    rewardSummary: "Küçük para ödülü",
    riskSummary: "Zaman kaybı",
    acceptLogic:
        "%50: geri alırsın, passiveIncomePerSecond × 150 para. %50: 1 dakika pasif gelir -%10.",
    declineLogic:
        "Hayır seçilirse genelde hiçbir şey olmaz; sadece fırsat kaçar.",
    adOption: "",
    effectTags: "instant_money;passive_penalty",
    cooldownGroup: "funny",
  ),
  _EventSeed(
    id: "EVT_012",
    title: "Acı Sos Yarışması",
    type: "risk",
    rarity: "common",
    weight: 100,
    unlockCondition: "menu unlocked",
    eventText: "Müşteriler en acı döneri istiyor. Acı sosu basacak mısın?",
    acceptLabel: "Acıyı Bas",
    declineLabel: "Normal Yap",
    rewardSummary: "5 dakika tap +%50",
    riskSummary: "Fazla acı tepki çeker",
    acceptLogic: "%70: 5 dakika tap geliri +%50. %30: 2 dakika tüm gelir -%20.",
    declineLogic:
        "Hayır seçilirse genelde hiçbir şey olmaz; sadece fırsat kaçar.",
    adOption: "",
    effectTags: "tap_boost;global_penalty",
    cooldownGroup: "recipe",
  ),
  _EventSeed(
    id: "EVT_013",
    title: "Usta Morali Bozuk",
    type: "social",
    rarity: "common",
    weight: 100,
    unlockCondition: "staff unlocked",
    eventText: "Baş şefin morali bozuk. Ona çay ısmarlamak ister misin?",
    acceptLabel: "Çay Ismarla",
    declineLabel: "Boş Ver",
    rewardSummary: "5 dakika tüm gelir +%20",
    riskSummary: "Küçük masraf",
    acceptLogic: "Mevcut paranın %1’i gider, 5 dakika tüm gelir +%20.",
    declineLogic:
        "Hayır seçilirse genelde hiçbir şey olmaz; sadece fırsat kaçar.",
    adOption: "",
    effectTags: "money_cost;global_boost",
    cooldownGroup: "staff",
  ),
  _EventSeed(
    id: "EVT_014",
    title: "Gizli Müşteri",
    type: "social",
    rarity: "common",
    weight: 100,
    unlockCondition: "default",
    eventText:
        "Dükkâna gizemli bir müşteri geldi. Ona özel servis yapacak mısın?",
    acceptLabel: "Özel Servis",
    declineLabel: "Normal Servis",
    rewardSummary: "Bahşiş veya itibar",
    riskSummary: "Boşa gidebilir",
    acceptLogic:
        "%50: passiveIncomePerSecond × 500 para. %30: itibar +1. %20: hiçbir şey olmaz.",
    declineLogic:
        "Hayır seçilirse genelde hiçbir şey olmaz; sadece fırsat kaçar.",
    adOption: "",
    effectTags: "instant_money;reputation",
    cooldownGroup: "customer",
  ),
  _EventSeed(
    id: "EVT_015",
    title: "Döner Robotu Arızalandı",
    type: "maintenance",
    rarity: "rare",
    weight: 55,
    unlockCondition: "staff item tier >= 5",
    eventText: "Robot personel kısa devre yaptı. Elle müdahale edecek misin?",
    acceptLabel: "Müdahale Et",
    declineLabel: "Bekle",
    rewardSummary: "5 dakika pasif +%40",
    riskSummary: "Başarısız tamir",
    acceptLogic:
        "%60: 5 dakika pasif gelir +%40. %40: 2 dakika pasif gelir -%25.",
    declineLogic: "1 dakika pasif gelir -%10.",
    adOption: "",
    effectTags: "passive_boost;passive_penalty",
    cooldownGroup: "maintenance",
  ),
  _EventSeed(
    id: "EVT_016",
    title: "Büyük Catering Siparişi",
    type: "investment",
    rarity: "rare",
    weight: 55,
    unlockCondition: "staff unlocked",
    eventText:
        "Bir şirket 500 kişilik döner siparişi verdi. Kabul edecek misin?",
    acceptLabel: "Kabul Et",
    declineLabel: "Reddet",
    rewardSummary: "Büyük para ödülü",
    riskSummary: "Hazırlık masrafı",
    acceptLogic:
        "%50: passiveIncomePerSecond × 1000 para. %50: mevcut paranın %6’sı gider.",
    declineLogic:
        "Hayır seçilirse genelde hiçbir şey olmaz; sadece fırsat kaçar.",
    adOption: "Reklam İzle: başarı şansı %80 olur.",
    effectTags: "instant_money;money_cost;rewarded_ad",
    cooldownGroup: "order",
  ),
  _EventSeed(
    id: "EVT_017",
    title: "TV Programı Daveti",
    type: "social",
    rarity: "rare",
    weight: 55,
    unlockCondition: "prestige >= 1 or reputation >= 3",
    eventText:
        "Bir yemek programı seni yayına çağırıyor. Katılmak ister misin?",
    acceptLabel: "Katıl",
    declineLabel: "Boş Ver",
    rewardSummary: "İtibar +2 veya gelir boost",
    riskSummary: "Kötü performans riski",
    acceptLogic: "%60: itibar +2. %40: 5 dakika tüm gelir -%10.",
    declineLogic:
        "Hayır seçilirse genelde hiçbir şey olmaz; sadece fırsat kaçar.",
    adOption: "Reklam İzle: garanti itibar +1 ve 5 dakika gelir +%20.",
    effectTags: "reputation;global_penalty;rewarded_ad",
    cooldownGroup: "social",
  ),
  _EventSeed(
    id: "EVT_018",
    title: "Altın Döner Yarışması",
    type: "challenge",
    rarity: "epic",
    weight: 25,
    unlockCondition: "menu item tier >= 4",
    eventText:
        "Altın Döner Yarışması başladı. Katılım ücretli ama ödülü büyük.",
    acceptLabel: "Katıl",
    declineLabel: "Boş Ver",
    rewardSummary: "20 dakikalık gelir ödülü",
    riskSummary: "Katılım ücreti",
    acceptLogic:
        "Mevcut paranın %8’i gider. %40: passiveIncomePerSecond × 1200 para. %60: sadece deneyim kazanılır.",
    declineLogic:
        "Hayır seçilirse genelde hiçbir şey olmaz; sadece fırsat kaçar.",
    adOption: "Reklam İzle: katılım ücreti yarıya iner.",
    effectTags: "money_cost;instant_money;rewarded_ad",
    cooldownGroup: "festival",
  ),
  _EventSeed(
    id: "EVT_019",
    title: "Tedarikçi İndirimi",
    type: "investment",
    rarity: "common",
    weight: 100,
    unlockCondition: "default",
    eventText: "Tedarikçin bugün indirim yaptı. Malzeme stoklayacak mısın?",
    acceptLabel: "Stokla",
    declineLabel: "Boş Ver",
    rewardSummary: "10 dakika upgrade maliyeti -%10",
    riskSummary: "Ön ödeme gerekir",
    acceptLogic:
        "Mevcut paranın %2’si gider, 10 dakika tüm upgrade maliyetleri -%10.",
    declineLogic:
        "Hayır seçilirse genelde hiçbir şey olmaz; sadece fırsat kaçar.",
    adOption: "",
    effectTags: "upgrade_discount;money_cost",
    cooldownGroup: "supplier",
  ),
  _EventSeed(
    id: "EVT_020",
    title: "Çalışan Prim İstiyor",
    type: "staff",
    rarity: "common",
    weight: 100,
    unlockCondition: "staff unlocked",
    eventText: "Personel prim istiyor. Kabul edecek misin?",
    acceptLabel: "Prim Ver",
    declineLabel: "Reddet",
    rewardSummary: "10 dakika pasif +%30",
    riskSummary: "Para gider",
    acceptLogic: "Mevcut paranın %5’i gider, 10 dakika pasif gelir +%30.",
    declineLogic: "3 dakika pasif gelir -%10.",
    adOption: "",
    effectTags: "money_cost;passive_boost;passive_penalty",
    cooldownGroup: "staff",
  ),
  _EventSeed(
    id: "EVT_021",
    title: "Menüye Yeni Sos Ekle",
    type: "risk",
    rarity: "common",
    weight: 100,
    unlockCondition: "menu unlocked",
    eventText: "Yeni bir sos denemek ister misin?",
    acceptLabel: "Dene",
    declineLabel: "Boş Ver",
    rewardSummary: "5 dakika tüm gelir +%40",
    riskSummary: "Sos tutmayabilir",
    acceptLogic: "%50: 5 dakika tüm gelir +%40. %50: 3 dakika tap geliri -%15.",
    declineLogic:
        "Hayır seçilirse genelde hiçbir şey olmaz; sadece fırsat kaçar.",
    adOption: "",
    effectTags: "global_boost;tap_penalty",
    cooldownGroup: "recipe",
  ),
  _EventSeed(
    id: "EVT_022",
    title: "Ucuz Bıçak Satıcısı",
    type: "risk",
    rarity: "common",
    weight: 100,
    unlockCondition: "knife unlocked",
    eventText: "Bir satıcı ucuz bıçak bileme hizmeti teklif ediyor.",
    acceptLabel: "Kabul Et",
    declineLabel: "Reddet",
    rewardSummary: "5 dakika tap +%30",
    riskSummary: "Bıçak körelebilir",
    acceptLogic:
        "%70: 5 dakika tap geliri +%30. %30: 2 dakika tap geliri -%20.",
    declineLogic:
        "Hayır seçilirse genelde hiçbir şey olmaz; sadece fırsat kaçar.",
    adOption: "",
    effectTags: "tap_boost;tap_penalty",
    cooldownGroup: "knife",
  ),
  _EventSeed(
    id: "EVT_023",
    title: "Kalabalık Maç Günü",
    type: "social",
    rarity: "common",
    weight: 100,
    unlockCondition: "default",
    eventText:
        "Bugün maç var, herkes döner yemek istiyor. Hazırlık yapacak mısın?",
    acceptLabel: "Hazırlık Yap",
    declineLabel: "Boş Ver",
    rewardSummary: "10 dakika pasif +%50",
    riskSummary: "Hazırlık masrafı",
    acceptLogic: "Mevcut paranın %5’i gider, 10 dakika pasif gelir +%50.",
    declineLogic:
        "Hayır seçilirse genelde hiçbir şey olmaz; sadece fırsat kaçar.",
    adOption: "",
    effectTags: "money_cost;passive_boost",
    cooldownGroup: "crowd",
  ),
  _EventSeed(
    id: "EVT_024",
    title: "Paket Servis Patladı",
    type: "social",
    rarity: "rare",
    weight: 55,
    unlockCondition: "staff unlocked",
    eventText: "Paket servis uygulamasında aniden öne çıktın!",
    acceptLabel: "Kabul Et",
    declineLabel: "Reddet",
    rewardSummary: "5 dakika passive x2",
    riskSummary: "Yoğunluk turboyu etkileyebilir",
    acceptLogic:
        "5 dakika passive income x2. %25 risk: turbo cooldown +1 dakika.",
    declineLogic:
        "Hayır seçilirse genelde hiçbir şey olmaz; sadece fırsat kaçar.",
    adOption: "",
    effectTags: "passive_boost;turbo_penalty",
    cooldownGroup: "delivery",
  ),
  _EventSeed(
    id: "EVT_025",
    title: "Usta’dan Özel Ders",
    type: "reward",
    rarity: "common",
    weight: 100,
    unlockCondition: "knife unlocked",
    eventText: "Baş şef sana özel kesim tekniği göstermek istiyor.",
    acceptLabel: "Öğren",
    declineLabel: "Boş Ver",
    rewardSummary: "5 dakika tap +%75",
    riskSummary: "Yok",
    acceptLogic: "5 dakika tap geliri +%75.",
    declineLogic:
        "Hayır seçilirse genelde hiçbir şey olmaz; sadece fırsat kaçar.",
    adOption: "",
    effectTags: "tap_boost",
    cooldownGroup: "staff",
  ),
  _EventSeed(
    id: "EVT_026",
    title: "Efsane Turşucu Geldi",
    type: "risk",
    rarity: "common",
    weight: 100,
    unlockCondition: "menu unlocked",
    eventText:
        "Mahallenin meşhur turşucusu özel turşu suyu teklif ediyor. Menüye eklemek ister misin?",
    acceptLabel: "Ekle",
    declineLabel: "Boş Ver",
    rewardSummary: "8 dakika tüm gelir +%35",
    riskSummary: "Fazla ekşi olabilir",
    acceptLogic: "%60: 8 dakika tüm gelir +%35. %40: 3 dakika tap geliri -%15.",
    declineLogic:
        "Hayır seçilirse genelde hiçbir şey olmaz; sadece fırsat kaçar.",
    adOption: "",
    effectTags: "global_boost;tap_penalty",
    cooldownGroup: "recipe",
  ),
  _EventSeed(
    id: "EVT_027",
    title: "Gizli Baharat Sandığı",
    type: "risk",
    rarity: "rare",
    weight: 55,
    unlockCondition: "menu unlocked",
    eventText: "Depoda eski bir baharat sandığı buldun. Açmak ister misin?",
    acceptLabel: "Aç",
    declineLabel: "Açma",
    rewardSummary: "Menü boost veya para",
    riskSummary: "Bayat baharat riski",
    acceptLogic:
        "%40: 10 dakika menü bonusu +%50. %30: passiveIncomePerSecond × 400 para. %30: 2 dakika tüm gelir -%10.",
    declineLogic:
        "Hayır seçilirse genelde hiçbir şey olmaz; sadece fırsat kaçar.",
    adOption: "",
    effectTags: "menu_boost;instant_money;global_penalty",
    cooldownGroup: "recipe",
  ),
  _EventSeed(
    id: "EVT_028",
    title: "Dönerci Dededen Miras Tarif",
    type: "recipe",
    rarity: "epic",
    weight: 25,
    unlockCondition: "menu item tier >= 3",
    eventText:
        "Yaşlı bir dönerci bu tarif dedemden kaldı diyerek sır veriyor. Deneyecek misin?",
    acceptLabel: "Dene",
    declineLabel: "Boş Ver",
    rewardSummary: "15 dakika tüm gelir +%25 veya kalıcı bonus",
    riskSummary: "Yok",
    acceptLogic:
        "15 dakika tüm gelir +%25. %10 ekstra şans: kalıcı Menü etkisi +%1.",
    declineLogic:
        "Hayır seçilirse genelde hiçbir şey olmaz; sadece fırsat kaçar.",
    adOption: "",
    effectTags: "global_boost;permanent_bonus",
    cooldownGroup: "recipe",
  ),
  _EventSeed(
    id: "EVT_029",
    title: "Kediler Dükkâna Dadandı",
    type: "funny",
    rarity: "common",
    weight: 100,
    unlockCondition: "default",
    eventText:
        "Dükkânın önüne kediler toplandı. Onlara döner kırpığı verecek misin?",
    acceptLabel: "Besle",
    declineLabel: "Boş Ver",
    rewardSummary: "İtibar boost veya viral ödül",
    riskSummary: "Küçük maliyet",
    acceptLogic:
        "Mevcut paranın %2’si gider, 10 dakika itibar kazanımı +%30. %20 ek şans: passiveIncomePerSecond × 600 para.",
    declineLogic:
        "Hayır seçilirse genelde hiçbir şey olmaz; sadece fırsat kaçar.",
    adOption: "",
    effectTags: "money_cost;reputation_boost;instant_money",
    cooldownGroup: "funny",
  ),
  _EventSeed(
    id: "EVT_030",
    title: "Döner Bıçağı Ustası",
    type: "knife",
    rarity: "common",
    weight: 100,
    unlockCondition: "knife unlocked",
    eventText:
        "Bir bıçak ustası bıçağını özel taşla bilemek istiyor. Kabul eder misin?",
    acceptLabel: "Bilet",
    declineLabel: "Reddet",
    rewardSummary: "7 dakika tap +%80",
    riskSummary: "Fazla bileme riski",
    acceptLogic:
        "%75: 7 dakika tap geliri +%80. %25: 2 dakika tap geliri -%20.",
    declineLogic:
        "Hayır seçilirse genelde hiçbir şey olmaz; sadece fırsat kaçar.",
    adOption: "",
    effectTags: "tap_boost;tap_penalty",
    cooldownGroup: "knife",
  ),
  _EventSeed(
    id: "EVT_031",
    title: "Acil Düğün Siparişi",
    type: "order",
    rarity: "rare",
    weight: 55,
    unlockCondition: "staff unlocked",
    eventText:
        "Bir düğün salonundan son dakika döner siparişi geldi. Yetişebilir misin?",
    acceptLabel: "Yetiş",
    declineLabel: "Reddet",
    rewardSummary: "Büyük para veya gelir boost",
    riskSummary: "Yetişememe masrafı",
    acceptLogic:
        "%50: passiveIncomePerSecond × 900 para. %30: 5 dakika tüm gelir +%50. %20: mevcut paranın %5’i gider.",
    declineLogic:
        "Hayır seçilirse genelde hiçbir şey olmaz; sadece fırsat kaçar.",
    adOption: "",
    effectTags: "instant_money;global_boost;money_cost",
    cooldownGroup: "order",
  ),
  _EventSeed(
    id: "EVT_032",
    title: "Vegan Komşu Şikâyeti",
    type: "funny",
    rarity: "rare",
    weight: 55,
    unlockCondition: "menu unlocked",
    eventText:
        "Vegan komşu kokudan rahatsız olmuş. Ona özel etsiz menü yapmayı dener misin?",
    acceptLabel: "Dene",
    declineLabel: "Uğraşma",
    rewardSummary: "Yeni müşteri kitlesi",
    riskSummary: "Menü maliyeti veya itibar riski",
    acceptLogic:
        "%50: 10 dakika tüm gelir +%20. %50: mevcut paranın %3’ü gider.",
    declineLogic: "%20: itibar -1. %80: hiçbir şey olmaz.",
    adOption: "",
    effectTags: "global_boost;money_cost;reputation_penalty",
    cooldownGroup: "customer",
  ),
  _EventSeed(
    id: "EVT_033",
    title: "Döner Yeme Yarışması",
    type: "social",
    rarity: "common",
    weight: 100,
    unlockCondition: "default",
    eventText:
        "Dükkânın önünde döner yeme yarışması düzenleniyor. Sponsor olur musun?",
    acceptLabel: "Sponsor Ol",
    declineLabel: "Boş Ver",
    rewardSummary: "12 dakika pasif +%60",
    riskSummary: "Sponsor maliyeti",
    acceptLogic: "Mevcut paranın %4’ü gider, 12 dakika pasif gelir +%60.",
    declineLogic:
        "Hayır seçilirse genelde hiçbir şey olmaz; sadece fırsat kaçar.",
    adOption: "",
    effectTags: "money_cost;passive_boost",
    cooldownGroup: "festival",
  ),
  _EventSeed(
    id: "EVT_034",
    title: "Ünlü Gurme Kılık Değiştirmiş",
    type: "social",
    rarity: "rare",
    weight: 55,
    unlockCondition: "default",
    eventText:
        "Sıradan görünen bir müşteri aslında ünlü gurme olabilir. Ona özel servis yapacak mısın?",
    acceptLabel: "Özel Servis",
    declineLabel: "Normal Servis",
    rewardSummary: "İtibar veya bahşiş",
    riskSummary: "Boşa gidebilir",
    acceptLogic:
        "%35: itibar +2. %45: passiveIncomePerSecond × 500 para. %20: hiçbir şey olmaz.",
    declineLogic:
        "Hayır seçilirse genelde hiçbir şey olmaz; sadece fırsat kaçar.",
    adOption: "",
    effectTags: "reputation;instant_money",
    cooldownGroup: "customer",
  ),
  _EventSeed(
    id: "EVT_035",
    title: "Elektrikler Gitti",
    type: "maintenance",
    rarity: "common",
    weight: 100,
    unlockCondition: "oven unlocked",
    eventText: "Mahallede elektrikler kesildi. Jeneratör kiralayacak mısın?",
    acceptLabel: "Jeneratör Kirala",
    declineLabel: "Bekle",
    rewardSummary: "Pasif gelir korunur",
    riskSummary: "Maliyet veya kesinti",
    acceptLogic: "Evet: mevcut paranın %6’sı gider, pasif gelir etkilenmez.",
    declineLogic:
        "3 dakika pasif gelir -%50. %20 ek şans: müşteriler mum ışığını sever, 5 dakika itibar +%20.",
    adOption: "",
    effectTags: "money_cost;passive_penalty;reputation_boost",
    cooldownGroup: "maintenance",
  ),
  _EventSeed(
    id: "EVT_036",
    title: "Yanlışlıkla Acı Sos Patladı",
    type: "funny",
    rarity: "common",
    weight: 100,
    unlockCondition: "menu unlocked",
    eventText: "Acı sos şişesi patladı ve bütün döner baharatlandı!",
    acceptLabel: "Fırsata Çevir",
    declineLabel: "Temizle",
    rewardSummary: "5 dakika tap +%70",
    riskSummary: "Müşteri tepki riski",
    acceptLogic: "%50: 5 dakika tap geliri +%70. %50: 3 dakika tüm gelir -%20.",
    declineLogic: "Mevcut paranın %2’si gider, risk yok.",
    adOption: "",
    effectTags: "tap_boost;global_penalty;money_cost",
    cooldownGroup: "recipe",
  ),
  _EventSeed(
    id: "EVT_037",
    title: "Gizemli Müşteri Bahşişi",
    type: "reward",
    rarity: "common",
    weight: 100,
    unlockCondition: "default",
    eventText: "Bir müşteri masaya gizemli bir zarf bıraktı. Açacak mısın?",
    acceptLabel: "Aç",
    declineLabel: "Açma",
    rewardSummary: "Para veya itibar",
    riskSummary: "Boş çıkabilir",
    acceptLogic:
        "%50: passiveIncomePerSecond × 500 para. %20: itibar +1. %30: zarf boş çıkar.",
    declineLogic:
        "Hayır seçilirse genelde hiçbir şey olmaz; sadece fırsat kaçar.",
    adOption: "",
    effectTags: "instant_money;reputation",
    cooldownGroup: "customer",
  ),
  _EventSeed(
    id: "EVT_038",
    title: "Sosyal Medya Challenge",
    type: "challenge",
    rarity: "rare",
    weight: 55,
    unlockCondition: "turbo unlocked",
    eventText:
        "1 dakikada en çok döner kesme challenge’ı trend oldu. Katılacak mısın?",
    acceptLabel: "Katıl",
    declineLabel: "Boş Ver",
    rewardSummary: "10 dakika tap x2",
    riskSummary: "Başarısızlık penalty",
    acceptLogic:
        "60 saniyelik mini görev. Başarılı: 10 dakika tap geliri x2. Başarısız: 2 dakika tap geliri -%10.",
    declineLogic:
        "Hayır seçilirse genelde hiçbir şey olmaz; sadece fırsat kaçar.",
    adOption: "",
    effectTags: "challenge;tap_boost;tap_penalty",
    cooldownGroup: "challenge",
  ),
  _EventSeed(
    id: "EVT_039",
    title: "Kayıp Turist Kafilesi",
    type: "social",
    rarity: "common",
    weight: 100,
    unlockCondition: "default",
    eventText:
        "Bir turist kafilesi yanlışlıkla dükkânına geldi. Menü anlatmaya çalışır mısın?",
    acceptLabel: "Anlat",
    declineLabel: "Boş Ver",
    rewardSummary: "Büyük sipariş",
    riskSummary: "İletişim karışır",
    acceptLogic:
        "%60: passiveIncomePerSecond × 700 para. %40: 2 dakika gelir -%10.",
    declineLogic:
        "Hayır seçilirse genelde hiçbir şey olmaz; sadece fırsat kaçar.",
    adOption: "",
    effectTags: "instant_money;global_penalty",
    cooldownGroup: "customer",
  ),
  _EventSeed(
    id: "EVT_040",
    title: "Kasapla Pazarlık",
    type: "investment",
    rarity: "common",
    weight: 100,
    unlockCondition: "default",
    eventText: "Kasap bugün fiyatları artırmış. Sıkı pazarlık yapacak mısın?",
    acceptLabel: "Pazarlık Yap",
    declineLabel: "Boş Ver",
    rewardSummary: "10 dakika upgrade maliyeti -%12",
    riskSummary: "Maliyet artabilir",
    acceptLogic:
        "%50: 10 dakika upgrade maliyetleri -%12. %50: 5 dakika upgrade maliyetleri +%8.",
    declineLogic:
        "Hayır seçilirse genelde hiçbir şey olmaz; sadece fırsat kaçar.",
    adOption: "",
    effectTags: "upgrade_discount;upgrade_cost_penalty",
    cooldownGroup: "supplier",
  ),
  _EventSeed(
    id: "EVT_041",
    title: "Lahmacuncu ile Ortak Menü",
    type: "social",
    rarity: "common",
    weight: 100,
    unlockCondition: "menu unlocked",
    eventText:
        "Yan dükkândaki lahmacuncu ortak kampanya teklif ediyor. Kabul eder misin?",
    acceptLabel: "Kabul Et",
    declineLabel: "Reddet",
    rewardSummary: "10 dakika tüm gelir +%30",
    riskSummary: "Müşteri kayması",
    acceptLogic:
        "10 dakika tüm gelir +%30. %25 risk: 3 dakika tap geliri -%15.",
    declineLogic:
        "Hayır seçilirse genelde hiçbir şey olmaz; sadece fırsat kaçar.",
    adOption: "",
    effectTags: "global_boost;tap_penalty",
    cooldownGroup: "partnership",
  ),
  _EventSeed(
    id: "EVT_042",
    title: "Usta Uyuyakaldı",
    type: "funny",
    rarity: "common",
    weight: 100,
    unlockCondition: "staff unlocked",
    eventText: "Baş şef öğle arasında uyuyakaldı. Onu uyandıracak mısın?",
    acceptLabel: "Uyandır",
    declineLabel: "Bırak Uyusun",
    rewardSummary: "Pasif veya tap bonus",
    riskSummary: "Moral riski",
    acceptLogic:
        "%80: 5 dakika pasif gelir +%25. %20: 2 dakika pasif gelir -%15.",
    declineLogic:
        "3 dakika pasif gelir -%10 ama sonra 5 dakika tap geliri +%20.",
    adOption: "",
    effectTags: "passive_boost;passive_penalty;tap_boost",
    cooldownGroup: "staff",
  ),
  _EventSeed(
    id: "EVT_043",
    title: "Döner Kokusu Sokakta Yayılıyor",
    type: "social",
    rarity: "common",
    weight: 100,
    unlockCondition: "default",
    eventText:
        "Döner kokusu tüm sokağa yayıldı. Kapıya reklam tabelası koyacak mısın?",
    acceptLabel: "Tabela Koy",
    declineLabel: "Bekle",
    rewardSummary: "15 dakika pasif +%35",
    riskSummary: "Tabela masrafı",
    acceptLogic: "Mevcut paranın %3’ü gider, 15 dakika pasif gelir +%35.",
    declineLogic: "3 dakika tüm gelir +%10.",
    adOption: "",
    effectTags: "money_cost;passive_boost;global_boost",
    cooldownGroup: "marketing",
  ),
  _EventSeed(
    id: "EVT_044",
    title: "Sos Tarifi Çalındı",
    type: "risk",
    rarity: "rare",
    weight: 55,
    unlockCondition: "menu unlocked",
    eventText:
        "Rakip dönerci sos tarifini çalmaya çalışıyor. Peşine düşecek misin?",
    acceptLabel: "Peşine Düş",
    declineLabel: "Boş Ver",
    rewardSummary: "İtibar + boost",
    riskSummary: "Zaman kaybı",
    acceptLogic:
        "%60: itibar +1 ve 5 dakika tüm gelir +%20. %40: 2 dakika pasif gelir -%15.",
    declineLogic: "%20: 5 dakika menü bonusu -%15. %80: hiçbir şey olmaz.",
    adOption: "",
    effectTags: "reputation;global_boost;passive_penalty;menu_penalty",
    cooldownGroup: "rival",
  ),
  _EventSeed(
    id: "EVT_045",
    title: "Altın Bıçak Efsanesi",
    type: "challenge",
    rarity: "rare",
    weight: 55,
    unlockCondition: "knife item tier >= 5",
    eventText:
        "Bir müşteri altın bıçakla kesilen döner daha lezzetli olur diyor. Gösteri yapar mısın?",
    acceptLabel: "Gösteri Yap",
    declineLabel: "Boş Ver",
    rewardSummary: "30 saniye kritik tap",
    riskSummary: "Bıçak kayabilir",
    acceptLogic:
        "30 saniye boyunca her tap için kritik kazanç şansı. %20 risk: 1 dakika tap geliri -%20.",
    declineLogic:
        "Hayır seçilirse genelde hiçbir şey olmaz; sadece fırsat kaçar.",
    adOption: "",
    effectTags: "crit_tap;tap_penalty",
    cooldownGroup: "knife",
  ),
  _EventSeed(
    id: "EVT_046",
    title: "Dönerci Marşı",
    type: "funny",
    rarity: "common",
    weight: 100,
    unlockCondition: "staff unlocked",
    eventText:
        "Personel kendi dönerci marşını yazmış. Dükkânda çaldıracak mısın?",
    acceptLabel: "Çal",
    declineLabel: "Çalma",
    rewardSummary: "8 dakika pasif +%25",
    riskSummary: "Müşteri rahatsız olabilir",
    acceptLogic:
        "%70: 8 dakika pasif gelir +%25. %30: 2 dakika itibar kazanımı -%20.",
    declineLogic: "Personel üzülür: 2 dakika pasif gelir -%5.",
    adOption: "",
    effectTags: "passive_boost;reputation_penalty;passive_penalty",
    cooldownGroup: "staff",
  ),
  _EventSeed(
    id: "EVT_047",
    title: "Paketçi Motoru Bozuldu",
    type: "maintenance",
    rarity: "common",
    weight: 100,
    unlockCondition: "staff unlocked",
    eventText: "Paketçinin motoru bozuldu. Tamir ettirecek misin?",
    acceptLabel: "Tamir Ettir",
    declineLabel: "Bekle",
    rewardSummary: "10 dakika pasif +%40",
    riskSummary: "Maliyet veya pasif düşüş",
    acceptLogic: "Mevcut paranın %4’ü gider, 10 dakika pasif gelir +%40.",
    declineLogic: "5 dakika pasif gelir -%20.",
    adOption: "",
    effectTags: "money_cost;passive_boost;passive_penalty",
    cooldownGroup: "delivery",
  ),
  _EventSeed(
    id: "EVT_048",
    title: "Belediye Başkanı Geldi",
    type: "social",
    rarity: "rare",
    weight: 55,
    unlockCondition: "reputation >= 2",
    eventText:
        "Belediye başkanı döner yemeye geldi. Özel tabak hazırlayacak mısın?",
    acceptLabel: "Hazırla",
    declineLabel: "Boş Ver",
    rewardSummary: "İtibar veya gelir boost",
    riskSummary: "Masraf",
    acceptLogic:
        "%40: itibar +2. %40: 10 dakika tüm gelir +%35. %20: mevcut paranın %5’i gider.",
    declineLogic:
        "Hayır seçilirse genelde hiçbir şey olmaz; sadece fırsat kaçar.",
    adOption: "",
    effectTags: "reputation;global_boost;money_cost",
    cooldownGroup: "customer",
  ),
  _EventSeed(
    id: "EVT_049",
    title: "Döner Uçağa Gidiyor",
    type: "order",
    rarity: "epic",
    weight: 25,
    unlockCondition: "staff item tier >= 3",
    eventText:
        "Havalimanından acil VIP döner siparişi geldi. Yetiştirebilir misin?",
    acceptLabel: "Yetiştir",
    declineLabel: "Reddet",
    rewardSummary: "Çok büyük para veya boost",
    riskSummary: "Yetişememe",
    acceptLogic:
        "%35: passiveIncomePerSecond × 1200 para. %35: 10 dakika tüm gelir +%50. %30: 3 dakika pasif gelir -%25.",
    declineLogic:
        "Hayır seçilirse genelde hiçbir şey olmaz; sadece fırsat kaçar.",
    adOption: "",
    effectTags: "instant_money;global_boost;passive_penalty",
    cooldownGroup: "order",
  ),
  _EventSeed(
    id: "EVT_050",
    title: "Gizli Sos Kazanı Taştı",
    type: "maintenance",
    rarity: "common",
    weight: 100,
    unlockCondition: "menu unlocked",
    eventText: "Gizli sos kazanı taşmak üzere. Hemen müdahale edecek misin?",
    acceptLabel: "Müdahale Et",
    declineLabel: "Bekle",
    rewardSummary: "8 dakika menü +%40",
    riskSummary: "Sos boşa gidebilir",
    acceptLogic:
        "%70: 8 dakika menü bonusu +%40. %30: mevcut paranın %4’ü gider.",
    declineLogic: "2 dakika menü bonusu -%20.",
    adOption: "",
    effectTags: "menu_boost;money_cost;menu_penalty",
    cooldownGroup: "recipe",
  ),
  _EventSeed(
    id: "EVT_051",
    title: "Döner Kralı Seçmeleri",
    type: "challenge",
    rarity: "epic",
    weight: 25,
    unlockCondition: "reputation >= 5",
    eventText: "Şehirde Döner Kralı seçmeleri başlıyor. Katılmak ister misin?",
    acceptLabel: "Katıl",
    declineLabel: "Katılma",
    rewardSummary: "İtibar +3 veya 15 dakika gelir +%50",
    riskSummary: "Hazırlık masrafı",
    acceptLogic:
        "%40: itibar +3. %40: 15 dakika tüm gelir +%50. %20: mevcut paranın %6’sı gider.",
    declineLogic:
        "Hayır seçilirse genelde hiçbir şey olmaz; sadece fırsat kaçar.",
    adOption: "",
    effectTags: "reputation;global_boost;money_cost",
    cooldownGroup: "festival",
  ),
  _EventSeed(
    id: "EVT_052",
    title: "Gizli Eleştirmen Masada",
    type: "social",
    rarity: "rare",
    weight: 55,
    unlockCondition: "default",
    eventText:
        "Bir müşteri sürekli not alıyor. Gizli eleştirmen olabilir. Özel servis yapacak mısın?",
    acceptLabel: "Özel Servis",
    declineLabel: "Boş Ver",
    rewardSummary: "İtibar veya menü boost",
    riskSummary: "Fazla masraf",
    acceptLogic:
        "%50: itibar +2. %30: 10 dakika menü bonusu +%40. %20: mevcut paranın %4’ü gider.",
    declineLogic:
        "Hayır seçilirse genelde hiçbir şey olmaz; sadece fırsat kaçar.",
    adOption: "",
    effectTags: "reputation;menu_boost;money_cost",
    cooldownGroup: "customer",
  ),
  _EventSeed(
    id: "EVT_053",
    title: "Ekmek Fırını Grevde",
    type: "maintenance",
    rarity: "common",
    weight: 100,
    unlockCondition: "default",
    eventText:
        "Mahalle fırını bugün ekmek yetiştiremiyor. Alternatif ekmek alacak mısın?",
    acceptLabel: "Alternatif Al",
    declineLabel: "Bekle",
    rewardSummary: "8 dakika pasif +%25",
    riskSummary: "Maliyet veya gelir düşüşü",
    acceptLogic: "Mevcut paranın %3’ü gider, 8 dakika pasif gelir +%25.",
    declineLogic: "5 dakika tüm gelir -%15.",
    adOption: "",
    effectTags: "money_cost;passive_boost;global_penalty",
    cooldownGroup: "supplier",
  ),
  _EventSeed(
    id: "EVT_054",
    title: "Sos Şelalesi",
    type: "funny",
    rarity: "common",
    weight: 100,
    unlockCondition: "menu unlocked",
    eventText:
        "Sos makinesi yanlışlıkla fazla sos sıkıyor. Bunu yeni lezzet diye sunacak mısın?",
    acceptLabel: "Sun",
    declineLabel: "Durdur",
    rewardSummary: "6 dakika tap +%60",
    riskSummary: "Fazla sos tepki çeker",
    acceptLogic: "%60: 6 dakika tap geliri +%60. %40: 3 dakika tüm gelir -%15.",
    declineLogic:
        "Hayır seçilirse genelde hiçbir şey olmaz; sadece fırsat kaçar.",
    adOption: "",
    effectTags: "tap_boost;global_penalty",
    cooldownGroup: "recipe",
  ),
  _EventSeed(
    id: "EVT_055",
    title: "Öğrenci İndirimi Günü",
    type: "social",
    rarity: "common",
    weight: 100,
    unlockCondition: "default",
    eventText: "Öğrenciler kapıda sıra oldu. İndirim yapacak mısın?",
    acceptLabel: "İndirim Yap",
    declineLabel: "Yapma",
    rewardSummary: "10 dakika pasif +%50",
    riskSummary: "Kazanç başına gelir düşer",
    acceptLogic: "10 dakika pasif gelir +%50 ama 5 dakika tüm gelir -%10.",
    declineLogic:
        "Hayır seçilirse genelde hiçbir şey olmaz; sadece fırsat kaçar.",
    adOption: "",
    effectTags: "passive_boost;global_penalty",
    cooldownGroup: "customer",
  ),
  _EventSeed(
    id: "EVT_056",
    title: "Kasadaki Bozuk Para Bereketi",
    type: "reward",
    rarity: "common",
    weight: 100,
    unlockCondition: "default",
    eventText: "Kasada unutulmuş bozuk para kutusu buldun. Sayacak mısın?",
    acceptLabel: "Say",
    declineLabel: "Boş Ver",
    rewardSummary: "Pasif gelir ×250 para",
    riskSummary: "Yok",
    acceptLogic:
        "Anında passiveIncomePerSecond × 250 para. %20 ek şans: itibar +1.",
    declineLogic:
        "Hayır seçilirse genelde hiçbir şey olmaz; sadece fırsat kaçar.",
    adOption: "",
    effectTags: "instant_money;reputation",
    cooldownGroup: "cash",
  ),
  _EventSeed(
    id: "EVT_057",
    title: "Müşteri Bol Soğan İstiyor",
    type: "funny",
    rarity: "common",
    weight: 100,
    unlockCondition: "menu unlocked",
    eventText:
        "Bir müşteri herkese bol soğanlı döner önermeye başladı. Bu akımı büyütecek misin?",
    acceptLabel: "Büyüt",
    declineLabel: "Boş Ver",
    rewardSummary: "8 dakika tüm gelir +%30",
    riskSummary: "İtibar düşebilir",
    acceptLogic:
        "%50: 8 dakika tüm gelir +%30. %50: 3 dakika itibar kazanımı -%20.",
    declineLogic:
        "Hayır seçilirse genelde hiçbir şey olmaz; sadece fırsat kaçar.",
    adOption: "",
    effectTags: "global_boost;reputation_penalty",
    cooldownGroup: "customer",
  ),
  _EventSeed(
    id: "EVT_058",
    title: "Döner Selfie Noktası",
    type: "investment",
    rarity: "rare",
    weight: 55,
    unlockCondition: "reputation >= 2",
    eventText:
        "Müşteriler dönerle fotoğraf çekmek istiyor. Selfie köşesi kuracak mısın?",
    acceptLabel: "Kur",
    declineLabel: "Kurma",
    rewardSummary: "20 dakika itibar +%50 veya viral para",
    riskSummary: "Kurulum maliyeti",
    acceptLogic:
        "Mevcut paranın %5’i gider, 20 dakika itibar kazanımı +%50. %25 ek şans: passiveIncomePerSecond × 800 para.",
    declineLogic:
        "Hayır seçilirse genelde hiçbir şey olmaz; sadece fırsat kaçar.",
    adOption: "",
    effectTags: "money_cost;reputation_boost;instant_money",
    cooldownGroup: "marketing",
  ),
  _EventSeed(
    id: "EVT_059",
    title: "Eski Usta Geri Döndü",
    type: "staff",
    rarity: "rare",
    weight: 55,
    unlockCondition: "staff unlocked",
    eventText: "Dükkânın eski ustası bir günlüğüne yardım etmek istiyor.",
    acceptLabel: "Kabul Et",
    declineLabel: "Reddet",
    rewardSummary: "10 dakika pasif +%60",
    riskSummary: "Personel morali riski",
    acceptLogic:
        "10 dakika pasif gelir +%60. %20 risk: 3 dakika personel geliri -%15.",
    declineLogic:
        "Hayır seçilirse genelde hiçbir şey olmaz; sadece fırsat kaçar.",
    adOption: "",
    effectTags: "passive_boost;passive_penalty",
    cooldownGroup: "staff",
  ),
  _EventSeed(
    id: "EVT_060",
    title: "Yanlışlıkla VIP Sos Kullanıldı",
    type: "risk",
    rarity: "rare",
    weight: 55,
    unlockCondition: "menu item tier >= 3",
    eventText:
        "Normal sos yerine pahalı VIP sos kullanılmış. Bunu premium menü diye satacak mısın?",
    acceptLabel: "Premium Sat",
    declineLabel: "Durdur",
    rewardSummary: "8 dakika tüm gelir +%70",
    riskSummary: "Maliyet patlar",
    acceptLogic:
        "%50: 8 dakika tüm gelir +%70. %50: mevcut paranın %7’si gider.",
    declineLogic: "Mevcut paranın %3’ü gider.",
    adOption: "",
    effectTags: "global_boost;money_cost",
    cooldownGroup: "recipe",
  ),
  _EventSeed(
    id: "EVT_061",
    title: "Paket Servis Influencer’ı",
    type: "social",
    rarity: "rare",
    weight: 55,
    unlockCondition: "staff unlocked",
    eventText:
        "Paket servis yorumlarında bir influencer seni övmüş. Kampanya başlatacak mısın?",
    acceptLabel: "Başlat",
    declineLabel: "Başlatma",
    rewardSummary: "12 dakika pasif +%70",
    riskSummary: "Kampanya maliyeti",
    acceptLogic:
        "Mevcut paranın %4’ü gider, 12 dakika pasif gelir +%70. %20 ek şans: itibar +1.",
    declineLogic:
        "Hayır seçilirse genelde hiçbir şey olmaz; sadece fırsat kaçar.",
    adOption: "",
    effectTags: "money_cost;passive_boost;reputation",
    cooldownGroup: "delivery",
  ),
  _EventSeed(
    id: "EVT_062",
    title: "Döner Sırası Taştı",
    type: "crowd",
    rarity: "common",
    weight: 100,
    unlockCondition: "staff unlocked",
    eventText:
        "Dükkânın önünde sıra sokağa kadar uzadı. Geçici personel çağıracak mısın?",
    acceptLabel: "Personel Çağır",
    declineLabel: "Çağırma",
    rewardSummary: "10 dakika pasif +%80",
    riskSummary: "Personel maliyeti veya itibar riski",
    acceptLogic: "Mevcut paranın %5’i gider, 10 dakika pasif gelir +%80.",
    declineLogic: "5 dakika tüm gelir +%20 ama 2 dakika itibar kazanımı -%20.",
    adOption: "",
    effectTags: "money_cost;passive_boost;global_boost;reputation_penalty",
    cooldownGroup: "crowd",
  ),
  _EventSeed(
    id: "EVT_063",
    title: "Mangal Dumanı Alarmı",
    type: "maintenance",
    rarity: "common",
    weight: 100,
    unlockCondition: "oven unlocked",
    eventText:
        "Duman fazla yükseldi, komşular bakmaya başladı. Havalandırmayı açacak mısın?",
    acceptLabel: "Aç",
    declineLabel: "Açma",
    rewardSummary: "Sorun çözülür",
    riskSummary: "Gelir düşebilir",
    acceptLogic: "Mevcut paranın %2’si gider, sorun çözülür.",
    declineLogic: "%50: hiçbir şey olmaz. %50: 4 dakika tüm gelir -%20.",
    adOption: "",
    effectTags: "money_cost;global_penalty",
    cooldownGroup: "maintenance",
  ),
  _EventSeed(
    id: "EVT_064",
    title: "Usta Bıçağını Kaybetti",
    type: "funny",
    rarity: "common",
    weight: 100,
    unlockCondition: "knife unlocked",
    eventText:
        "Baş şef favori bıçağını bulamıyor. Aramaya yardım edecek misin?",
    acceptLabel: "Ara",
    declineLabel: "Arama",
    rewardSummary: "8 dakika tap +%50",
    riskSummary: "Zaman kaybı",
    acceptLogic:
        "%60: 8 dakika tap geliri +%50. %40: 2 dakika tap geliri -%10.",
    declineLogic: "3 dakika tap geliri -%15.",
    adOption: "",
    effectTags: "tap_boost;tap_penalty",
    cooldownGroup: "knife",
  ),
  _EventSeed(
    id: "EVT_065",
    title: "Döner Akademisi Daveti",
    type: "social",
    rarity: "epic",
    weight: 25,
    unlockCondition: "prestige >= 1",
    eventText: "Döner Akademisi seni konuşmacı olarak çağırıyor. Gider misin?",
    acceptLabel: "Git",
    declineLabel: "Gitme",
    rewardSummary: "İtibar +2 veya kalıcı Staff +%1",
    riskSummary: "Dükkân boş kalır",
    acceptLogic:
        "%50: itibar +2. %30: kalıcı Staff effect +%1. %20: 3 dakika pasif gelir -%20.",
    declineLogic:
        "Hayır seçilirse genelde hiçbir şey olmaz; sadece fırsat kaçar.",
    adOption: "",
    effectTags: "reputation;permanent_bonus;passive_penalty",
    cooldownGroup: "social",
  ),
  _EventSeed(
    id: "EVT_066",
    title: "Baharatçı Yanlış Paket Gönderdi",
    type: "risk",
    rarity: "rare",
    weight: 55,
    unlockCondition: "menu unlocked",
    eventText:
        "Baharatçı yanlışlıkla çok özel bir karışım göndermiş. Kullanacak mısın?",
    acceptLabel: "Kullan",
    declineLabel: "İade Et",
    rewardSummary: "Menü boost veya para",
    riskSummary: "Tadı garip olabilir",
    acceptLogic:
        "%45: 10 dakika menü bonusu +%60. %35: passiveIncomePerSecond × 400 para. %20: 3 dakika tüm gelir -%15.",
    declineLogic: "Küçük para ödülü: passiveIncomePerSecond × 100.",
    adOption: "",
    effectTags: "menu_boost;instant_money;global_penalty",
    cooldownGroup: "supplier",
  ),
  _EventSeed(
    id: "EVT_067",
    title: "Şefin Eski Rakibi Geldi",
    type: "rival",
    rarity: "rare",
    weight: 55,
    unlockCondition: "prestige >= 1",
    eventText:
        "Baş şefin eski rakibi dükkâna geldi ve sessizce döner sipariş etti.",
    acceptLabel: "Özel Hazırla",
    declineLabel: "Normal Servis",
    rewardSummary: "İtibar +2 veya tap +%80",
    riskSummary: "Stres",
    acceptLogic:
        "%50: itibar +2. %30: 5 dakika tap geliri +%80. %20: 2 dakika tap geliri -%15.",
    declineLogic:
        "Hayır seçilirse genelde hiçbir şey olmaz; sadece fırsat kaçar.",
    adOption: "",
    effectTags: "reputation;tap_boost;tap_penalty",
    cooldownGroup: "rival",
  ),
  _EventSeed(
    id: "EVT_068",
    title: "Döner Arabası Kiralama",
    type: "investment",
    rarity: "rare",
    weight: 55,
    unlockCondition: "staff item tier >= 2",
    eventText:
        "Bir etkinlik için mobil döner arabası kiralama fırsatı var. Kiralar mısın?",
    acceptLabel: "Kirala",
    declineLabel: "Kiralama",
    rewardSummary: "20 dakika pasif +%80",
    riskSummary: "Kira maliyeti",
    acceptLogic: "Mevcut paranın %8’i gider, 20 dakika pasif gelir +%80.",
    declineLogic:
        "Hayır seçilirse genelde hiçbir şey olmaz; sadece fırsat kaçar.",
    adOption: "",
    effectTags: "money_cost;passive_boost",
    cooldownGroup: "festival",
  ),
  _EventSeed(
    id: "EVT_069",
    title: "Çocuk Menüsü Fikri",
    type: "menu",
    rarity: "common",
    weight: 100,
    unlockCondition: "menu unlocked",
    eventText:
        "Bir aile çocuklar için mini döner menüsü önerdi. Menüye ekleyecek misin?",
    acceptLabel: "Ekle",
    declineLabel: "Ekleme",
    rewardSummary: "12 dakika tüm gelir +%25",
    riskSummary: "Menü karışabilir",
    acceptLogic:
        "%60: 12 dakika tüm gelir +%25. %40: 3 dakika pasif gelir -%10.",
    declineLogic:
        "Hayır seçilirse genelde hiçbir şey olmaz; sadece fırsat kaçar.",
    adOption: "",
    effectTags: "global_boost;passive_penalty",
    cooldownGroup: "recipe",
  ),
  _EventSeed(
    id: "EVT_070",
    title: "Sıra Dışı Bahşiş",
    type: "reward",
    rarity: "common",
    weight: 100,
    unlockCondition: "default",
    eventText:
        "Bir müşteri hayatımın döneriydi deyip bahşiş bırakıyor. Kabul edecek misin?",
    acceptLabel: "Kabul Et",
    declineLabel: "Nazikçe Reddet",
    rewardSummary: "Para veya itibar",
    riskSummary: "Yok",
    acceptLogic: "Anında passiveIncomePerSecond × 500 para.",
    declineLogic: "İtibar +1.",
    adOption: "",
    effectTags: "instant_money;reputation",
    cooldownGroup: "customer",
  ),
  _EventSeed(
    id: "EVT_071",
    title: "Döner Tabelası Düştü",
    type: "maintenance",
    rarity: "common",
    weight: 100,
    unlockCondition: "default",
    eventText: "Dükkân tabelası yamuldu. Hemen tamir ettirecek misin?",
    acceptLabel: "Tamir Ettir",
    declineLabel: "Bekle",
    rewardSummary: "10 dakika itibar +%25",
    riskSummary: "Pasif gelir düşebilir",
    acceptLogic: "Mevcut paranın %3’ü gider, 10 dakika itibar kazanımı +%25.",
    declineLogic: "%35: 5 dakika pasif gelir -%15. %65: hiçbir şey olmaz.",
    adOption: "",
    effectTags: "money_cost;reputation_boost;passive_penalty",
    cooldownGroup: "maintenance",
  ),
  _EventSeed(
    id: "EVT_072",
    title: "Yanlışlıkla Büyük Porsiyon",
    type: "funny",
    rarity: "common",
    weight: 100,
    unlockCondition: "staff unlocked",
    eventText:
        "Personel herkese büyük porsiyon hazırlamış. Bunu kampanya diye duyuracak mısın?",
    acceptLabel: "Duyur",
    declineLabel: "Durdur",
    rewardSummary: "8 dakika pasif +%60",
    riskSummary: "Maliyet",
    acceptLogic: "8 dakika pasif gelir +%60, mevcut paranın %5’i gider.",
    declineLogic:
        "Hayır seçilirse genelde hiçbir şey olmaz; sadece fırsat kaçar.",
    adOption: "",
    effectTags: "passive_boost;money_cost",
    cooldownGroup: "staff",
  ),
  _EventSeed(
    id: "EVT_073",
    title: "Döner Tost Denemesi",
    type: "recipe",
    rarity: "common",
    weight: 100,
    unlockCondition: "menu unlocked",
    eventText: "Personel döner tost icat etti. Menüye koymayı dener misin?",
    acceptLabel: "Dene",
    declineLabel: "Hayır",
    rewardSummary: "Gelir boost veya para",
    riskSummary: "Tutmama riski",
    acceptLogic:
        "%40: 10 dakika tüm gelir +%60. %40: passiveIncomePerSecond × 300 para. %20: 2 dakika tüm gelir -%10.",
    declineLogic:
        "Hayır seçilirse genelde hiçbir şey olmaz; sadece fırsat kaçar.",
    adOption: "",
    effectTags: "global_boost;instant_money;global_penalty",
    cooldownGroup: "recipe",
  ),
  _EventSeed(
    id: "EVT_074",
    title: "Şehir Dışı Festival Daveti",
    type: "festival",
    rarity: "rare",
    weight: 55,
    unlockCondition: "staff item tier >= 2",
    eventText: "Başka şehirde yemek festivali var. Ekip gönderecek misin?",
    acceptLabel: "Ekip Gönder",
    declineLabel: "Gönderme",
    rewardSummary: "Pasif boost veya itibar",
    riskSummary: "Yorgunluk ve maliyet",
    acceptLogic:
        "Mevcut paranın %6’sı gider. %50: 15 dakika pasif +%70. %30: itibar +2. %20: 3 dakika pasif -%15.",
    declineLogic:
        "Hayır seçilirse genelde hiçbir şey olmaz; sadece fırsat kaçar.",
    adOption: "",
    effectTags: "money_cost;passive_boost;reputation;passive_penalty",
    cooldownGroup: "festival",
  ),
  _EventSeed(
    id: "EVT_075",
    title: "Dönerci Rüyası",
    type: "funny",
    rarity: "common",
    weight: 100,
    unlockCondition: "knife unlocked",
    eventText:
        "Baş şef rüyasında mükemmel kesim tekniği gördü. Denemesini ister misin?",
    acceptLabel: "Dene",
    declineLabel: "Boş Ver",
    rewardSummary: "6 dakika tap +%70",
    riskSummary: "Rüya karışık çıkabilir",
    acceptLogic:
        "%70: 6 dakika tap geliri +%70. %30: 2 dakika tap geliri -%10.",
    declineLogic:
        "Hayır seçilirse genelde hiçbir şey olmaz; sadece fırsat kaçar.",
    adOption: "",
    effectTags: "tap_boost;tap_penalty",
    cooldownGroup: "staff",
  ),
  _EventSeed(
    id: "EVT_076",
    title: "Komşu Esnaf Dayanışması",
    type: "social",
    rarity: "common",
    weight: 100,
    unlockCondition: "default",
    eventText: "Yan dükkânlar ortak kampanya yapmak istiyor. Katılır mısın?",
    acceptLabel: "Katıl",
    declineLabel: "Katılma",
    rewardSummary: "12 dakika tüm gelir +%25 veya itibar",
    riskSummary: "Yok",
    acceptLogic: "12 dakika tüm gelir +%25. %20 ek şans: itibar +1.",
    declineLogic:
        "Hayır seçilirse genelde hiçbir şey olmaz; sadece fırsat kaçar.",
    adOption: "",
    effectTags: "global_boost;reputation",
    cooldownGroup: "partnership",
  ),
  _EventSeed(
    id: "EVT_077",
    title: "Yanlış Adrese Sipariş",
    type: "maintenance",
    rarity: "common",
    weight: 100,
    unlockCondition: "delivery unlocked",
    eventText:
        "Büyük bir sipariş yanlış adrese gitmiş. Telafi gönderecek misin?",
    acceptLabel: "Telafi Et",
    declineLabel: "Etme",
    rewardSummary: "İtibar +1",
    riskSummary: "Maliyet veya itibar kaybı",
    acceptLogic: "Mevcut paranın %4’ü gider, itibar +1.",
    declineLogic: "%40: 5 dakika itibar kazanımı -%30. %60: hiçbir şey olmaz.",
    adOption: "",
    effectTags: "money_cost;reputation;reputation_penalty",
    cooldownGroup: "delivery",
  ),
  _EventSeed(
    id: "EVT_078",
    title: "Menüde Gizli Ürün",
    type: "recipe",
    rarity: "rare",
    weight: 55,
    unlockCondition: "menu item tier >= 2",
    eventText:
        "Personel gizli menü fikri öneriyor. Sadece bilenlere satılsın mı?",
    acceptLabel: "Başlat",
    declineLabel: "Hayır",
    rewardSummary: "Menü bonusu veya itibar",
    riskSummary: "Boşa çıkabilir",
    acceptLogic:
        "%50: 15 dakika menü bonusu +%40. %30: itibar +1. %20: kimse bilmez, hiçbir şey olmaz.",
    declineLogic:
        "Hayır seçilirse genelde hiçbir şey olmaz; sadece fırsat kaçar.",
    adOption: "",
    effectTags: "menu_boost;reputation",
    cooldownGroup: "recipe",
  ),
  _EventSeed(
    id: "EVT_079",
    title: "Yeni Paket Tasarımı",
    type: "investment",
    rarity: "common",
    weight: 100,
    unlockCondition: "delivery unlocked",
    eventText: "Döner paketlerini yenilemek ister misin?",
    acceptLabel: "Yenile",
    declineLabel: "Hayır",
    rewardSummary: "20 dakika itibar +%40",
    riskSummary: "Tasarım maliyeti",
    acceptLogic:
        "Mevcut paranın %5’i gider, 20 dakika itibar kazanımı +%40. %20 ek şans: 10 dakika pasif +%25.",
    declineLogic:
        "Hayır seçilirse genelde hiçbir şey olmaz; sadece fırsat kaçar.",
    adOption: "",
    effectTags: "money_cost;reputation_boost;passive_boost",
    cooldownGroup: "marketing",
  ),
  _EventSeed(
    id: "EVT_080",
    title: "Döner Sosu Şişelensin",
    type: "investment",
    rarity: "rare",
    weight: 55,
    unlockCondition: "menu item tier >= 3",
    eventText:
        "Müşteriler sosunu şişe olarak satın almak istiyor. Deneyecek misin?",
    acceptLabel: "Şişele",
    declineLabel: "Hayır",
    rewardSummary: "Büyük para veya gelir boost",
    riskSummary: "Şişeleme maliyeti",
    acceptLogic:
        "%45: passiveIncomePerSecond × 1000 para. %35: 10 dakika tüm gelir +%35. %20: mevcut paranın %6’sı gider.",
    declineLogic:
        "Hayır seçilirse genelde hiçbir şey olmaz; sadece fırsat kaçar.",
    adOption: "",
    effectTags: "instant_money;global_boost;money_cost",
    cooldownGroup: "recipe",
  ),
];
