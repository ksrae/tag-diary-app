import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:mobile/config/revenue_cat.dart';
import 'package:mobile/features/premium/data/purchase_repository.dart';

final purchaseRepositoryProvider = Provider<PurchaseRepository>((ref) {
  return PurchaseRepository();
});

final isProProvider = StateNotifierProvider<IsProNotifier, bool>((ref) {
  return IsProNotifier(ref.watch(purchaseRepositoryProvider));
});

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
    
    final entitlement = customerInfo.entitlements.all[RevenueCatConfig.entitlementId];
    state = entitlement?.isActive ?? false;
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
