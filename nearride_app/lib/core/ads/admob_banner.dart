import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// A bottom-anchored adaptive AdMob banner.
///
/// Production unit IDs can be supplied at build time with:
/// --dart-define=ADMOB_ANDROID_BANNER_ID=... and
/// --dart-define=ADMOB_IOS_BANNER_ID=...
class AdMobBanner extends StatefulWidget {
  const AdMobBanner({super.key});

  @override
  State<AdMobBanner> createState() => _AdMobBannerState();
}

class _AdMobBannerState extends State<AdMobBanner> {
  BannerAd? _banner;
  int? _loadedWidth;
  bool _isLoaded = false;

  bool get _isSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  String get _adUnitId {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return const String.fromEnvironment(
        'ADMOB_IOS_BANNER_ID',
        defaultValue: 'ca-app-pub-3940256099942544/2435281174',
      );
    }
    return const String.fromEnvironment(
      'ADMOB_ANDROID_BANNER_ID',
      defaultValue: 'ca-app-pub-3940256099942544/9214589741',
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isSupported) return;
    final width = MediaQuery.sizeOf(context).width.truncate();
    if (width > 0 && width != _loadedWidth) _load(width);
  }

  Future<void> _load(int width) async {
    _loadedWidth = width;
    final size = await AdSize.getLargeAnchoredAdaptiveBannerAdSize(
      width,
    );
    if (!mounted || size == null || _loadedWidth != width) return;

    _banner?.dispose();
    _isLoaded = false;
    final banner = BannerAd(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      size: size,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted || ad != _banner) return;
          setState(() => _isLoaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          if (!mounted || ad != _banner) return;
          setState(() {
            _banner = null;
            _isLoaded = false;
          });
          if (kDebugMode) debugPrint('AdMob banner failed to load: $error');
        },
      ),
    );
    setState(() => _banner = banner);
    banner.load();
  }

  @override
  void dispose() {
    _banner?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final banner = _banner;
    if (!_isSupported || banner == null || !_isLoaded) {
      return const SizedBox.shrink();
    }
    return SafeArea(
      top: false,
      child: SizedBox(
        width: banner.size.width.toDouble(),
        height: banner.size.height.toDouble(),
        child: AdWidget(ad: banner),
      ),
    );
  }
}
