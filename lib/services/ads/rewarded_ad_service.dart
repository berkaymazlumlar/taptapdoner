enum RewardOutcome { granted, declined, unavailable, failed }

abstract interface class RewardedAdService {
  bool get isAvailable;

  Future<RewardOutcome> showOfflineRewardDouble();
}

class NoopRewardedAdService implements RewardedAdService {
  const NoopRewardedAdService();

  @override
  bool get isAvailable => false;

  @override
  Future<RewardOutcome> showOfflineRewardDouble() async {
    return RewardOutcome.unavailable;
  }
}
