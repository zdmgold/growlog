import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/admob_service.dart';

/// Space kept clear above and below every banner, so a stray tap on the app's
/// own buttons never lands on an ad (within the 16-32dp range).
const double kAdSafeGap = 16;

/// The bottom banner slot. Collapses to nothing while the ad loads, if it
/// fails, off Android, or after the "Remove Ads" purchase.
class AdBottomArea extends StatelessWidget {
  /// Adds the phone's bottom inset. Use on screens with no dock under it.
  final bool safeBottom;
  const AdBottomArea({super.key, this.safeBottom = false});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AdMobService.adsRemoved,
      builder: (context, removed, _) {
        if (removed || !AdMobService.isSupported) {
          return const SizedBox.shrink();
        }
        final slot = const _BannerSlot();
        return safeBottom ? SafeArea(top: false, child: slot) : slot;
      },
    );
  }
}

class _BannerSlot extends StatefulWidget {
  const _BannerSlot();

  @override
  State<_BannerSlot> createState() => _BannerSlotState();
}

class _BannerSlotState extends State<_BannerSlot> {
  BannerAd? _ad;
  bool _loaded = false;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      _load();
    }
  }

  Future<void> _load() async {
    await AdMobService.ready;
    if (!mounted) return;
    final width = MediaQuery.of(context).size.width.truncate();
    final size =
        await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(width);
    final unit = AdMobService.bannerAdUnitId;
    if (!mounted || size == null || unit == null) return;

    final ad = BannerAd(
      adUnitId: unit,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (a) {
          if (!mounted) {
            a.dispose();
            return;
          }
          setState(() => _loaded = true);
        },
        onAdFailedToLoad: (a, error) {
          debugPrint('Banner failed to load: ${error.code} ${error.message}');
          a.dispose();
          if (mounted) {
            setState(() {
              _ad = null;
              _loaded = false;
            });
          }
        },
      ),
    );
    _ad = ad;
    await ad.load();
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _ad;
    if (!_loaded || ad == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: kAdSafeGap),
      child: Center(
        child: SizedBox(
          width: ad.size.width.toDouble(),
          height: ad.size.height.toDouble(),
          child: AdWidget(ad: ad),
        ),
      ),
    );
  }
}
