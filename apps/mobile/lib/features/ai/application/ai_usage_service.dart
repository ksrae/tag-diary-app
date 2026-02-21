import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/premium/application/purchase_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

final aiUsageServiceProvider = Provider((ref) => AiUsageService(ref));

class AiUsageService {
  final Ref _ref;
  AiUsageService(this._ref);

  bool get isPro => _ref.read(isProProvider);

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

  Future<int> getMaxDailyLimit() async {
    if (isPro) return 3; // Pro limit
    final stats = await _getStats();
    // Default 0 + max 1 ad reward (based on user request: 본 0회/일 + 광고 시청 시 1회 추가 (최대 1회/일))
    // Wait, the user pseudo code said "1 + adRewardCount" but text said 0. Let's make it 0 + adRewardCount (max 1 reward).
    return stats.adRewardCount;
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
