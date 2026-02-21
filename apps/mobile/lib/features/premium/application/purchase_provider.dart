import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:mobile/config/revenue_cat.dart';
import 'package:mobile/features/premium/data/purchase_repository.dart';
import 'package:mobile/core/services/firestore_service.dart';

final purchaseRepositoryProvider = Provider<PurchaseRepository>((ref) {
  return PurchaseRepository();
});

/// Current subscription plan provider (Free/Basic/Pro)
final subscriptionPlanProvider = StateNotifierProvider<SubscriptionPlanNotifier, SubscriptionPlan>((ref) {
  return SubscriptionPlanNotifier(ref.watch(purchaseRepositoryProvider));
});

/// Backward-compatible isPro provider (true if plan != free)
final isProProvider = StateNotifierProvider<IsProNotifier, bool>((ref) {
  return IsProNotifier(ref.watch(purchaseRepositoryProvider));
});

class SubscriptionPlanNotifier extends StateNotifier<SubscriptionPlan> {
  final PurchaseRepository _repository;

  SubscriptionPlanNotifier(this._repository) : super(SubscriptionPlan.free) {
    _init();
  }

  Future<void> _init() async {
    const isDebugPro = bool.fromEnvironment('IS_PRO', defaultValue: false);
    if (isDebugPro) {
      state = SubscriptionPlan.pro;
      return;
    }

    await _repository.init();
    await checkStatus();

    Purchases.addCustomerInfoUpdateListener((customerInfo) {
      _updateStatus(customerInfo);
    });
  }

  Future<void> checkStatus() async {
    const isDebugPro = bool.fromEnvironment('IS_PRO', defaultValue: false);
    if (isDebugPro) {
      state = SubscriptionPlan.pro;
      return;
    }

    final customerInfo = await _repository.getCustomerInfo();
    _updateStatus(customerInfo);
  }

  void _updateStatus(CustomerInfo? customerInfo) {
    const isDebugPro = bool.fromEnvironment('IS_PRO', defaultValue: false);
    if (isDebugPro) {
      state = SubscriptionPlan.pro;
      return;
    }

    if (customerInfo == null) return;

    final entitlements = customerInfo.entitlements.all;
    if (entitlements['pro']?.isActive ?? false) {
      state = SubscriptionPlan.pro;
    } else if (entitlements['basic']?.isActive ?? false) {
      state = SubscriptionPlan.basic;
    } else {
      state = SubscriptionPlan.free;
    }
  }

  Future<SubscriptionPlan> purchasePackage(Package package) async {
    final customerInfo = await _repository.purchasePackage(package);
    _updateStatus(customerInfo);
    return state;
  }

  Future<SubscriptionPlan> restorePurchases() async {
    final customerInfo = await _repository.restorePurchases();
    _updateStatus(customerInfo);
    return state;
  }
}

class IsProNotifier extends StateNotifier<bool> {
  final PurchaseRepository _repository;

  IsProNotifier(this._repository) : super(false) {
    _init();
  }

  Future<void> _init() async {
    // Check for debug override
    const isDebugPro = bool.fromEnvironment('IS_PRO', defaultValue: false);
    if (isDebugPro) {
      state = true;
      return;
    }

    await _repository.init();
    await checkProStatus();
    
    // Listen for real-time updates
    Purchases.addCustomerInfoUpdateListener((customerInfo) {
      _updateStatus(customerInfo);
    });
  }

  Future<void> checkProStatus() async {
    const isDebugPro = bool.fromEnvironment('IS_PRO', defaultValue: false);
    if (isDebugPro) {
      state = true;
      return;
    }
    
    final customerInfo = await _repository.getCustomerInfo();
    _updateStatus(customerInfo);
  }

  void _updateStatus(CustomerInfo? customerInfo) {
    const isDebugPro = bool.fromEnvironment('IS_PRO', defaultValue: false);
    if (isDebugPro) {
      state = true;
      return;
    }

    if (customerInfo == null) return;
    
    // isPro = true if either basic or pro entitlement is active (any paid plan)
    final entitlements = customerInfo.entitlements.all;
    final hasPro = entitlements['pro']?.isActive ?? false;
    final hasBasic = entitlements['basic']?.isActive ?? false;
    state = hasPro || hasBasic;
  }
  
  Future<bool> purchasePackage(Package package) async {
    final customerInfo = await _repository.purchasePackage(package);
    _updateStatus(customerInfo);
    return state; // Returns true if purchase resulted in Pro status
  }
  
  Future<bool> restorePurchases() async {
    final customerInfo = await _repository.restorePurchases();
    _updateStatus(customerInfo);
    return state;
  }
}
