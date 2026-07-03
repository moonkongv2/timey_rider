import 'dart:async';

import 'package:flutter/foundation.dart';

import '../catalogs/vehicle_unlock_catalog.dart';
import '../models/purchase_entitlement.dart';
import 'iap_purchase_client.dart';
import 'local_purchase_entitlement_store.dart';

enum VehiclePackPurchaseStatus {
  idle,
  loadingProduct,
  productUnavailable,
  purchaseInProgress,
  pending,
  restoring,
  restoreNotFound,
  purchased,
  restored,
  canceled,
  error,
}

const Object _unset = Object();

class VehiclePackPurchaseState {
  const VehiclePackPurchaseState({
    required this.entitlement,
    required this.status,
    this.product,
    this.error,
    this.notFoundIds = const [],
    this.storeAvailable = true,
  });

  const VehiclePackPurchaseState.initial()
    : entitlement = const PurchaseEntitlement.locked(),
      status = VehiclePackPurchaseStatus.idle,
      product = null,
      error = null,
      notFoundIds = const [],
      storeAvailable = true;

  final PurchaseEntitlement entitlement;
  final VehiclePackPurchaseStatus status;
  final IapProductDetails? product;
  final IapPurchaseError? error;
  final List<String> notFoundIds;
  final bool storeAvailable;

  bool get vehiclePackUnlocked => entitlement.vehiclePackUnlocked;

  VehiclePackPurchaseState copyWith({
    PurchaseEntitlement? entitlement,
    VehiclePackPurchaseStatus? status,
    Object? product = _unset,
    Object? error = _unset,
    List<String>? notFoundIds,
    bool? storeAvailable,
  }) {
    return VehiclePackPurchaseState(
      entitlement: entitlement ?? this.entitlement,
      status: status ?? this.status,
      product: product == _unset ? this.product : product as IapProductDetails?,
      error: error == _unset ? this.error : error as IapPurchaseError?,
      notFoundIds: List.unmodifiable(notFoundIds ?? this.notFoundIds),
      storeAvailable: storeAvailable ?? this.storeAvailable,
    );
  }
}

class VehiclePackPurchaseController extends ChangeNotifier {
  VehiclePackPurchaseController({
    required IapPurchaseClient purchaseClient,
    required PurchaseEntitlementStore entitlementStore,
    DateTime Function()? now,
  }) : _purchaseClient = purchaseClient,
       _entitlementStore = entitlementStore,
       _now = now ?? DateTime.now {
    _purchaseSubscription = _purchaseClient.purchaseStream.listen(
      (purchases) => unawaited(_handlePurchaseUpdates(purchases)),
      onError: (Object error) {
        _setState(
          _state.copyWith(
            status: VehiclePackPurchaseStatus.error,
            error: _controllerError('purchase_stream_error', '$error'),
          ),
        );
      },
    );
  }

  final IapPurchaseClient _purchaseClient;
  final PurchaseEntitlementStore _entitlementStore;
  final DateTime Function() _now;
  late final StreamSubscription<List<IapPurchaseUpdate>> _purchaseSubscription;
  final Set<String> _completedPurchaseKeys = {};
  final Set<String> _processingPurchaseKeys = {};

  VehiclePackPurchaseState _state = const VehiclePackPurchaseState.initial();

  VehiclePackPurchaseState get state => _state;

  Future<PurchaseEntitlement> loadCachedEntitlement() async {
    final entitlement = await _entitlementStore.load();
    _setState(_state.copyWith(entitlement: entitlement));
    return entitlement;
  }

  Future<IapProductDetails?> loadVehiclePackProduct() async {
    _setState(
      _state.copyWith(
        status: VehiclePackPurchaseStatus.loadingProduct,
        error: null,
        notFoundIds: const [],
      ),
    );

    final isAvailable = await _purchaseClient.isAvailable();
    if (!isAvailable) {
      _setState(
        _state.copyWith(
          status: VehiclePackPurchaseStatus.productUnavailable,
          product: null,
          error: _controllerError(
            'store_unavailable',
            'The store is not available.',
          ),
          storeAvailable: false,
        ),
      );
      return null;
    }

    final result = await _purchaseClient.queryProducts({
      VehicleUnlockCatalog.vehiclePackProductId,
    });
    IapProductDetails? product;
    for (final candidate in result.products) {
      if (candidate.id == VehicleUnlockCatalog.vehiclePackProductId) {
        product = candidate;
        break;
      }
    }

    if (product == null) {
      _setState(
        _state.copyWith(
          status: VehiclePackPurchaseStatus.productUnavailable,
          product: null,
          error:
              result.error ??
              _controllerError(
                'product_not_found',
                'The vehicle pack product was not found.',
              ),
          notFoundIds: result.notFoundIds,
          storeAvailable: true,
        ),
      );
      return null;
    }

    _setState(
      _state.copyWith(
        status: VehiclePackPurchaseStatus.idle,
        product: product,
        error: null,
        notFoundIds: result.notFoundIds,
        storeAvailable: true,
      ),
    );
    return product;
  }

  Future<bool> buyVehiclePack({IapProductDetails? product}) async {
    final productToBuy = product ?? _state.product;
    if (productToBuy == null) {
      _setState(
        _state.copyWith(
          status: VehiclePackPurchaseStatus.productUnavailable,
          error: _controllerError(
            'product_not_loaded',
            'The vehicle pack product has not been loaded.',
          ),
        ),
      );
      return false;
    }

    _setState(
      _state.copyWith(
        status: VehiclePackPurchaseStatus.purchaseInProgress,
        error: null,
      ),
    );

    try {
      final didStart = await _purchaseClient.buyNonConsumable(productToBuy);
      if (!didStart) {
        _setState(
          _state.copyWith(
            status: VehiclePackPurchaseStatus.error,
            error: _controllerError(
              'purchase_not_started',
              'The store did not start the purchase.',
            ),
          ),
        );
      }
      return didStart;
    } catch (error) {
      _setState(
        _state.copyWith(
          status: VehiclePackPurchaseStatus.error,
          error: _controllerError('purchase_failed', '$error'),
        ),
      );
      return false;
    }
  }

  Future<void> restoreVehiclePack() async {
    _setState(
      _state.copyWith(status: VehiclePackPurchaseStatus.restoring, error: null),
    );
    try {
      await _purchaseClient.restorePurchases();
      if (_state.status == VehiclePackPurchaseStatus.restoring &&
          !_state.vehiclePackUnlocked) {
        _setState(
          _state.copyWith(
            status: VehiclePackPurchaseStatus.restoreNotFound,
            error: null,
          ),
        );
      }
    } catch (error) {
      _setState(
        _state.copyWith(
          status: VehiclePackPurchaseStatus.error,
          error: _controllerError('restore_failed', '$error'),
        ),
      );
    }
  }

  Future<void> _handlePurchaseUpdates(List<IapPurchaseUpdate> purchases) async {
    for (final purchase in purchases) {
      if (purchase.productId != VehicleUnlockCatalog.vehiclePackProductId) {
        continue;
      }

      switch (purchase.status) {
        case IapPurchaseStatus.pending:
          _setState(
            _state.copyWith(
              status: VehiclePackPurchaseStatus.pending,
              error: null,
            ),
          );
        case IapPurchaseStatus.purchased:
          await _deliverVehiclePack(
            purchase,
            source: PurchaseEntitlementSource.storePurchase,
            successStatus: VehiclePackPurchaseStatus.purchased,
          );
        case IapPurchaseStatus.restored:
          await _deliverVehiclePack(
            purchase,
            source: PurchaseEntitlementSource.storeRestore,
            successStatus: VehiclePackPurchaseStatus.restored,
          );
        case IapPurchaseStatus.error:
          _setState(
            _state.copyWith(
              status: VehiclePackPurchaseStatus.error,
              error:
                  purchase.error ??
                  _controllerError('purchase_error', 'The purchase failed.'),
            ),
          );
          await _completeTerminalPurchaseIfNeeded(purchase);
        case IapPurchaseStatus.canceled:
          _setState(
            _state.copyWith(
              status: VehiclePackPurchaseStatus.canceled,
              error: purchase.error,
            ),
          );
          await _completeTerminalPurchaseIfNeeded(purchase);
      }
    }
  }

  Future<void> _deliverVehiclePack(
    IapPurchaseUpdate purchase, {
    required PurchaseEntitlementSource source,
    required VehiclePackPurchaseStatus successStatus,
  }) async {
    final purchaseKey = _purchaseKey(purchase);
    if (_completedPurchaseKeys.contains(purchaseKey) ||
        _processingPurchaseKeys.contains(purchaseKey)) {
      return;
    }

    _processingPurchaseKeys.add(purchaseKey);
    final entitlement = PurchaseEntitlement(
      vehiclePackUnlocked: true,
      updatedAt: _now(),
      source: source,
    );

    try {
      await _entitlementStore.save(entitlement);
      if (purchase.pendingCompletePurchase) {
        await _purchaseClient.completePurchase(purchase);
      }
      _completedPurchaseKeys.add(purchaseKey);
      _setState(
        _state.copyWith(
          entitlement: entitlement,
          status: successStatus,
          error: null,
        ),
      );
    } catch (error) {
      _setState(
        _state.copyWith(
          entitlement: entitlement,
          status: VehiclePackPurchaseStatus.error,
          error: _controllerError('purchase_completion_failed', '$error'),
        ),
      );
    } finally {
      _processingPurchaseKeys.remove(purchaseKey);
    }
  }

  Future<void> _completeTerminalPurchaseIfNeeded(
    IapPurchaseUpdate purchase,
  ) async {
    if (!purchase.pendingCompletePurchase) {
      return;
    }
    try {
      await _purchaseClient.completePurchase(purchase);
    } catch (error) {
      _setState(
        _state.copyWith(
          status: VehiclePackPurchaseStatus.error,
          error: _controllerError('purchase_completion_failed', '$error'),
        ),
      );
    }
  }

  String _purchaseKey(IapPurchaseUpdate purchase) {
    return [
      purchase.productId,
      purchase.purchaseId ?? '',
      purchase.transactionDate ?? '',
      purchase.status.name,
    ].join('|');
  }

  IapPurchaseError _controllerError(String code, String message) {
    return IapPurchaseError(
      source: 'timey_rider',
      code: code,
      message: message,
    );
  }

  void _setState(VehiclePackPurchaseState state) {
    _state = state;
    notifyListeners();
  }

  @override
  void dispose() {
    unawaited(_purchaseSubscription.cancel());
    super.dispose();
  }
}
