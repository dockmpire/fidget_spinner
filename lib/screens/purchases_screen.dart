import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../constants.dart';
import '../models/fidget_definition.dart';
import '../models/fidget_registry.dart';
import '../services/entitlement_service.dart';
import '../services/iap_service.dart';

class PurchasesScreen extends StatefulWidget {
  const PurchasesScreen({super.key});

  @override
  State<PurchasesScreen> createState() => _PurchasesScreenState();
}

class _PurchasesScreenState extends State<PurchasesScreen> {
  List<ProductDetails> _products = [];
  bool _loading = true;
  bool _restoring = false;

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _listenForPurchases();
  }

  Future<void> _loadProducts() async {
    final products = await IAPService.loadProducts();
    if (mounted) {
      setState(() {
        _products = products;
        _loading = false;
      });
    }
  }

  void _listenForPurchases() {
    IAPService.purchaseResults.listen((result) {
      if (!mounted) return;
      switch (result.status) {
        case PurchaseResultStatus.success:
          setState(() {}); // Refresh entitlements
          _showSnackBar(
            result.wasRestored ? 'Purchases restored!' : 'Purchase successful!',
          );
          break;
        case PurchaseResultStatus.error:
          _showSnackBar(result.errorMessage ?? 'Something went wrong');
          break;
        case PurchaseResultStatus.pending:
          _showSnackBar('Purchase pending...');
          break;
        case PurchaseResultStatus.cancelled:
          break;
      }
      if (result.status != PurchaseResultStatus.pending) {
        setState(() => _restoring = false);
      }
    });
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: kSurface,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _restore() async {
    setState(() => _restoring = true);
    await IAPService.restorePurchases();
  }

  ProductDetails? _productDetailsFor(FidgetDefinition fidget) {
    if (fidget.productId == null) return null;
    try {
      return _products.firstWhere((p) => p.id == fidget.productId);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final premiumFidgets = FidgetRegistry.premium;

    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        backgroundColor: kBackground,
        foregroundColor: Colors.white,
        title: const Text('Purchases'),
        centerTitle: true,
        actions: [
          if (_restoring)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: kAccent,
                  ),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _restore,
              child: const Text(
                'Restore',
                style: TextStyle(color: kAccent, fontSize: 14),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: kAccent),
              )
            : premiumFidgets.isEmpty
                ? _EmptyState()
                : ListView.separated(
                    padding: const EdgeInsets.all(24),
                    itemCount: premiumFidgets.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final fidget = premiumFidgets[index];
                      final productDetails = _productDetailsFor(fidget);
                      final unlocked =
                          EntitlementService.isUnlocked(fidget.id);
                      return _PurchaseCard(
                        fidget: fidget,
                        productDetails: productDetails,
                        unlocked: unlocked,
                        onBuy: productDetails != null
                            ? () => IAPService.buyProduct(productDetails)
                            : null,
                      );
                    },
                  ),
      ),
    );
  }
}

class _PurchaseCard extends StatelessWidget {
  final FidgetDefinition fidget;
  final ProductDetails? productDetails;
  final bool unlocked;
  final VoidCallback? onBuy;

  const _PurchaseCard({
    required this.fidget,
    required this.productDetails,
    required this.unlocked,
    required this.onBuy,
  });

  @override
  Widget build(BuildContext context) {
    final priceLabel = unlocked
        ? 'Owned'
        : (productDetails?.price ?? '\$${fidget.price.toStringAsFixed(2)}');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: unlocked
              ? fidget.accentColor.withValues(alpha: 0.3)
              : kAccent.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(fidget.icon, color: fidget.accentColor, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fidget.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  priceLabel,
                  style: TextStyle(
                    color: unlocked ? fidget.accentColor : kTextMuted,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          if (unlocked)
            const Icon(Icons.check_circle, color: kAccent, size: 20)
          else
            _GetButton(onTap: onBuy, label: productDetails?.price ?? 'Get'),
        ],
      ),
    );
  }
}

class _GetButton extends StatelessWidget {
  final VoidCallback? onTap;
  final String label;

  const _GetButton({required this.onTap, required this.label});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: kAccent.withValues(alpha: onTap != null ? 0.1 : 0.04),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: kAccent.withValues(alpha: onTap != null ? 0.4 : 0.15),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: onTap != null ? kAccent : kTextMuted,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.shopping_bag_outlined,
            size: 48,
            color: kTextMuted.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Text(
            'More fidgets coming soon',
            style: TextStyle(
              color: kTextMuted.withValues(alpha: 0.6),
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}
