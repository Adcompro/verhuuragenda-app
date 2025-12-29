import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../core/api/api_client.dart';
import '../config/api_config.dart';

/// Service voor Apple In-App Purchases
class AppleIAPService {
  static AppleIAPService? _instance;
  static AppleIAPService get instance {
    _instance ??= AppleIAPService._();
    return _instance!;
  }

  AppleIAPService._();

  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  // Product IDs - moeten overeenkomen met App Store Connect
  static const String productMonthly = 'nl.vakantiewoningverhuur.premium.monthly';
  static const String productYearly = 'nl.vakantiewoningverhuur.premium.yearly';

  static const Set<String> _productIds = {productMonthly, productYearly};

  // Cached products
  List<ProductDetails> _products = [];
  List<ProductDetails> get products => _products;

  // Callback for purchase updates
  Function(PurchaseResult)? onPurchaseUpdate;

  // Check if store is available
  bool _isAvailable = false;
  bool get isAvailable => _isAvailable;

  /// Initialize the IAP service
  Future<void> initialize() async {
    if (!Platform.isIOS) {
      debugPrint('AppleIAPService: Not iOS, skipping initialization');
      return;
    }

    _isAvailable = await _inAppPurchase.isAvailable();

    if (!_isAvailable) {
      debugPrint('AppleIAPService: Store not available');
      return;
    }

    // Listen to purchase stream
    _subscription = _inAppPurchase.purchaseStream.listen(
      _onPurchaseUpdate,
      onDone: _onPurchaseStreamDone,
      onError: _onPurchaseStreamError,
    );

    // Load products
    await loadProducts();

    debugPrint('AppleIAPService: Initialized successfully');
  }

  /// Load available products from App Store
  Future<List<ProductDetails>> loadProducts() async {
    if (!_isAvailable) {
      debugPrint('AppleIAPService: Store not available for loading products');
      return [];
    }

    try {
      final ProductDetailsResponse response = await _inAppPurchase
          .queryProductDetails(_productIds);

      if (response.notFoundIDs.isNotEmpty) {
        debugPrint('AppleIAPService: Products not found: ${response.notFoundIDs}');
      }

      if (response.error != null) {
        debugPrint('AppleIAPService: Error loading products: ${response.error}');
        return [];
      }

      _products = response.productDetails;
      debugPrint('AppleIAPService: Loaded ${_products.length} products');

      return _products;
    } catch (e) {
      debugPrint('AppleIAPService: Exception loading products: $e');
      return [];
    }
  }

  /// Get product by ID
  ProductDetails? getProduct(String productId) {
    try {
      return _products.firstWhere((p) => p.id == productId);
    } catch (e) {
      return null;
    }
  }

  /// Purchase a subscription
  Future<bool> purchaseSubscription(String productId) async {
    if (!_isAvailable) {
      onPurchaseUpdate?.call(PurchaseResult(
        success: false,
        error: 'App Store is niet beschikbaar',
      ));
      return false;
    }

    final product = getProduct(productId);
    if (product == null) {
      onPurchaseUpdate?.call(PurchaseResult(
        success: false,
        error: 'Product niet gevonden',
      ));
      return false;
    }

    try {
      final PurchaseParam purchaseParam = PurchaseParam(
        productDetails: product,
      );

      // Subscriptions use buyNonConsumable (they auto-renew)
      final bool success = await _inAppPurchase.buyNonConsumable(
        purchaseParam: purchaseParam,
      );

      debugPrint('AppleIAPService: Purchase initiated: $success');
      return success;
    } catch (e) {
      debugPrint('AppleIAPService: Purchase exception: $e');
      onPurchaseUpdate?.call(PurchaseResult(
        success: false,
        error: 'Aankoop mislukt: $e',
      ));
      return false;
    }
  }

  /// Restore previous purchases
  Future<void> restorePurchases() async {
    if (!_isAvailable) {
      onPurchaseUpdate?.call(PurchaseResult(
        success: false,
        error: 'App Store is niet beschikbaar',
      ));
      return;
    }

    try {
      await _inAppPurchase.restorePurchases();
      debugPrint('AppleIAPService: Restore initiated');
    } catch (e) {
      debugPrint('AppleIAPService: Restore exception: $e');
      onPurchaseUpdate?.call(PurchaseResult(
        success: false,
        error: 'Herstellen mislukt: $e',
      ));
    }
  }

  /// Handle purchase updates
  void _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) async {
    for (final PurchaseDetails purchaseDetails in purchaseDetailsList) {
      debugPrint('AppleIAPService: Purchase update - ${purchaseDetails.productID}: ${purchaseDetails.status}');

      switch (purchaseDetails.status) {
        case PurchaseStatus.pending:
          onPurchaseUpdate?.call(PurchaseResult(
            success: false,
            isPending: true,
            message: 'Aankoop wordt verwerkt...',
          ));
          break;

        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          // Verify with our backend
          final result = await _verifyPurchase(purchaseDetails);
          onPurchaseUpdate?.call(result);

          // Complete the purchase
          if (purchaseDetails.pendingCompletePurchase) {
            await _inAppPurchase.completePurchase(purchaseDetails);
          }
          break;

        case PurchaseStatus.error:
          onPurchaseUpdate?.call(PurchaseResult(
            success: false,
            error: purchaseDetails.error?.message ?? 'Aankoop mislukt',
          ));

          if (purchaseDetails.pendingCompletePurchase) {
            await _inAppPurchase.completePurchase(purchaseDetails);
          }
          break;

        case PurchaseStatus.canceled:
          onPurchaseUpdate?.call(PurchaseResult(
            success: false,
            isCanceled: true,
            message: 'Aankoop geannuleerd',
          ));
          break;
      }
    }
  }

  /// Verify purchase with backend
  Future<PurchaseResult> _verifyPurchase(PurchaseDetails purchaseDetails) async {
    try {
      // Get the receipt data from the purchase verification data
      // This is the recommended approach for in_app_purchase package
      String receiptData = purchaseDetails.verificationData.serverVerificationData;

      debugPrint('AppleIAPService: Receipt data length: ${receiptData.length}');

      if (receiptData.isEmpty) {
        return PurchaseResult(
          success: false,
          error: 'Geen receipt data beschikbaar',
        );
      }

      // Send to our backend for verification
      final isRestore = purchaseDetails.status == PurchaseStatus.restored;
      final endpoint = isRestore
          ? '${ApiConfig.subscription}/apple/restore'
          : '${ApiConfig.subscription}/apple/verify';

      debugPrint('AppleIAPService: Calling endpoint: $endpoint');

      final response = await ApiClient.instance.post(
        endpoint,
        data: {
          'receipt_data': receiptData,
        },
      );

      debugPrint('AppleIAPService: Response status: ${response.statusCode}');

      final data = response.data as Map<String, dynamic>;

      if (data['success'] == true) {
        return PurchaseResult(
          success: true,
          isRestore: isRestore,
          message: isRestore
              ? 'Abonnement hersteld!'
              : 'Abonnement geactiveerd!',
          subscription: data['subscription'],
        );
      } else {
        return PurchaseResult(
          success: false,
          error: data['error'] ?? 'Verificatie mislukt',
        );
      }
    } on DioException catch (e) {
      debugPrint('AppleIAPService: DioException: ${e.type}');
      debugPrint('AppleIAPService: Response: ${e.response?.data}');
      debugPrint('AppleIAPService: Status code: ${e.response?.statusCode}');

      // Try to get error message from response
      String errorMsg = 'Verificatie mislukt';
      if (e.response?.data is Map) {
        errorMsg = e.response?.data['error'] ?? e.response?.data['message'] ?? errorMsg;
      }

      return PurchaseResult(
        success: false,
        error: '$errorMsg (${e.response?.statusCode ?? "geen verbinding"})',
      );
    } catch (e) {
      debugPrint('AppleIAPService: General exception: $e');
      return PurchaseResult(
        success: false,
        error: 'Verificatie mislukt: $e',
      );
    }
  }

  void _onPurchaseStreamDone() {
    debugPrint('AppleIAPService: Purchase stream done');
    _subscription?.cancel();
  }

  void _onPurchaseStreamError(Object error) {
    debugPrint('AppleIAPService: Purchase stream error: $error');
  }

  /// Dispose of resources
  void dispose() {
    _subscription?.cancel();
    _subscription = null;
  }
}

/// Result of a purchase operation
class PurchaseResult {
  final bool success;
  final bool isPending;
  final bool isCanceled;
  final bool isRestore;
  final String? message;
  final String? error;
  final Map<String, dynamic>? subscription;

  PurchaseResult({
    required this.success,
    this.isPending = false,
    this.isCanceled = false,
    this.isRestore = false,
    this.message,
    this.error,
    this.subscription,
  });
}
