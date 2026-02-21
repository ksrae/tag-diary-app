import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/premium/application/purchase_provider.dart';
import 'package:mobile/core/services/firestore_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

final aiUsageServiceProvider = Provider((ref) => AiUsageService(ref));

class AiUsageService {
  final Ref _ref;
  AiUsageService(this._ref);

  bool get isPro => _ref.read(isProProvider);
  SubscriptionPlan get plan => _ref.read(subscriptionPlanProvider);

  Future<({int usageCount, int adRewardCount})> _getStats() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().split('T')[0];
    final usageKey = 'ai_usage_$today';
    final rewardKey = 'ai_ad_reward_$today';

    return (
      usageCount: prefs.getInt(usageKey) ?? 0,
      adRewardCount: prefs.getInt(rewardKey) ?? 0,
    );
  }

  /// Daily AI limit per plan:
  /// - Free: 0 (+ 1 ad reward max)
  /// - Basic: 3
  /// - Pro: 5
  Future<int> getMaxDailyLimit() async {
    final stats = await _getStats();

    switch (plan) {
      case SubscriptionPlan.pro:
        return 5;
      case SubscriptionPlan.basic:
        return 3;
      case SubscriptionPlan.free:
        // Free users: 0 base + up to 1 ad reward per day
        return stats.adRewardCount;
    }
  }

  Future<int> getRemainingCount() async {
    final maxLimit = await getMaxDailyLimit();
    final stats = await _getStats();
    return (maxLimit - stats.usageCount).clamp(0, 999);
  }

  Future<bool> canGenerate() async {
    final remaining = await getRemainingCount();
    return remaining > 0;
  }

  Future<bool> canWatchAd() async {
    if (isPro) return false;
    final stats = await _getStats();
    // Free user logic: Can watch ad if reward count is < 1 (max 1 reward per day)
    return stats.adRewardCount < 1;
  }

  Future<void> incrementUsage() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().split('T')[0];
    final usageKey = 'ai_usage_$today';
    final count = prefs.getInt(usageKey) ?? 0;
    await prefs.setInt(usageKey, count + 1);
  }

  Future<void> addReward() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().split('T')[0];
    final rewardKey = 'ai_ad_reward_$today';
    final count = prefs.getInt(rewardKey) ?? 0;
    await prefs.setInt(rewardKey, count + 1);
  }
}
