import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:mobile/config/revenue_cat.dart';

class PurchaseRepository {
  bool _isConfigured = false;

  Future<void> init() async {
    if (_isConfigured) return;

    await Purchases.setLogLevel(LogLevel.debug);

    PurchasesConfiguration configuration =
        PurchasesConfiguration(RevenueCatConfig.apiKey);

    await Purchases.configure(configuration);
    _isConfigured = true;
  }

  Future<Offerings?> getOfferings() async {
    try {
      await init();
      return await Purchases.getOfferings();
    } on PlatformException catch (e) {
      print('Error getting offerings: $e');
      return null;
    }
  }

  Future<CustomerInfo?> purchasePackage(Package package) async {
    try {
      await init();
      return await Purchases.purchasePackage(package);
    } on PlatformException catch (e) {
      var errorCode = PurchasesErrorHelper.getErrorCode(e);
      if (errorCode != PurchasesErrorCode.purchaseCancelledError) {
        print('Error purchasing package: $e');
      }
      return null;
    }
  }

  Future<CustomerInfo?> restorePurchases() async {
    try {
      await init();
      return await Purchases.restorePurchases();
    } on PlatformException catch (e) {
      print('Error restoring purchases: $e');
      return null;
    }
  }

  Future<CustomerInfo?> getCustomerInfo() async {
    try {
      await init();
      return await Purchases.getCustomerInfo();
    } on PlatformException catch (e) {
      print('Error getting customer info: $e');
      return null;
    }
  }
}
