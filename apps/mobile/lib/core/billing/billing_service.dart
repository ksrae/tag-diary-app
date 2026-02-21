import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../services/firestore_service.dart';

part 'billing_service.g.dart';

class BillingService {
  static const String _revenueCatAppleApiKey = 'YOUR_APPLE_API_KEY';
  static const String _revenueCatGoogleApiKey = 'YOUR_GOOGLE_API_KEY';

  Future<void> init() async {
    await Purchases.setLogLevel(LogLevel.debug);

    PurchasesConfiguration configuration;
    if (defaultTargetPlatform == TargetPlatform.android) {
      configuration = PurchasesConfiguration(_revenueCatGoogleApiKey);
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      configuration = PurchasesConfiguration(_revenueCatAppleApiKey);
    } else {
      return;
    }

    await Purchases.configure(configuration);
  }

  /// 사용자가 어떤 요금제인지 확인
  Future<SubscriptionPlan> getCurrentPlan() async {
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      
      final entitlements = customerInfo.entitlements.all;
      if (entitlements['pro']?.isActive ?? false) return SubscriptionPlan.pro;
      if (entitlements['basic']?.isActive ?? false) return SubscriptionPlan.basic;
      
      return SubscriptionPlan.free;
    } catch (e) {
      return SubscriptionPlan.free;
    }
  }

  Future<Offerings?> getOfferings() async {
    try {
      return await Purchases.getOfferings();
    } catch (e) {
      debugPrint('Failed to get offerings: $e');
      return null;
    }
  }

  Future<SubscriptionPlan> purchasePackage(Package package) async {
    try {
      final customerInfo = await Purchases.purchasePackage(package);
      final entitlements = customerInfo.entitlements.all;
      
      if (entitlements['pro']?.isActive ?? false) return SubscriptionPlan.pro;
      if (entitlements['basic']?.isActive ?? false) return SubscriptionPlan.basic;
      
      return SubscriptionPlan.free;
    } catch (e) {
      debugPrint('Purchase failed or cancelled: $e');
      return SubscriptionPlan.free;
    }
  }

  Future<bool> purchaseCapacityAddon(Package package) async {
     try {
       // 단건 결제: 서버에서 추가 용량을 늘려줘야 하므로 결제 성공 여부만 리턴
       await Purchases.purchasePackage(package);
       return true;
     } catch (e) {
       return false;
     }
  }

  Future<SubscriptionPlan> restorePurchases() async {
    try {
      final customerInfo = await Purchases.restorePurchases();
      final entitlements = customerInfo.entitlements.all;
      
      if (entitlements['pro']?.isActive ?? false) return SubscriptionPlan.pro;
      if (entitlements['basic']?.isActive ?? false) return SubscriptionPlan.basic;
      
      return SubscriptionPlan.free;
    } catch (e) {
      debugPrint('Restore failed: $e');
      return SubscriptionPlan.free;
    }
  }
}

@riverpod
class ActiveSubscriptionPlan extends _$ActiveSubscriptionPlan {
  final _billingService = BillingService();

  @override
  FutureOr<SubscriptionPlan> build() async {
    return _billingService.getCurrentPlan();
  }

  Future<void> checkStatus() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _billingService.getCurrentPlan());
  }

  Future<SubscriptionPlan> purchase(Package package) async {
    state = const AsyncValue.loading();
    final plan = await _billingService.purchasePackage(package);
    state = AsyncValue.data(plan);
    return plan;
  }
}
