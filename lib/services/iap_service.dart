import 'dart:async';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

class IAPService extends ValueNotifier<bool> {
  static const String _monthlyId = 'com.zdmgold.growlog.pro.monthly';
  static const String _yearlyId = 'com.zdmgold.growlog.pro.yearly';
  static const String _prefsKey = 'growlog_pro_status';

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  bool _available = false;
  List<ProductDetails> _products = [];

  IAPService() : super(false) {
    _init();
  }

  List<ProductDetails> get products => List.unmodifiable(_products);

  Future<void> _init() async {
    try {
      _available = await _iap.isAvailable();
      if (!_available) {
        debugPrint('IAP not available on this device');
        await _loadCachedStatus();
        return;
      }

      final ProductDetailsResponse response = await _iap.queryProductDetails({
        _monthlyId,
        _yearlyId,
      });

      if (response.notFoundIDs.isNotEmpty) {
        debugPrint('IAP products not found: ${response.notFoundIDs}');
      }

      _products = response.productDetails;
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
      final cached = prefs.getBool(_prefsKey) ?? false;
      value = cached;
    } catch (e) {
      value = false;
    }
  }

  Future<void> _saveStatus(bool isPro) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefsKey, isPro);
      value = isPro;
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
    if (purchase.productID == _monthlyId || purchase.productID == _yearlyId) {
      await _saveStatus(true);
      if (purchase.pendingCompletePurchase) {
        await _iap.completePurchase(purchase);
      }
    }
  }

  Future<void> purchaseMonthly() async {
    await _purchaseProduct(_monthlyId);
  }

  Future<void> purchaseYearly() async {
    await _purchaseProduct(_yearlyId);
  }

  Future<void> _purchaseProduct(String id) async {
    if (!_available) {
      debugPrint('IAP not available');
      return;
    }
    final product = _products.firstWhere(
      (p) => p.id == id,
      orElse: () => throw Exception('Product $id not found'),
    );
    final PurchaseParam purchaseParam = PurchaseParam(productDetails: product);
    await _iap.buyNonConsumable(purchaseParam: purchaseParam);
  }

  Future<void> restorePurchases() async {
    if (!_available) return;
    await _iap.restorePurchases();
  }

  Future<void> checkExpiry() async {
    // For non-consumable subscriptions (one-time unlock), no expiry check needed.
    // If switching to auto-renewing subscriptions, implement server-side receipt validation.
    // Stubbed for now — cached status is treated as permanent for one-time purchases.
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
