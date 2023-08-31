import 'dart:io';
import 'package:chat/utils/shared_pref.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdHelper {
  static InterstitialAd? _interstitialAd;
  static const String _lastAdDisplayKey = 'last_ad_display';
  static const String _adDisplayCountKey = 'ad_display_count';

  static String get bannerAdUnitId {
    if (Platform.isAndroid) {
      //working banner id ca-app-pub-7181343877669077/1377492143   ca-app-pub-7181343877669077/1377492143
      // return 'ca-app-pub-3940256099942544/6300978111';
      return 'ca-app-pub-7181343877669077/5678624787';
    } else if (Platform.isIOS) {
      // return 'ca-app-pub-7181343877669077/5410197832';
      return 'ca-app-pub-7181343877669077/2375844027';
      // return 'ca-app-pub-3940256099942544/2934735716';
    } else {
      throw new UnsupportedError('Unsupported platform');
    }
  }

  static String get interstitialAdUnitId {
    if (Platform.isAndroid) {
      // return "ca-app-pub-7181343877669077/9813069201";
      return "ca-app-pub-7181343877669077/5759349989";
    } else if (Platform.isIOS) {
      // return "ca-app-pub-7181343877669077/5345359476";
      return "ca-app-pub-7181343877669077/9871190663";
      //return "ca-app-pub-3940256099942544/4411468910";
    } else {
      throw new UnsupportedError("Unsupported platform");
    }
  }

  static String get rewardedAdUnitId {
    if (Platform.isAndroid) {
      return "ca-app-pub-3940256099942544/5224354917";
    } else if (Platform.isIOS) {
      return "ca-app-pub-3940256099942544/1712485313";
    } else {
      throw new UnsupportedError("Unsupported platform");
    }
  }

  static String get openAppAdUnitId {
    if (Platform.isAndroid) {
      //working banner id ca-app-pub-7181343877669077/1377492143   ca-app-pub-7181343877669077/1377492143
      // return 'ca-app-pub-3940256099942544/6300978111';
      return 'ca-app-pub-7181343877669077/8346499195';
    } else if (Platform.isIOS) {
      // return 'ca-app-pub-7181343877669077/5410197832';
      return 'ca-app-pub-7181343877669077/7556177613';
      // return 'ca-app-pub-3940256099942544/2934735716';
    } else {
      throw new UnsupportedError('Unsupported platform');
    }
  }

  Future<void> createInterstitialAd() async {
    await InterstitialAd.load(
        adUnitId: AdHelper.interstitialAdUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (InterstitialAd ad) {
            debugPrint('$ad loaded');
            _interstitialAd = ad;
            _interstitialAd!.setImmersiveMode(true);
          },
          onAdFailedToLoad: (LoadAdError error) {
            debugPrint('InterstitialAd failed to load: $error.');
            _interstitialAd = null;
            createInterstitialAd();
          },
        ));
  }

  void showInterstitialAd() async {
    print(
        '*********************************************************showInterstitialAd');
    SharedPreferences prefs = await SharedPreferences.getInstance();
    // Retrieve saved values
    int lastAdTimestamp = prefs.getInt(_lastAdDisplayKey) ?? 0;
    int adDisplayCount = prefs.getInt(_adDisplayCountKey) ?? 0;
    // Calculate time difference
    int currentTime = DateTime.now().millisecondsSinceEpoch;
    int timeDifference = currentTime - lastAdTimestamp;

    // Load Interstitial Ad
    await createInterstitialAd();

    if (_interstitialAd == null) {
      // Debug
      debugPrint('Warning: attempt to show interstitial before loaded.');
      return;
    }
    // Run callbacks
    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (InterstitialAd ad) =>
          debugPrint('ad onAdShowedFullScreenContent.'),
      onAdDismissedFullScreenContent: (InterstitialAd ad) {
        debugPrint('$ad onAdDismissedFullScreenContent.');
        ad.dispose();
        createInterstitialAd();
      },
      onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
        debugPrint('$ad onAdFailedToShowFullScreenContent: $error');
        ad.dispose();
        createInterstitialAd();
      },
    );

    // _interstitialAd!.show();
    // _interstitialAd = null;

    //start

    print('-----------------------ad count $adDisplayCount');

    // Display ad if conditions are met
    if (adDisplayCount < 2) {
      print(
          '*********************************************************if adDisplayCount < 3');
      // Show the interstitial ad here
      //  AdHelper().showInterstitialAd();
      _interstitialAd!.show();
      _interstitialAd = null;

      // Update values
      await prefs.setInt(_lastAdDisplayKey, currentTime);
      await prefs.setInt(_adDisplayCountKey, adDisplayCount + 1);
    }

    if (timeDifference >= 24 * 60 * 60 * 1000) {
      print(
          '*********************************************************if timeDifference >= 24 * 60 * 60 * 1000');
      adDisplayCount = 0;
      await prefs.setInt(_lastAdDisplayKey, currentTime);
      await prefs.setInt(_adDisplayCountKey, adDisplayCount);
      disposeInterstitialAd();
    }
  }

  Future<void> showInterstitialAdWithLimit() async {
    int adCounter = SharedPrefs.getInt('interstitialAdCounter') ?? 0;

    if (adCounter >= 3) {
      // Show ad every 3rd time
      // Show the interstitial ad here
      AdHelper().showInterstitialAd();

      adCounter = 0; // Reset the counter after showing the ad
    } else {
      adCounter++; // Increment the counter
    }
    await SharedPrefs.setInt('interstitialAdCounter', adCounter);
  }

  static Future<void> showInterstitialAd2TimesIn24Hours() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // Retrieve saved values
    int lastAdTimestamp = prefs.getInt(_lastAdDisplayKey) ?? 0;
    int adDisplayCount = prefs.getInt(_adDisplayCountKey) ?? 0;

    // Calculate time difference
    int currentTime = DateTime.now().millisecondsSinceEpoch;
    int timeDifference = currentTime - lastAdTimestamp;

    // Display ad if conditions are met
    if (adDisplayCount < 2) {
      // Show the interstitial ad here
      AdHelper().showInterstitialAd();
      // Update values
      await prefs.setInt(_lastAdDisplayKey, currentTime);
      await prefs.setInt(_adDisplayCountKey, adDisplayCount + 1);
    }

    if (timeDifference >= 24 * 60 * 60 * 1000) {
      adDisplayCount = 0;
      await prefs.setInt(_lastAdDisplayKey, currentTime);
      await prefs.setInt(_adDisplayCountKey, adDisplayCount);
    }
  }

  // Dispose Interstitial Ad
  void disposeInterstitialAd() {
    _interstitialAd?.dispose();
    _interstitialAd = null;
  }
}

class AppOpenAdManager {
  AppOpenAd? _appOpenAd;
  bool _isShowingAd = false;
  static bool isLoaded = false;

  /// Load an AppOpenAd.
  void loadAd() {
    AppOpenAd.load(
      adUnitId: AdHelper.openAppAdUnitId,
      orientation: AppOpenAd.orientationPortrait,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          print("Ad Loadede.................................");
          _appOpenAd = ad;
          isLoaded = true;
        },
        onAdFailedToLoad: (error) {
          // Handle the error.
        },
      ),
    );
  }

  // Whether an ad is available to be shown.
  bool get isAdAvailable {
    return _appOpenAd != null;
  }

  void showAdIfAvailable() {
    print(
        "Called=====================================================================");
    if (_appOpenAd == null) {
      print('Tried to show ad before available.');
      loadAd();
      return;
    }
    if (_isShowingAd) {
      print('Tried to show ad while already showing an ad.');
      return;
    }
    // Set the fullScreenContentCallback and show the ad.
    _appOpenAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        _isShowingAd = true;
        print('$ad onAdShowedFullScreenContent');
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        print('$ad onAdFailedToShowFullScreenContent: $error');
        _isShowingAd = false;
        ad.dispose();
        _appOpenAd = null;
      },
      onAdDismissedFullScreenContent: (ad) {
        print('$ad onAdDismissedFullScreenContent');
        _isShowingAd = false;
        ad.dispose();
        _appOpenAd = null;
        loadAd();
      },
    );
    _appOpenAd!.show();
  }
}

class CustomBannerAd extends StatefulWidget {
  const CustomBannerAd({Key? key}) : super(key: key);

  @override
  State<CustomBannerAd> createState() => _CustomBannerAdState();
}

class _CustomBannerAdState extends State<CustomBannerAd> {
  late BannerAd bannerAd;
  bool isBannerAdLoaded = false;

  double _adHeight = 0;

  @override
  void didChangeDependencies() {
    // TODO: implement didChangeDependencies
    super.didChangeDependencies();
    bannerAd = BannerAd(
      size: AdSize.getInlineAdaptiveBannerAdSize(
          MediaQuery.of(context).size.width.toInt(), 60),
      //  size: AdSize.getCurrentOrientationInlineAdaptiveBannerAdSize(MediaQuery.of(context).size.width.toInt(),),

      adUnitId: AdHelper.bannerAdUnitId,
      listener: BannerAdListener(onAdFailedToLoad: (ad, error) {
        print("Ad Failed to Load");
        ad.dispose();
      }, onAdLoaded: (ad) {
        print("Ad Loaded");
        setState(() {
          isBannerAdLoaded = true;
        });
      }),
      request: const AdRequest(),
    );
    bannerAd.load();
  }

  @override
  Widget build(BuildContext context) {
    return isBannerAdLoaded
        ? SizedBox(
            width: double.infinity,
            height: 60,
            child: AdWidget(
              ad: bannerAd,
            ),
          )
        : SizedBox();
  }
}
