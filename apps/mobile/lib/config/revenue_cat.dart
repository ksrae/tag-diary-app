import 'dart:io';

class RevenueCatConfig {
  // Placeholder keys - Replace with actual keys from RevenueCat dashboard
  static const String appleApiKey = 'appl_placeholder_key';
  static const String googleApiKey = 'goog_placeholder_key';

  static String get apiKey {
    if (Platform.isAndroid) {
      return googleApiKey;
    } else if (Platform.isIOS) {
      return appleApiKey;
    }
    return '';
  }

  static const String entitlementId = 'pro'; // Identifier configured in RevenueCat
}
