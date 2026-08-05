import 'dart:async';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// RECONCILED to match the agreed monetization model: a single
/// non-consumable "Remove Ads" purchase — not a recurring Pro
/// subscription. The original source (written out honestly last turn)
/// was built around monthly/yearly subscription IDs; this replaces
/// that with one product, `buyNonConsumable` (correct call for a
/// one-time unlock, unchanged from before), and a plainer `adsRemoved`
/// ValueNotifier<bool> instead of a generic "isPro" flag.
class IAPService extends ValueNotifier<bool> {
  static const String _removeAdsId = 'com.zdmgold.growlog.remove_ads';
  static const String _prefsKey = 'growlog_ads_removed';

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  bool _available = false;
  ProductDetails? _removeAdsProduct;

  IAPService() : super(false) {
    _init();
  }

  /// Price string for the Remove Ads product (e.g. "$2.99"), or null
  /// if the store hasn't returned product details yet. Settings screen
  /// uses this to show a real price rather than a hardcoded guess.
  String? get removeAdsPrice => _removeAdsProduct?.price;

  Future<void> _init() async {
    try {
      _available = await _iap.isAvailable();
      if (!_available) {
        debugPrint('IAP not available on this device');
        await _loadCachedStatus();
        return;
      }

      final ProductDetailsResponse response =
          await _iap.queryProductDetails({_removeAdsId});

      if (response.notFoundIDs.isNotEmpty) {
        debugPrint('IAP products not found: ${response.notFoundIDs}');
      }
      if (response.productDetails.isNotEmpty) {
        _removeAdsProduct = response.productDetails.first;
      }

      _subscription = _iap.purchaseStream.listen(
        _onPurchaseUpdate,
        onDone: () => _subscription?.cancel(),
        onError: (error) => debugPrint('IAP stream error: $error'),
      );

      await _iap.restorePurchases();
      await _loadCachedStatus();
    } catch (e) {
      debugPrint('IAPService._init error: $e');
      await _loadCachedStatus();
    }
  }

  Future<void> _loadCachedStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      value = prefs.getBool(_prefsKey) ?? false;
    } catch (e) {
      value = false;
    }
  }

  Future<void> _saveStatus(bool adsRemoved) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefsKey, adsRemoved);
      value = adsRemoved;
    } catch (e) {
      debugPrint('IAPService._saveStatus error: $e');
    }
  }

  void _onPurchaseUpdate(List<PurchaseDetails> purchases) {
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          _handleSuccessfulPurchase(purchase);
          break;
        case PurchaseStatus.error:
          debugPrint('IAP purchase error: ${purchase.error?.message}');
          break;
        case PurchaseStatus.canceled:
          debugPrint('IAP purchase canceled');
          break;
        case PurchaseStatus.pending:
          debugPrint('IAP purchase pending');
          break;
        default:
          break;
      }
    }
  }

  Future<void> _handleSuccessfulPurchase(PurchaseDetails purchase) async {
    if (purchase.productID == _removeAdsId) {
      await _saveStatus(true);
      if (purchase.pendingCompletePurchase) {
        await _iap.completePurchase(purchase);
      }
    }
  }

  /// The one purchase this app offers. Non-consumable — bought once,
  /// owned forever, restorable on a new device via restorePurchases().
  Future<void> purchaseRemoveAds() async {
    if (!_available) {
      debugPrint('IAP not available');
      return;
    }
    final product = _removeAdsProduct;
    if (product == null) {
      debugPrint('Remove Ads product not loaded yet');
      return;
    }
    final purchaseParam = PurchaseParam(productDetails: product);
    await _iap.buyNonConsumable(purchaseParam: purchaseParam);
  }

  Future<void> restorePurchases() async {
    if (!_available) return;
    await _iap.restorePurchases();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
