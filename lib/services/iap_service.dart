import 'dart:async';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'entitlement_service.dart';
import 'iap_product_ids.dart';

/// Manages the store connection, purchase stream, and buy/restore flow.
///
/// Usage:
///   await IAPService.init();
///   final products = await IAPService.loadProducts();
///   IAPService.buyProduct(product);
///   IAPService.restorePurchases();
///   IAPService.dispose(); // call in app teardown
class IAPService {
  static final InAppPurchase _iap = InAppPurchase.instance;
  static StreamSubscription<List<PurchaseDetails>>? _subscription;

  // Notifies listeners when a purchase completes or fails.
  static final StreamController<PurchaseResult> _resultController =
      StreamController<PurchaseResult>.broadcast();
  static Stream<PurchaseResult> get purchaseResults => _resultController.stream;

  /// Initialises the store connection and begins listening for purchase updates.
  /// Call once from main() after StorageService and EntitlementService are ready.
  static Future<void> init() async {
    final available = await _iap.isAvailable();
    if (!available) return;

    _subscription = _iap.purchaseStream.listen(
      _onPurchaseUpdate,
      onError: (Object error) {
        _resultController.add(PurchaseResult.error('Store error: $error'));
      },
    );
  }

  /// Loads product details from the store for all registered product IDs.
  /// Returns an empty list if the store is unavailable or products aren't found.
  static Future<List<ProductDetails>> loadProducts() async {
    final available = await _iap.isAvailable();
    if (!available) return [];

    final response = await _iap.queryProductDetails(IAPProductIds.all);
    return response.productDetails;
  }

  /// Initiates a non-consumable purchase for [product].
  static void buyProduct(ProductDetails product) {
    final param = PurchaseParam(productDetails: product);
    _iap.buyNonConsumable(purchaseParam: param);
  }

  /// Restores all previous purchases. Triggers purchase stream updates
  /// for each previously purchased product.
  static Future<void> restorePurchases() async {
    await _iap.restorePurchases();
  }

  /// Cancels the purchase stream subscription. Call when the app is disposed.
  static void dispose() {
    _subscription?.cancel();
    _resultController.close();
  }

  // ─── Private ────────────────────────────────────────────────────────────────

  static Future<void> _onPurchaseUpdate(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          await _deliverProduct(purchase);
          break;

        case PurchaseStatus.error:
          _resultController.add(
            PurchaseResult.error(
              purchase.error?.message ?? 'Purchase failed',
            ),
          );
          break;

        case PurchaseStatus.pending:
          _resultController.add(PurchaseResult.pending());
          break;

        case PurchaseStatus.canceled:
          _resultController.add(PurchaseResult.cancelled());
          break;
      }

      // Always complete the purchase to clear it from the queue.
      if (purchase.pendingCompletePurchase) {
        await _iap.completePurchase(purchase);
      }
    }
  }

  /// Unlocks the fidget tied to [purchase] and notifies listeners.
  static Future<void> _deliverProduct(PurchaseDetails purchase) async {
    final fidgetId = _fidgetIdFromProductId(purchase.productID);
    if (fidgetId != null) {
      await EntitlementService.unlock(fidgetId);
      _resultController.add(
        PurchaseResult.success(
          productId: purchase.productID,
          fidgetId: fidgetId,
          wasRestored: purchase.status == PurchaseStatus.restored,
        ),
      );
    }
  }

  /// Resolves a product ID back to its fidget ID using the reverse map.
  static String? _fidgetIdFromProductId(String productId) {
    return IAPProductIds.fidgetToProduct.entries
        .firstWhere(
          (e) => e.value == productId,
          orElse: () => const MapEntry('', ''),
        )
        .key
        .isNotEmpty
        ? IAPProductIds.fidgetToProduct.entries
            .firstWhere((e) => e.value == productId)
            .key
        : null;
  }
}

/// Represents the outcome of a purchase attempt.
class PurchaseResult {
  final PurchaseResultStatus status;
  final String? productId;
  final String? fidgetId;
  final String? errorMessage;
  final bool wasRestored;

  const PurchaseResult._({
    required this.status,
    this.productId,
    this.fidgetId,
    this.errorMessage,
    this.wasRestored = false,
  });

  factory PurchaseResult.success({
    required String productId,
    required String fidgetId,
    bool wasRestored = false,
  }) =>
      PurchaseResult._(
        status: PurchaseResultStatus.success,
        productId: productId,
        fidgetId: fidgetId,
        wasRestored: wasRestored,
      );

  factory PurchaseResult.error(String message) => PurchaseResult._(
        status: PurchaseResultStatus.error,
        errorMessage: message,
      );

  factory PurchaseResult.pending() =>
      const PurchaseResult._(status: PurchaseResultStatus.pending);

  factory PurchaseResult.cancelled() =>
      const PurchaseResult._(status: PurchaseResultStatus.cancelled);
}

enum PurchaseResultStatus { success, error, pending, cancelled }
