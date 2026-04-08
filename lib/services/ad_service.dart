import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firestore_service.dart';

class AdService {
  AdService._();

  static final AdService instance = AdService._();

  static const int dailyLimit = 10;

  Future<void> init() async {
    await MobileAds.instance.initialize();
  }

  Future<bool> canWatchAd() async {
    final prefs = await SharedPreferences.getInstance();
    final date = DateTime.now().toIso8601String().split('T').first;
    final currentDate = prefs.getString('ad_date_${FirebaseAuth.instance.currentUser!.uid}') ?? '';
    if (currentDate != date) {
      await prefs.setString('ad_date_${FirebaseAuth.instance.currentUser!.uid}', date);
      await prefs.setInt('ad_count_${FirebaseAuth.instance.currentUser!.uid}', 0);
    }
    final count = prefs.getInt('ad_count_${FirebaseAuth.instance.currentUser!.uid}') ?? 0;
    return count < dailyLimit;
  }

  Future<void> watchRewardedAd({required void Function(String) onError, required void Function() onReward}) async {
    if (!await canWatchAd()) {
      onError('Daily ad limit reached (10/10).');
      return;
    }

    await RewardedAd.load(
      adUnitId: 'ca-app-pub-3940256099942544/5224354917',
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) => ad.dispose(),
            onAdFailedToShowFullScreenContent: (ad, err) {
              ad.dispose();
              onError(err.message);
            },
          );
          ad.show(onUserEarnedReward: (ad, reward) async {
            final prefs = await SharedPreferences.getInstance();
            final key = 'ad_count_${FirebaseAuth.instance.currentUser!.uid}';
            final count = prefs.getInt(key) ?? 0;
            await prefs.setInt(key, count + 1);
            await FirestoreService.instance.claimReward(coins: 20, source: 'Rewarded Ad completed');
            onReward();
          });
        },
        onAdFailedToLoad: (error) => onError(error.message),
      ),
    );
  }
}
