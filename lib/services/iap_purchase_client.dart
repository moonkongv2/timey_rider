import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart';

enum IapPurchaseStatus { pending, purchased, restored, error, canceled }

class IapProductDetails {
  const IapProductDetails({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.rawPrice,
    required this.currencyCode,
    required this.currencySymbol,
    this.sourceProductDetails,
  });

  final String id;
  final String title;
  final String description;
  final String price;
  final double rawPrice;
  final String currencyCode;
  final String currencySymbol;
  final Object? sourceProductDetails;
}

class IapPurchaseError {
  const IapPurchaseError({
    required this.source,
    required this.code,
    required this.message,
    this.details,
  });

  final String source;
  final String code;
  final String message;
  final Object? details;
}

class IapProductQueryResult {
  const IapProductQueryResult({
    required this.products,
    this.notFoundIds = const [],
    this.error,
  });

  final List<IapProductDetails> products;
  final List<String> notFoundIds;
  final IapPurchaseError? error;
}

class IapPurchaseUpdate {
  const IapPurchaseUpdate({
    required this.productId,
    required this.status,
    this.purchaseId,
    this.transactionDate,
    this.pendingCompletePurchase = false,
    this.error,
    this.sourcePurchaseDetails,
  });

  final String productId;
  final IapPurchaseStatus status;
  final String? purchaseId;
  final String? transactionDate;
  final bool pendingCompletePurchase;
  final IapPurchaseError? error;
  final Object? sourcePurchaseDetails;
}

abstract interface class IapPurchaseClient {
  Stream<List<IapPurchaseUpdate>> get purchaseStream;

  Future<bool> isAvailable();

  Future<IapProductQueryResult> queryProducts(Set<String> productIds);

  Future<bool> buyNonConsumable(IapProductDetails product);

  Future<void> restorePurchases();

  Future<void> completePurchase(IapPurchaseUpdate purchase);
}

class InAppPurchaseClient implements IapPurchaseClient {
  InAppPurchaseClient({InAppPurchase? inAppPurchase})
    : _inAppPurchase = inAppPurchase ?? InAppPurchase.instance;

  final InAppPurchase _inAppPurchase;

  @override
  Stream<List<IapPurchaseUpdate>> get purchaseStream {
    return _inAppPurchase.purchaseStream.map(
      (purchases) => purchases.map(_purchaseUpdateFromStore).toList(),
    );
  }

  @override
  Future<bool> isAvailable() {
    return _inAppPurchase.isAvailable();
  }

  @override
  Future<IapProductQueryResult> queryProducts(Set<String> productIds) async {
    final response = await _inAppPurchase.queryProductDetails(productIds);
    return IapProductQueryResult(
      products: response.productDetails.map(_productDetailsFromStore).toList(),
      notFoundIds: List.unmodifiable(response.notFoundIDs),
      error: _errorFromStore(response.error),
    );
  }

  @override
  Future<bool> buyNonConsumable(IapProductDetails product) {
    final sourceProduct = product.sourceProductDetails;
    if (sourceProduct is! ProductDetails) {
      throw ArgumentError.value(
        product,
        'product',
        'Product was not loaded by InAppPurchaseClient.',
      );
    }

    return _inAppPurchase.buyNonConsumable(
      purchaseParam: PurchaseParam(productDetails: sourceProduct),
    );
  }

  @override
  Future<void> restorePurchases() {
    return _inAppPurchase.restorePurchases();
  }

  @override
  Future<void> completePurchase(IapPurchaseUpdate purchase) {
    final sourcePurchase = purchase.sourcePurchaseDetails;
    if (sourcePurchase is! PurchaseDetails) {
      throw ArgumentError.value(
        purchase,
        'purchase',
        'Purchase was not emitted by InAppPurchaseClient.',
      );
    }

    return _inAppPurchase.completePurchase(sourcePurchase);
  }

  IapProductDetails _productDetailsFromStore(ProductDetails product) {
    return IapProductDetails(
      id: product.id,
      title: product.title,
      description: product.description,
      price: product.price,
      rawPrice: product.rawPrice,
      currencyCode: product.currencyCode,
      currencySymbol: product.currencySymbol,
      sourceProductDetails: product,
    );
  }

  IapPurchaseUpdate _purchaseUpdateFromStore(PurchaseDetails purchase) {
    final error = _errorFromStore(purchase.error);
    return IapPurchaseUpdate(
      productId: purchase.productID,
      status: _purchaseStatusFromStore(purchase.status, error),
      purchaseId: purchase.purchaseID,
      transactionDate: purchase.transactionDate,
      pendingCompletePurchase: purchase.pendingCompletePurchase,
      error: error,
      sourcePurchaseDetails: purchase,
    );
  }

  IapPurchaseStatus _purchaseStatusFromStore(
    PurchaseStatus status,
    IapPurchaseError? error,
  ) {
    return switch (status) {
      PurchaseStatus.pending => IapPurchaseStatus.pending,
      PurchaseStatus.purchased => IapPurchaseStatus.purchased,
      PurchaseStatus.restored => IapPurchaseStatus.restored,
      PurchaseStatus.canceled => IapPurchaseStatus.canceled,
      PurchaseStatus.error =>
        _isCancellationError(error)
            ? IapPurchaseStatus.canceled
            : IapPurchaseStatus.error,
    };
  }

  IapPurchaseError? _errorFromStore(IAPError? error) {
    if (error == null) {
      return null;
    }
    return IapPurchaseError(
      source: error.source,
      code: error.code,
      message: error.message,
      details: error.details,
    );
  }

  bool _isCancellationError(IapPurchaseError? error) {
    if (error == null) {
      return false;
    }
    final normalized = '${error.code} ${error.message} ${error.details}'
        .toLowerCase();
    return normalized.contains('cancel');
  }
}
