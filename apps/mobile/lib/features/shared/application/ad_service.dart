import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final adServiceProvider = Provider((ref) => AdService());

class AdService {
  RewardedAd? _rewardedAd;
  bool _isAdLoaded = false;

  void loadRewardedAd() {
    RewardedAd.load(
      adUnitId: _getAdUnitId(),
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isAdLoaded = true;
        },
        onAdFailedToLoad: (error) {
          debugPrint('RewardedAd failed to load: $error');
          _isAdLoaded = false;
        },
      ),
    );
  }

  void showRewardedAd(
      {required VoidCallback onReward, required VoidCallback onClosed}) {
    if (!_isAdLoaded || _rewardedAd == null) {
      debugPrint('Ad not loaded yet');
      onClosed();
      return;
    }

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _isAdLoaded = false;
        loadRewardedAd(); // Preload next ad
        onClosed();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _isAdLoaded = false;
        loadRewardedAd();
        onClosed();
      },
    );

    _rewardedAd!.show(
      onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
        onReward();
      },
    );
  }

  String _getAdUnitId() {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'ca-app-pub-3940256099942544/5224354917'; // Android Test Rewarded Ad ID
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      return 'ca-app-pub-3940256099942544/1712485313'; // iOS Test Rewarded Ad ID
    } else {
      return '';
    }
  }
}
