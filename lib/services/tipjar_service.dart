import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart';

class TipJarService {
  // Product IDs must exist in App Store Connect / Google Play Console.
  // Keep them stable across app versions.
  static const String tip29ProductId = 'tip_29_nok';
  static const String tip59ProductId = 'tip_59_nok';
  static const String tip99ProductId = 'tip_99_nok';

  static const List<String> tipProductIds = <String>[
    tip29ProductId,
    tip59ProductId,
    tip99ProductId,
  ];

  final InAppPurchase _iap = InAppPurchase.instance;

  Future<bool> isAvailable() => _iap.isAvailable();

  Future<Map<String, ProductDetails>> loadTipProducts() async {
    final resp = await _iap.queryProductDetails(tipProductIds.toSet());
    if (resp.error != null) return <String, ProductDetails>{};

    final map = <String, ProductDetails>{};
    for (final p in resp.productDetails) {
      map[p.id] = p;
    }
    return map;
  }

  Future<bool> buyTip(ProductDetails product) async {
    final purchaseParam = PurchaseParam(productDetails: product);
    return _iap.buyConsumable(purchaseParam: purchaseParam);
  }

  Stream<List<PurchaseDetails>> purchaseStream() => _iap.purchaseStream;

  Future<void> completeIfNeeded(PurchaseDetails p) async {
    if (p.pendingCompletePurchase) {
      await _iap.completePurchase(p);
    }
  }
}
